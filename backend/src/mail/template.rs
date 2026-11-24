/*
    Building blocks for the emails' HTML
    --------------------------------------------------------------------
    - every email is the same page (`page`): a wordmark, a badge, a
      heading, a white card, a note on why it was sent, a footer. What
      goes in the card is each email's own, made from the pieces below,
      so an approval looks like good news and a lead like a call to make
    - `preheader`: the line the inbox shows next to the subject. Without
      one, the inbox shows the first text in the email (the wordmark).
      Code emails keep the sun-dot wordmark there; the rest set their own
    - inline styles and tables only: email apps drop <style> blocks and
      most modern CSS. No images (nothing is hosted yet); badges are a
      character in a coloured circle
    - colours are the app's tokens (design/tokens.json)
    - `esc` every value from outside; the pieces escape what they're given
*/

use crate::PRODUCT_NAME;

pub const INK: &str = "#2a1f19";
pub const MUTED: &str = "#6d635a";
const SUN: &str = "#f6c445";
const SUN_TINT: &str = "#fdf1cc";
const CREAM: &str = "#fbf8f4";
const CREAM_DEEP: &str = "#f3ece4";
const TRACK: &str = "#e4dad0";
const FONT: &str = "-apple-system,BlinkMacSystemFont,'Segoe UI',Inter,Helvetica,Arial,sans-serif";

// A colour pair: the strong one for text and marks, the tint behind it.
#[derive(Clone, Copy)]
pub enum Tone {
    Sun,
    Success,
    Warning,
    Danger,
    Ink,
}

impl Tone {
    fn strong(self) -> &'static str {
        match self {
            Tone::Sun => "#875d09",
            Tone::Success => "#2e7445",
            Tone::Warning => "#875d09",
            Tone::Danger => "#b3402f",
            Tone::Ink => INK,
        }
    }

    fn tint(self) -> &'static str {
        match self {
            Tone::Sun => SUN_TINT,
            Tone::Success => "#e1f1e4",
            Tone::Warning => "#fdefc8",
            Tone::Danger => "#fbe4df",
            Tone::Ink => CREAM_DEEP,
        }
    }
}

/*
    The big circle above the heading. `glyph` is HTML (an entity such as
    "&#10003;"), written by the caller, never user input
*/
pub struct Badge {
    pub glyph: &'static str,
    pub tone: Tone,
}

pub struct EmailPage<'a> {
    pub preheader: Option<&'a str>,
    // The sun dot before the wordmark: code emails only.
    pub sun_dot: bool,
    pub badge: Option<Badge>,
    pub heading: &'a str,
    // The card's HTML, built from the pieces below.
    pub card: String,
    // Why it was sent, in grey under the card.
    pub note: Option<&'a str>,
}

