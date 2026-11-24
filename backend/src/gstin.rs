/*
    GSTIN: India's 15-character GST number
    --------------------------------------------------------------------
    - layout: 27 AAPFU0939F 1 Z V
        - 2 digits:  state code (27 = Maharashtra)
        - 10 chars:  the business's PAN
        - 1 char:    entity number for that PAN in the state (1-9, A-Z)
        - "Z":       fixed
        - 1 char:    check character, computed from the first 14
    - the check character catches a mistyped GSTIN; it doesn't prove the
      GSTIN is registered or active (that needs the GST lookup API, later)
*/

const CHARSET: &[u8; 36] = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

// A GSTIN that passed every check, with what it tells us.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Gstin {
    // Uppercase, no spaces.
    pub number: String,
    pub pan: String,
    pub state: &'static str,
}

/*
    Checks a GSTIN as typed. Spaces and lowercase are allowed (people
    copy it from certificates); None when it isn't a valid GSTIN
*/
pub fn parse(raw: &str) -> Option<Gstin> {
    let number: String = raw
        .chars()
        .filter(|c| !c.is_whitespace())
        .collect::<String>()
        .to_uppercase();
    let b = number.as_bytes();
    if b.len() != 15 {
        return None;
    }
    let shape = b[0..2].iter().all(u8::is_ascii_digit)
        && b[2..7].iter().all(u8::is_ascii_uppercase)
        && b[7..11].iter().all(u8::is_ascii_digit)
        && b[11].is_ascii_uppercase()
        && (b[12].is_ascii_uppercase() || (b'1'..=b'9').contains(&b[12]))
        && b[13] == b'Z'
        && b[14].is_ascii_alphanumeric();
    if !shape || check_char(&b[..14])? != b[14] {
        return None;
    }
    let state = state_name(&number[..2])?;
    Some(Gstin {
        pan: number[2..12].to_owned(),
        state,
        number,
    })
}

/*
    The check character of the first 14 characters
    --------------------------------------------------------------------
    - each character's value is its place in CHARSET (0-9, then A=10...)
    - values at odd places (2nd, 4th...) are doubled
    - each product is split into "how many 36s" + "remainder", and both
      parts are added up
    - the check character is the one that brings the sum to a multiple
      of 36
*/
fn check_char(first14: &[u8]) -> Option<u8> {
    let mut sum = 0usize;
    for (i, c) in first14.iter().enumerate() {
        let value = CHARSET.iter().position(|x| x == c)?;
        let product = value * if i % 2 == 0 { 1 } else { 2 };
        sum += product / 36 + product % 36;
    }
    Some(CHARSET[(36 - sum % 36) % 36])
}

/*
    The state or union territory of a GSTIN's first two digits. 99
    (centre jurisdiction) isn't a business location, so it's refused
*/
fn state_name(code: &str) -> Option<&'static str> {
    Some(match code {
        "01" => "Jammu and Kashmir",
        "02" => "Himachal Pradesh",
        "03" => "Punjab",
        "04" => "Chandigarh",
        "05" => "Uttarakhand",
        "06" => "Haryana",
        "07" => "Delhi",
        "08" => "Rajasthan",
        "09" => "Uttar Pradesh",
        "10" => "Bihar",
        "11" => "Sikkim",
        "12" => "Arunachal Pradesh",
        "13" => "Nagaland",
        "14" => "Manipur",
        "15" => "Mizoram",
        "16" => "Tripura",
        "17" => "Meghalaya",
        "18" => "Assam",
        "19" => "West Bengal",
        "20" => "Jharkhand",
        "21" => "Odisha",
        "22" => "Chhattisgarh",
        "23" => "Madhya Pradesh",
        "24" => "Gujarat",
        // 25 is the old Daman and Diu code, merged into 26 in 2020.
        "25" | "26" => "Dadra and Nagar Haveli and Daman and Diu",
        "27" => "Maharashtra",
        // 28 is Andhra Pradesh's code from before Telangana split off.
        "28" | "37" => "Andhra Pradesh",
        "29" => "Karnataka",
        "30" => "Goa",
        "31" => "Lakshadweep",
        "32" => "Kerala",
        "33" => "Tamil Nadu",
        "34" => "Puducherry",
        "35" => "Andaman and Nicobar Islands",
        "36" => "Telangana",
        "38" => "Ladakh",
        "97" => "Other Territory",
        _ => return None,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    // A GSTIN published as an example by GST portals.
    const SAMPLE: &str = "27AAPFU0939F1ZV";

    #[test]
    fn a_valid_gstin_gives_its_pan_and_state() {
        let g = parse(SAMPLE).unwrap();
        assert_eq!(g.number, SAMPLE);
        assert_eq!(g.pan, "AAPFU0939F");
        assert_eq!(g.state, "Maharashtra");
    }

    #[test]
    fn spaces_and_lowercase_are_fine() {
        assert_eq!(parse(" 27aapfu0939f 1zv ").unwrap().number, SAMPLE);
    }

    #[test]
    fn a_typo_fails_the_check_character() {
        assert!(parse("27AAPFU0939F1ZW").is_none()); // last char changed
        assert!(parse("27AAPFU0938F1ZV").is_none()); // a PAN digit changed
    }

    #[test]
    fn wrong_shapes_fail() {
        assert!(parse("").is_none());
        assert!(parse("27AAPFU0939F1Z").is_none()); // 14 characters
        assert!(parse("27AAPFU0939F1YV").is_none()); // 14th isn't Z
        assert!(parse("27AAPF00939F1ZV").is_none()); // digit inside the PAN letters
    }

    #[test]
    fn an_unknown_state_fails() {
        // 99 with a correct check character: still refused.
        let first14 = b"99AAPFU0939F1Z";
        let check = check_char(first14).unwrap() as char;
        let gstin = format!("{}{check}", std::str::from_utf8(first14).unwrap());
        assert!(parse(&gstin).is_none());
    }
}
