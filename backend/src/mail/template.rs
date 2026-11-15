/*
    How emails look: one layout for all of them
    --------------------------------------------------------------------
    - laid out like the big services' account emails: the wordmark, a
      centred heading, a white bordered card with the message, a grey
      note on why it was sent, and a footer
    - two kinds:
        - `CodeEmail`: a 6-digit code, large and spaced, with how long it
          lasts and a don't-share line
        - `Message`: paragraphs, and optionally a table of details (a
          registration, a lead) between them
    - each gives the plain text and the HTML of one email; every email
      goes out with both (multipart/alternative)
    - inline styles and tables only: email apps drop <style> blocks and
      most modern CSS
    - colours are the app's tokens (design/tokens.json): ink, muted, sun,
      cream, track
    - no images: nothing is hosted yet, and blocked images would leave a
      gap. The wordmark is text with a sun dot
    - every value is HTML-escaped before it goes in
*/

use crate::{PRODUCT_NAME, mail::Email};

const INK: &str = "#2a1f19";
const MUTED: &str = "#6d635a";
const SUN: &str = "#f6c445";
const CREAM: &str = "#fbf8f4";
const TRACK: &str = "#e4dad0";
const FONT: &str = "-apple-system,BlinkMacSystemFont,'Segoe UI',Inter,Helvetica,Arial,sans-serif";
const P: &str = "margin:0 0 12px;font-size:15px;line-height:22px;";

// An email that carries a code.
pub struct CodeEmail<'a> {
    // "Verify your email"
    pub heading: &'a str,
    // "Here is your SolaCliq verification code:"
    pub intro: &'a str,
    pub code: &'a str,
    pub valid_minutes: i32,
    // Why it was sent, for the grey note under the card.
    pub reason: &'a str,
}

impl CodeEmail<'_> {
    // The plain-text part, for email apps that don't show HTML.
    pub fn text(&self) -> String {
        format!(
            "{intro} {code}\n\
             This code is valid for {minutes} minutes and can only be used once.\n\n\
             Please don't share this code with anyone: MarkCliq will never ask \
             for it on the phone or on WhatsApp.\n\n\
             {sign_off}\n\n\
             {reason}\n",
            intro = self.intro,
            code = self.code,
            minutes = self.valid_minutes,
            sign_off = sign_off_text(),
            reason = self.reason,
        )
    }

    pub fn html(&self) -> String {
        let card = format!(
            r#"<p style="{P}">{intro}</p>
<p style="margin:8px 0 20px;text-align:center;font-size:30px;line-height:38px;font-weight:600;letter-spacing:8px;">{code}</p>
<p style="{P}">This code is valid for <strong>{minutes} minutes</strong> and can only be used once.</p>
<p style="{P}"><strong>Please don't share this code with anyone:</strong> MarkCliq will never ask for it on the phone or on WhatsApp.</p>
{sign_off}"#,
            intro = escape(self.intro),
            code = escape(self.code),
            minutes = self.valid_minutes,
            sign_off = sign_off_html(),
        );
        layout(self.heading, &card, Some(self.reason))
    }
}

/*
    Any other email
    --------------------------------------------------------------------
    - `before`, then `details` as a two-column table, then `after`; each
      paragraph is plain text
    - `sign_off`: "Thanks, The SolaCliq team". Off for MarkCliq's own
      inbox (reviews, leads), where it would read oddly
    - `reason`: the grey note on why it was sent, if any
*/
pub struct Message {
    pub heading: String,
    pub before: Vec<String>,
    pub details: Vec<(&'static str, String)>,
    pub after: Vec<String>,
    pub sign_off: bool,
    pub reason: Option<String>,
}

impl Message {
    pub fn text(&self) -> String {
        let mut parts: Vec<String> = self.before.clone();
        if !self.details.is_empty() {
            parts.push(
                self.details
                    .iter()
                    .map(|(label, value)| format!("{label}: {value}"))
                    .collect::<Vec<_>>()
                    .join("\n"),
            );
        }
        parts.extend(self.after.iter().cloned());
        if self.sign_off {
            parts.push(sign_off_text());
        }
        if let Some(reason) = &self.reason {
            parts.push(reason.clone());
        }
        parts.join("\n\n") + "\n"
    }

