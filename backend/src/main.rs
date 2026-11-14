use std::process::ExitCode;

use backend::{AppState, config::Config, openapi, seed};
use sqlx::postgres::PgPoolOptions;
use tokio::net::TcpListener;
use tracing_subscriber::{EnvFilter, fmt, prelude::*};

#[tokio::main]
async fn main() -> ExitCode {
    // `cargo run -- openapi` prints the generated spec, for the CI check
    // against ../api/openapi.yaml.
    if std::env::args().nth(1).as_deref() == Some("openapi") {
        println!("{}", openapi::spec_json());
        return ExitCode::SUCCESS;
    }

    // A local .env is optional; production sets real environment variables.
    let _ = dotenvy::dotenv();

    let config = match Config::from_env() {
        Ok(config) => config,
        Err(e) => {
            eprintln!("config: {e}");
            return ExitCode::FAILURE;
        }
    };
    init_tracing(config.log_json);

    let args: Vec<String> = std::env::args().skip(1).collect();
    let result = match args.iter().map(String::as_str).collect::<Vec<_>>()[..] {
        [] => serve(config).await,
        ["seed"] => run_seed(config).await,
        ["make-platform-admin", email] => run_make_platform_admin(config, email).await,
        _ => Err(USAGE.into()),
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            tracing::error!(error = %e, "stopped");
            ExitCode::FAILURE
        }
    }
}

const USAGE: &str = "usage: backend [openapi | seed | make-platform-admin <email>]";

type Fallible = Result<(), Box<dyn std::error::Error>>;

// The database pool, with migrations applied. Every command starts here.
async fn connect(config: &Config) -> Result<sqlx::PgPool, Box<dyn std::error::Error>> {
    let db = PgPoolOptions::new()
        .max_connections(config.db_max_connections)
        .acquire_timeout(std::time::Duration::from_secs(3))
        .connect(&config.database_url)
        .await?;
    sqlx::migrate!().run(&db).await?;
    Ok(db)
}

/*
    `cargo run -- seed`: illustrative data for local testing. Prints the
    accounts and their shared password
*/
async fn run_seed(config: Config) -> Fallible {
    let db = connect(&config).await?;
    seed::run(&db, config.environment).await?;
    println!(
        "Seeded. Password for every account: {}",
        seed::SEED_PASSWORD
    );
    for person in seed::PEOPLE {
        let note = if person.has_password {
            ""
        } else {
            "  (invited: no password yet)"
        };
        println!("  {:<24} {}{note}", person.email, person.name);
    }
    Ok(())
}

// `cargo run -- make-platform-admin <email>`
async fn run_make_platform_admin(config: Config, email: &str) -> Fallible {
    let db = connect(&config).await?;
    if !seed::make_platform_admin(&db, email).await? {
        return Err(format!("no account has the email {email}").into());
    }
    println!("{email} is now a platform admin.");
    Ok(())
}

async fn serve(config: Config) -> Fallible {
    let db = connect(&config).await?;

    let app = backend::app(AppState {
        db,
        cookie_secure: config.cookie_secure,
        lifetimes: config.session_lifetimes,
        // The SMTP mailer replaces this before production (phase 3b).
        mailer: std::sync::Arc::new(backend::mail::LogMailer),
        code_secret: config.code_secret,
        review_email: config.review_email,
    });
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(addr = %config.bind_addr, "listening");
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    Ok(())
}

fn init_tracing(json: bool) {
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| {
        EnvFilter::new("info,backend=debug,tower_http=debug,sqlx::postgres::notice=warn")
    });
    let registry = tracing_subscriber::registry().with(filter);
    if json {
        registry.with(fmt::layer().json()).init();
    } else {
        registry.with(fmt::layer()).init();
    }
}

/// Resolves on Ctrl-C or SIGTERM (systemd stop), so in-flight requests finish.
async fn shutdown_signal() {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };
    #[cfg(unix)]
    let terminate = async {
        if let Ok(mut s) = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
        {
            s.recv().await;
        }
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! {
        () = ctrl_c => {},
        () = terminate => {},
    }
    tracing::info!("shutting down");
}
