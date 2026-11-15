/*
    Checks shared by every request that takes an email or a phone
    (sign-up, log in, adding a member...)
*/

// Emails are stored trimmed and lowercased (see the users migration).
pub fn normalize_email(email: &str) -> String {
    email.trim().to_lowercase()
}

/*
    A light shape check (something@domain.tld). The real proof is the
    code we email: only the inbox's owner can read it
*/
pub fn looks_like_email(email: &str) -> bool {
    let Some((local, domain)) = email.split_once('@') else {
        return false;
    };
    email.len() <= 254
        && !local.is_empty()
        && domain.contains('.')
        && !domain.starts_with('.')
        && !domain.ends_with('.')
        && !email.contains(char::is_whitespace)
        && !domain.contains('@')
}

// `^[6-9][0-9]{9}$`: an Indian mobile number, without +91.
pub fn is_indian_mobile(phone: &str) -> bool {
    phone.len() == 10
        && phone.starts_with(['6', '7', '8', '9'])
        && phone.chars().all(|c| c.is_ascii_digit())
}

// `^[1-9][0-9]{5}$`: Indian PIN codes don't start with 0.
pub fn is_pin_code(pin: &str) -> bool {
    pin.len() == 6 && !pin.starts_with('0') && pin.chars().all(|c| c.is_ascii_digit())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn emails() {
        assert!(looks_like_email("asha@example.com"));
        assert!(!looks_like_email("asha@example"));
        assert!(!looks_like_email("@example.com"));
        assert!(!looks_like_email("asha @example.com"));
        assert!(!looks_like_email("a@b@example.com"));
    }

    #[test]
    fn phones() {
        assert!(is_indian_mobile("9876511223"));
        assert!(!is_indian_mobile("5876511223")); // starts with 5
        assert!(!is_indian_mobile("987651122")); // 9 digits
        assert!(!is_indian_mobile("+919876511"));
    }

    #[test]
    fn normalizes() {
        assert_eq!(normalize_email("  Asha@Example.COM "), "asha@example.com");
    }
}