    pub fn html(&self) -> String {
        let paragraphs = |list: &[String]| -> String {
            list.iter()
                .map(|p| format!(r#"<p style="{P}">{}</p>"#, escape(p)))
                .collect::<Vec<_>>()
                .join("\n")
        };
        let mut card = paragraphs(&self.before);
        if !self.details.is_empty() {
            let rows: String = self
                .details
                .iter()
                .map(|(label, value)| {
                    format!(
                        r#"<tr><td style="padding:6px 12px 6px 0;font-size:14px;line-height:20px;color:{MUTED};vertical-align:top;white-space:nowrap;">{}</td><td style="padding:6px 0;font-size:14px;line-height:20px;vertical-align:top;">{}</td></tr>"#,
                        escape(label),
                        escape(value)
                    )
                })
                .collect();
            // No space under the table when nothing follows it in the card.
            let below = if self.after.is_empty() && !self.sign_off {
                0
            } else {
                16
            };
            card.push_str(&format!(
                r#"
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:4px 0 {below}px;border-top:1px solid {TRACK};border-bottom:1px solid {TRACK};">{rows}</table>"#
            ));
        }
        let after = paragraphs(&self.after);
        if !after.is_empty() {
            card.push('\n');
            card.push_str(&after);
        }
        if self.sign_off {
            card.push('\n');
            card.push_str(&sign_off_html());
        }
        layout(&self.heading, &card, self.reason.as_deref())
    }

    // Both parts, as one email to `to`.
    pub fn email(&self, to: &str, subject: String) -> Email {
        Email {
            to: to.to_owned(),
            subject,
            body: self.text(),
            html: Some(self.html()),
        }
    }
}

fn sign_off_text() -> String {
    format!("Thanks,\nThe {PRODUCT_NAME} team")
}

fn sign_off_html() -> String {
    format!(
        r#"<p style="margin:0;font-size:15px;line-height:22px;">Thanks,<br>The {} team</p>"#,
        escape(PRODUCT_NAME)
    )
}

// The page around a card: wordmark, heading, card, note, footer.
fn layout(heading: &str, card: &str, reason: Option<&str>) -> String {
    let heading = escape(heading);
    let product = escape(PRODUCT_NAME);
    let note = reason
        .map(|r| {
            format!(
                r#"<tr><td style="padding:16px 4px;font-size:13px;line-height:20px;color:{MUTED};border-bottom:1px solid {TRACK};">{}</td></tr>"#,
                escape(r)
            )
        })
        .unwrap_or_default();
    format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width">
<title>{heading}</title>
</head>
<body style="margin:0;padding:0;background:{CREAM};font-family:{FONT};color:{INK};">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:{CREAM};">
<tr><td align="center" style="padding:32px 16px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:520px;">
<tr><td align="center" style="padding-bottom:8px;font-size:15px;font-weight:600;letter-spacing:0.5px;color:{INK};">
<span style="color:{SUN};font-size:18px;">&#9679;</span>&nbsp;{product}
</td></tr>
<tr><td align="center" style="padding:4px 0 20px;font-size:24px;line-height:30px;font-weight:400;color:{INK};">{heading}</td></tr>
<tr><td style="background:#ffffff;border:1px solid {TRACK};border-radius:12px;padding:24px;color:{INK};">
{card}
</td></tr>
{note}
<tr><td align="center" style="padding:20px 0 0;font-size:12px;line-height:18px;color:{MUTED};">{product} by MarkCliq &middot; Mohali, Punjab</td></tr>
</table>
</td></tr>
</table>
</body>
</html>
"#
    )
}

// The five characters that matter in HTML text and attributes.
fn escape(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for c in s.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&#39;"),
            c => out.push(c),
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn code() -> CodeEmail<'static> {
        CodeEmail {
            heading: "Verify your email",
            intro: "Here is your SolaCliq verification code:",
            code: "123456",
            valid_minutes: 5,
            reason: "You're receiving this because <someone> signed up.",
        }
    }

    fn message() -> Message {
        Message {
            heading: "New company to review".into(),
            before: vec!["A company registered.".into()],
            details: vec![("Company", "Sun & Sons <Solar>".into())],
            after: vec!["Approve or reject it.".into()],
            sign_off: false,
            reason: None,
        }
    }

    #[test]
    fn both_parts_carry_the_code_and_its_lifetime() {
        let e = code();
        for part in [e.text(), e.html()] {
            assert!(part.contains("123456"));
            assert!(part.contains("5 minutes"));
            assert!(part.contains("don't share this code"));
        }
    }

    #[test]
    fn a_message_keeps_its_order_in_both_parts() {
        let m = message();
        for part in [m.text(), m.html()] {
            let before = part.find("A company registered.").unwrap();
            let details = part.find("Company").unwrap();
            let after = part.find("Approve or reject it.").unwrap();
            assert!(before < details && details < after);
            assert!(!part.contains("The SolaCliq team"), "no sign-off when off");
        }
        assert!(m.text().contains("Company: Sun & Sons <Solar>\n"));
    }

    #[test]
    fn values_are_escaped() {
        assert!(code().html().contains("&lt;someone&gt;"));
        let html = message().html();
        assert!(html.contains("Sun &amp; Sons &lt;Solar&gt;"));
        assert!(!html.contains("<Solar>"));
        assert_eq!(escape(r#"a&b"c'"#), "a&amp;b&quot;c&#39;");
    }
}
