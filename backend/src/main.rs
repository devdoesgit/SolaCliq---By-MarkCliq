use std::process::ExitCode;

use std::{sync::Arc, time::Duration};

use backend::{
    AppState, PRODUCT_NAME,
    config::Config,
    google::ServiceAccount,
    mail::{
        Email, LogMailer, Mailer,
        gmail::GmailMailer,
        template::{self as t, Badge, EmailPage, Tone},
    },
    openapi, seed,
};
use sqlx::postgres::PgPoolOptions;
use tokio::{net::TcpListener, task::JoinHandle};
use tracing_subscriber::{EnvFilter, fmt, prelude::*};

#[tokio::main]
async fn main() -> ExitCode {
    // `cargo run -- openapi` prints the generated spec, for the CI check
    // against ../api/openapi.yaml.
    if std::env::args().nth(1).as_deref() == Some("openapi") {
        println!("{}", openapi::spec_json());
        return ExitCode::SUCCESS;
    }

    /*
        TLS for outgoing HTTPS (the Gmail API) uses ring, which sqlx
        already brings in. Set once, before any HTTP client is built
    */
    let _ = rustls::crypto::ring::default_provider().install_default();

    /*
        A local .env is optional (production sets real environment
        variables), but one that can't be read stops here: otherwise the
        lines after a mistake would be skipped without a word
    */
    if let Err(e) = dotenvy::dotenv()
        && !e.not_found()
    {
        eprintln!(".env: {e}");
        return ExitCode::FAILURE;
    }

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
        ["send-test-email", to] => run_send_test_email(config, to).await,
        ["send-test-push", token] => run_send_test_push(config, token).await,
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

const USAGE: &str = "usage: backend [openapi | seed | make-platform-admin <email> | send-test-email <to> | send-test-push <token>]";

type Fallible = Result<(), Box<dyn std::error::Error>>;
// A mailer, and Gmail's background task when there is one (see `mailer`).
type MailerAndTask = (Arc<dyn Mailer>, Option<JoinHandle<()>>);

// The owner's pool, with migrations applied. The commands start here.
async fn connect(config: &Config) -> Result<sqlx::PgPool, Box<dyn std::error::Error>> {
    let db = pool(config, &config.database_url).await?;
    sqlx::migrate!().run(&db).await?;
    Ok(db)
}

async fn pool(config: &Config, url: &str) -> Result<sqlx::PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(config.db_max_connections)
        .acquire_timeout(std::time::Duration::from_secs(3))
        .connect(url)
        .await
}

