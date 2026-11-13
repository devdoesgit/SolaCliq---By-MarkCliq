/*
    Outgoing email (sign-up codes, password reset codes)
    --------------------------------------------------------------------
    - handlers call `state.mailer.send(email)`
    - which mailer that is gets decided once, in main.rs
        - development: LogMailer, prints the email to the server log
        - production: SMTP mailer (phase 3b, last step)
    - `send` returns at once and never fails for the caller
        - the request doesn't wait for the mail server
        - so a response takes the same time whether an email went out
          or not, and timing can't reveal which emails have accounts
*/

// One plain-text email.
#[derive(Debug, Clone)]
pub struct Email {
    pub to: String,
    pub subject: String,
    pub body: String,
}

/*
    Anything that can send an email
    --------------------------------------------------------------------
    - a trait is a list of methods a type promises to have
    - handlers only see `dyn Mailer` ("some type that has `send`"), so
      swapping the log for SMTP, or for the test mailer that keeps emails
      in memory, changes no handler code
    - `Send + Sync`: requests on many threads share one mailer, so it
      must be safe to use from any thread
*/
pub trait Mailer: Send + Sync {
    /*
        Queues `email` and returns straight away. Delivery problems are
        logged by the mailer, not returned.
    */
    fn send(&self, email: Email);
}

/*
    Development only: prints each email to the server log instead of
    sending it, so the 6-digit code can be read from the terminal.
*/
pub struct LogMailer;

impl Mailer for LogMailer {
    fn send(&self, email: Email) {
        tracing::info!(
            to = %email.to,
            subject = %email.subject,
            "email not sent (development; LogMailer)\n{}",
            email.body
        );
    }
}