pub fn page(p: EmailPage) -> String {
    let heading = esc(p.heading);
    let product = esc(PRODUCT_NAME);
    /*
        The preview line, then invisible padding so the inbox doesn't run
        on into the email's first words
    */
    let preheader = p
        .preheader
        .map(|t| {
            format!(
                r#"<div style="display:none;max-height:0;overflow:hidden;opacity:0;mso-hide:all;">{}{}</div>"#,
                esc(t),
                "&#847;&zwnj;&nbsp;".repeat(60)
            )
        })
        .unwrap_or_default();
    let dot = if p.sun_dot {
        format!(r#"<span style="color:{SUN};font-size:18px;">&#9679;</span>&nbsp;"#)
    } else {
        String::new()
    };
    let badge = p
        .badge
        .map(|b| {
            format!(
                r#"<tr><td align="center" style="padding:8px 0 4px;"><table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr><td align="center" valign="middle" width="56" height="56" style="width:56px;height:56px;border-radius:28px;background:{bg};color:{fg};font-size:28px;line-height:56px;font-weight:700;">{glyph}</td></tr></table></td></tr>"#,
                bg = b.tone.tint(),
                fg = b.tone.strong(),
                glyph = b.glyph
            )
        })
        .unwrap_or_default();
    let note = p
        .note
        .map(|n| {
            format!(
                r#"<tr><td style="padding:16px 4px;font-size:13px;line-height:20px;color:{MUTED};border-bottom:1px solid {TRACK};">{}</td></tr>"#,
                esc(n)
            )
        })
        .unwrap_or_default();
    let card = p.card;
    format!(
        r#"<!DOCTYPE html>
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta name="viewport" content="width=device-width">
<title>{heading}</title>
</head>
<body style="margin:0;padding:0;background:{CREAM};font-family:{FONT};color:{INK};">
{preheader}
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background:{CREAM};">
<tr><td align="center" style="padding:32px 16px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:520px;">
<tr><td align="center" style="padding-bottom:8px;font-size:15px;font-weight:600;letter-spacing:0.5px;color:{INK};">{dot}{product}</td></tr>
{badge}
<tr><td align="center" style="padding:8px 0 20px;font-size:24px;line-height:30px;font-weight:400;color:{INK};">{heading}</td></tr>
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

// A paragraph of plain text.
pub fn para(text: &str) -> String {
    para_html(&esc(text))
}

// A paragraph of HTML the caller built (with `esc` and `bold`).
pub fn para_html(html: &str) -> String {
    format!(r#"<p style="margin:0 0 12px;font-size:15px;line-height:22px;">{html}</p>"#)
}

pub fn bold(text: &str) -> String {
    format!("<strong>{}</strong>", esc(text))
}

// A small grey label over a section: "WHAT'S NEXT".
pub fn eyebrow(text: &str) -> String {
    format!(
        r#"<p style="margin:16px 0 8px;font-size:12px;line-height:16px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:{MUTED};">{}</p>"#,
        esc(text)
    )
}

// The code, large and spaced.
pub fn code(code: &str) -> String {
    format!(
        r#"<p style="margin:8px 0 20px;text-align:center;font-size:30px;line-height:38px;font-weight:600;letter-spacing:8px;">{}</p>"#,
        esc(code)
    )
}

// A tinted box: a bold title and a line of text.
pub fn callout(tone: Tone, title: &str, text: &str) -> String {
    format!(
        r#"<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:4px 0 16px;"><tr><td style="background:{bg};border-left:4px solid {fg};border-radius:8px;padding:12px 16px;"><p style="margin:0 0 4px;font-size:14px;line-height:20px;font-weight:600;color:{fg};">{title}</p><p style="margin:0;font-size:14px;line-height:20px;color:{INK};">{text}</p></td></tr></table>"#,
        bg = tone.tint(),
        fg = tone.strong(),
        title = esc(title),
        text = esc(text)
    )
}

// Where a step is in a progress list.
#[derive(Clone, Copy, PartialEq, Eq)]
pub enum Step {
    Done,
    Now,
    Later,
}

/*
    Steps down the card, each a circle and a title with a line under it:
    done ones green with a tick, the current one sun, the rest outlined
    and numbered. For "what happens next" and "how to set up"
*/
pub fn steps(items: &[(Step, &str, &str)]) -> String {
    let rows: String = items
        .iter()
        .enumerate()
        .map(|(i, (state, title, line))| {
            let (bg, fg, border, mark) = match state {
                Step::Done => (
                    Tone::Success.tint(),
                    Tone::Success.strong(),
                    Tone::Success.tint(),
                    "&#10003;".to_owned(),
                ),
                Step::Now => (SUN, INK, SUN, (i + 1).to_string()),
                Step::Later => ("#ffffff", MUTED, TRACK, (i + 1).to_string()),
            };
            let title_colour = if *state == Step::Later { MUTED } else { INK };
            format!(
                r#"<tr><td width="40" valign="top" style="padding:0 12px 14px 0;"><table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr><td align="center" valign="middle" width="28" height="28" style="width:28px;height:28px;border-radius:14px;background:{bg};border:1px solid {border};color:{fg};font-size:14px;line-height:28px;font-weight:700;">{mark}</td></tr></table></td><td valign="top" style="padding:3px 0 14px;"><p style="margin:0;font-size:15px;line-height:22px;font-weight:600;color:{title_colour};">{title}</p><p style="margin:2px 0 0;font-size:14px;line-height:20px;color:{MUTED};">{line}</p></td></tr>"#,
                title = esc(title),
                line = esc(line)
            )
        })
        .collect();
    format!(
        r#"<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:4px 0 4px;">{rows}</table>"#
    )
}

// A link inside a paragraph, in the ink colour, underlined.
pub fn link(href: &str, label: &str) -> String {
    format!(
        r#"<a href="{}" style="color:{INK};text-decoration:underline;">{}</a>"#,
        esc(href),
        esc(label)
    )
}

/*
    A value for a URL's query string: letters, digits and -._~ as they
    are, everything else as %XX (an email's "+" must not turn into a
    space)
*/
pub fn query_value(value: &str) -> String {
    value
        .bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                (b as char).to_string()
            }
            _ => format!("%{b:02X}"),
        })
        .collect()
}

// Label and value rows between two rules.
pub fn details(rows: &[(&str, String)]) -> String {
    let rows: String = rows
        .iter()
        .map(|(label, value)| {
            format!(
                r#"<tr><td style="padding:6px 12px 6px 0;font-size:14px;line-height:20px;color:{MUTED};vertical-align:top;white-space:nowrap;">{}</td><td style="padding:6px 0;font-size:14px;line-height:20px;vertical-align:top;">{}</td></tr>"#,
                esc(label),
                esc(value)
            )
        })
        .collect();
    format!(
        r#"<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:4px 0 16px;border-top:1px solid {TRACK};border-bottom:1px solid {TRACK};">{rows}</table>"#
    )
}

/*
    A company as a card: its initials in a circle, the name, a line
    under it, and a pill on the right ("Live", "Worker")
*/
pub fn company(name: &str, line: &str, pill: &str, tone: Tone) -> String {
    let initials: String = name
        .split_whitespace()
        .filter_map(|w| w.chars().find(|c| c.is_alphanumeric()))
        .take(2)
        .flat_map(char::to_uppercase)
        .collect();
    format!(
        r#"<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:0 0 16px;background:{CREAM};border-radius:10px;"><tr><td width="44" valign="middle" style="padding:12px 0 12px 12px;"><table role="presentation" cellspacing="0" cellpadding="0" border="0"><tr><td align="center" valign="middle" width="40" height="40" style="width:40px;height:40px;border-radius:20px;background:{INK};color:#ffffff;font-size:15px;line-height:40px;font-weight:600;">{initials}</td></tr></table></td><td valign="middle" style="padding:12px;"><p style="margin:0;font-size:15px;line-height:20px;font-weight:600;">{name}</p><p style="margin:2px 0 0;font-size:13px;line-height:18px;color:{MUTED};">{line}</p></td><td align="right" valign="middle" style="padding:12px 12px 12px 0;white-space:nowrap;"><span style="display:inline-block;padding:4px 10px;border-radius:12px;background:{bg};color:{fg};font-size:12px;line-height:16px;font-weight:600;">{pill}</span></td></tr></table>"#,
        initials = esc(&initials),
        name = esc(name),
        line = esc(line),
        pill = esc(pill),
        bg = tone.tint(),
        fg = tone.strong()
    )
}

// A big pill button: a link (https:, tel:, mailto:).
pub fn button(href: &str, label: &str) -> String {
    format!(
        r#"<table role="presentation" cellspacing="0" cellpadding="0" border="0" align="center" style="margin:4px auto 16px;"><tr><td align="center" style="border-radius:24px;background:{SUN};"><a href="{href}" style="display:inline-block;padding:12px 28px;font-size:16px;line-height:22px;font-weight:600;color:{INK};text-decoration:none;border-radius:24px;">{label}</a></td></tr></table>"#,
        href = esc(href),
        label = esc(label)
    )
}

/*
    One figure, large, in a sun-tinted box with a label over it and a
    line under it: the lead's estimate
*/
pub fn figure(label: &str, value: &str, line: &str) -> String {
    format!(
        r#"<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="margin:0 0 16px;"><tr><td align="center" style="background:{SUN_TINT};border-radius:10px;padding:16px;"><p style="margin:0;font-size:12px;line-height:16px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:{MUTED};">{label}</p><p style="margin:4px 0;font-size:24px;line-height:30px;font-weight:600;color:{INK};">{value}</p><p style="margin:0;font-size:14px;line-height:20px;color:{MUTED};">{line}</p></td></tr></table>"#,
        label = esc(label),
        value = esc(value),
        line = esc(line)
    )
}

pub fn sign_off() -> String {
    format!(
        r#"<p style="margin:16px 0 0;font-size:15px;line-height:22px;">Thanks,<br>The {} team</p>"#,
        esc(PRODUCT_NAME)
    )
}

pub fn sign_off_text() -> String {
    format!("Thanks,\nThe {PRODUCT_NAME} team")
}

// The five characters that matter in HTML text and attributes.
pub fn esc(s: &str) -> String {
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

    fn simple(preheader: Option<&str>, sun_dot: bool) -> String {
        page(EmailPage {
            preheader,
            sun_dot,
            badge: Some(Badge {
                glyph: "&#10003;",
                tone: Tone::Success,
            }),
            heading: "You're <approved>",
            card: para("Hello & welcome"),
            note: Some("Because <you> registered."),
        })
    }

    #[test]
    fn the_preheader_comes_before_anything_visible() {
        let html = simple(Some("Bright Sun Solar is live"), false);
        let pre = html.find("Bright Sun Solar is live").unwrap();
        let wordmark = html.find(PRODUCT_NAME).unwrap();
        assert!(pre < wordmark);
        assert!(!html.contains("&#9679;"), "no sun dot");
    }

    #[test]
    fn code_emails_keep_the_sun_dot_and_no_preheader() {
        let html = simple(None, true);
        assert!(html.contains("&#9679;"));
        assert!(!html.contains("display:none"));
    }

    #[test]
    fn values_are_escaped() {
        let html = simple(None, false);
        assert!(html.contains("You&#39;re &lt;approved&gt;"));
        assert!(html.contains("Hello &amp; welcome"));
        assert!(html.contains("Because &lt;you&gt; registered."));
        assert!(company("A<b> Co", "x", "Live", Tone::Success).contains("A&lt;b&gt; Co"));
        assert_eq!(esc(r#"a&b"c'"#), "a&amp;b&quot;c&#39;");
    }

    #[test]
    fn query_values_keep_a_plus_sign() {
        assert_eq!(
            query_value("parth+owner@markcliq.co"),
            "parth%2Bowner%40markcliq.co"
        );
        assert_eq!(query_value("a b&c"), "a%20b%26c");
    }

    #[test]
    fn company_initials_come_from_the_first_two_words() {
        assert!(company("bright sun solar", "", "Live", Tone::Success).contains(">BS<"));
        assert!(company("(Sun) Co", "", "Live", Tone::Success).contains(">SC<"));
    }
}