/*
    The server's pool: migrations first (as the owner, whose pool then
    closes), then the restricted login (APP_DATABASE_URL), checked
*/
async fn connect_app(config: &Config) -> Result<sqlx::PgPool, Box<dyn std::error::Error>> {
    connect(config).await?.close().await;
    let db = pool(config, &config.app_database_url).await?;
    let login = backend::scope::check_restricted(&db).await?;
    tracing::info!(%login, "database login restricted by row-level security");
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

/*
    The configured mailer
    --------------------------------------------------------------------
    - Gmail when MAIL_FROM is set; otherwise the log (Config allows that
      in development only)
    - the JoinHandle is Gmail's background task: await it after the last
      mailer is dropped, so queued emails go out before the process ends
*/
fn mailer(config: &Config) -> Result<MailerAndTask, Box<dyn std::error::Error>> {
    let Some(gmail) = &config.gmail else {
        return Ok((Arc::new(LogMailer), None));
    };
    let account = ServiceAccount::from_file(&gmail.key_file)?;
    let (mailer, task) = GmailMailer::start(account, gmail.from.clone());
    tracing::info!(from = %gmail.from, "sending email through the Gmail API");
    Ok((Arc::new(mailer), Some(task)))
}

/*
    Where push notifications go: Firebase when FCM_SERVICE_ACCOUNT_KEY_FILE
    is set; otherwise the log (Config allows that in development only)
*/
fn pusher(config: &Config) -> Result<backend::push::Sender, Box<dyn std::error::Error>> {
    let Some(path) = &config.fcm_key_file else {
        tracing::info!("push notifications go to the log (no FCM key set)");
        return Ok(backend::push::Sender::Log);
    };
    let account = ServiceAccount::from_file(path)?;
    if account.project_id().is_empty() {
        return Err("FCM_SERVICE_ACCOUNT_KEY_FILE has no project_id".into());
    }
    tracing::info!(
        project = account.project_id(),
        "sending push notifications through FCM"
    );
    Ok(backend::push::Sender::Fcm(Box::new(
        backend::push::Fcm::new(account),
    )))
}

// Lets queued emails go out, for up to 30 seconds.
async fn drain(task: Option<JoinHandle<()>>) {
    if let Some(task) = task
        && tokio::time::timeout(Duration::from_secs(30), task)
            .await
            .is_err()
    {
        tracing::warn!("stopped with emails still queued");
    }
}

/*
    `cargo run -- send-test-email <to>`: sends one email through the
    configured mailer and waits for it, to check the Gmail setup
*/
async fn run_send_test_email(config: Config, to: &str) -> Fallible {
    let (mailer, task) = mailer(&config)?;
    let line = format!("If you can read this, {PRODUCT_NAME} can send email.");
    mailer.send(Email {
        to: to.to_owned(),
        subject: format!("{PRODUCT_NAME} test email"),
        body: format!("{line}\n"),
        html: Some(t::page(EmailPage {
            preheader: Some(&line),
            sun_dot: false,
            badge: Some(Badge {
                glyph: "&#10003;",
                tone: Tone::Success,
            }),
            heading: "Email works",
            card: t::para(&line),
            note: Some("Sent by `send-test-email` to check the email setup."),
        })),
    });
    drop(mailer);
    drain(task).await;
    println!("Done; the log above says whether it was sent.");
    Ok(())
}

/*
    `cargo run -- send-test-push <token>`: one push straight to a phone's
    FCM token (the devices table has them), to check the Firebase setup.
    A made-up token checks the key alone: Firebase answers that the
    token isn't valid, which it can only say after accepting the key
*/
async fn run_send_test_push(config: Config, token: &str) -> Fallible {
    let backend::push::Sender::Fcm(mut fcm) = pusher(&config)? else {
        return Err("FCM_SERVICE_ACCOUNT_KEY_FILE is not set".into());
    };
    let outcome = fcm.send_test(token).await;
    println!("{outcome:?}");
    Ok(())
}

async fn serve(config: Config) -> Fallible {
    let db = connect_app(&config).await?;
    let (mailer, mail_task) = mailer(&config)?;
    if let Some(storage) = config.storage.clone() {
        tokio::spawn(sweep_uploads(db.clone(), storage.clone()));
        tokio::spawn(retire_kyc(db.clone(), storage, config.kyc_retention));
    }
    tokio::spawn(backend::push::run(db.clone(), pusher(&config)?));

    let app = backend::app(AppState {
        db,
        cookie_secure: config.cookie_secure,
        lifetimes: config.session_lifetimes,
        mailer,
        limits: Arc::new(backend::rate_limit::Limiter::new()),
        code_secret: config.code_secret,
        review_email: config.review_email,
        bank_key: config.bank_key,
        storage: config.storage,
    });
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(addr = %config.bind_addr, "listening");
    // With the connection's address, for rate limits when there's no proxy.
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<std::net::SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown_signal())
    .await?;
    // The router, and with it every mailer, is gone: send what's queued.
    drain(mail_task).await;
    Ok(())
}

/*
    Every hour, deletes uploads nothing attached within a day
    (`routes::uploads::sweep`). Stops with the server; the next start
    picks up where it left off
*/
async fn sweep_uploads(db: sqlx::PgPool, storage: backend::storage::Storage) {
    let mut every = tokio::time::interval(std::time::Duration::from_secs(60 * 60));
    loop {
        every.tick().await;
        match backend::routes::uploads::sweep(&db, &storage).await {
            Ok(0) => {}
            Ok(n) => tracing::info!(deleted = n, "abandoned uploads swept"),
            Err(e) => tracing::error!(error = ?e, "sweeping abandoned uploads"),
        }
    }
}

/*
    Every hour, KYC past its retention (`retention::run`): deleted with
    `KYC_RETENTION=true`, otherwise only counted in the log
*/
async fn retire_kyc(db: sqlx::PgPool, storage: backend::storage::Storage, delete: bool) {
    let mut every = tokio::time::interval(std::time::Duration::from_secs(60 * 60));
    loop {
        every.tick().await;
        match backend::retention::run(&db, &storage, delete).await {
            Ok(r) if r.due == 0 => {}
            Ok(r) if delete => tracing::info!(due = r.due, deleted = r.deleted, "KYC retention"),
            Ok(r) => tracing::warn!(due = r.due, "KYC past retention; KYC_RETENTION is off"),
            Err(e) => tracing::error!(error = ?e, "KYC retention"),
        }
    }
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
