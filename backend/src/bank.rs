/*
    Payout bank accounts
    --------------------------------------------------------------------
    - the account number is stored encrypted (AES-256-GCM, key BANK_KEY,
      never in the database) and never returned; the API shows the last
      4 digits
    - each encryption uses a fresh random 12-byte nonce, stored in front
      of the ciphertext; GCM also detects any change to the stored bytes
    - the bank's name comes from the IFSC's first four letters
*/

use std::{fmt, sync::Arc};

use aes_gcm::{
    Aes256Gcm, Nonce,
    aead::{Aead, KeyInit},
};

use crate::error::ApiError;

const NONCE_LEN: usize = 12;

/*
    The 32-byte key (BANK_KEY, 64 hex characters). `Debug` prints no
    bytes, so logging the config can't leak it
*/
#[derive(Clone)]
pub struct BankKey(Arc<Aes256Gcm>);

impl BankKey {
    // From 64 hex characters (`openssl rand -hex 32`); None otherwise.
    pub fn from_hex(hex: &str) -> Option<Self> {
        let hex = hex.trim();
        if hex.len() != 64 {
            return None;
        }
        let mut key = [0u8; 32];
        for (i, byte) in key.iter_mut().enumerate() {
            *byte = u8::from_str_radix(hex.get(i * 2..i * 2 + 2)?, 16).ok()?;
        }
        Some(BankKey(Arc::new(Aes256Gcm::new(&key.into()))))
    }

    // nonce || ciphertext
    pub fn encrypt(&self, account_number: &str) -> Result<Vec<u8>, ApiError> {
        let mut nonce = [0u8; NONCE_LEN];
        getrandom::fill(&mut nonce).map_err(|e| {
            tracing::error!(error = %e, "no randomness");
            ApiError::internal()
        })?;
        let sealed = self
            .0
            .encrypt(&Nonce::from(nonce), account_number.as_bytes())
            .map_err(|_| ApiError::internal())?;
        Ok([nonce.as_slice(), &sealed].concat())
    }

    // The account number back; for paying out (admin side, later).
    pub fn decrypt(&self, stored: &[u8]) -> Result<String, ApiError> {
        if stored.len() <= NONCE_LEN {
            return Err(ApiError::internal());
        }
        let (nonce, sealed) = stored.split_at(NONCE_LEN);
        let nonce: [u8; NONCE_LEN] = nonce.try_into().map_err(|_| ApiError::internal())?;
        let plain = self
            .0
            .decrypt(&Nonce::from(nonce), sealed)
            .map_err(|_| ApiError::internal())?;
        String::from_utf8(plain).map_err(|_| ApiError::internal())
    }
}

impl fmt::Debug for BankKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str("BankKey(..)")
    }
}

// `^[A-Z]{4}0[A-Z0-9]{6}$`: 4-letter bank code, a 0, the branch.
pub fn is_ifsc(ifsc: &str) -> bool {
    let b = ifsc.as_bytes();
    b.len() == 11
        && b[..4].iter().all(u8::is_ascii_uppercase)
        && b[4] == b'0'
        && b[5..]
            .iter()
            .all(|c| c.is_ascii_uppercase() || c.is_ascii_digit())
}

/*
    The bank of an IFSC, by its first four letters. Common banks only;
    any other shows its code (still a valid IFSC)
*/
pub fn bank_name(ifsc: &str) -> String {
    let code = ifsc.get(..4).unwrap_or(ifsc);
    match code {
        "SBIN" => "State Bank of India",
        "HDFC" => "HDFC Bank",
        "ICIC" => "ICICI Bank",
        "UTIB" => "Axis Bank",
        "PUNB" => "Punjab National Bank",
        "BARB" => "Bank of Baroda",
        "CNRB" => "Canara Bank",
        "UBIN" => "Union Bank of India",
        "BKID" => "Bank of India",
        "IDIB" => "Indian Bank",
        "CBIN" => "Central Bank of India",
        "IOBA" => "Indian Overseas Bank",
        "UCBA" => "UCO Bank",
        "MAHB" => "Bank of Maharashtra",
        "PSIB" => "Punjab & Sind Bank",
        "KKBK" => "Kotak Mahindra Bank",
        "INDB" => "IndusInd Bank",
        "YESB" => "Yes Bank",
        "IDFB" => "IDFC First Bank",
        "FDRL" => "Federal Bank",
        "AUBL" => "AU Small Finance Bank",
        "JAKA" => "J&K Bank",
        "AIRP" => "Airtel Payments Bank",
        "IPOS" => "India Post Payments Bank",
        other => other,
    }
    .to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;

    const KEY: &str = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";

    #[test]
    fn encrypts_and_decrypts() {
        let key = BankKey::from_hex(KEY).unwrap();
        let a = key.encrypt("123456789012").unwrap();
        let b = key.encrypt("123456789012").unwrap();
        assert_ne!(a, b, "a fresh nonce each time");
        assert!(!a.windows(12).any(|w| w == b"123456789012"));
        assert_eq!(key.decrypt(&a).unwrap(), "123456789012");
    }

    #[test]
    fn a_changed_byte_is_refused() {
        let key = BankKey::from_hex(KEY).unwrap();
        let mut a = key.encrypt("123456789012").unwrap();
        *a.last_mut().unwrap() ^= 1;
        assert!(key.decrypt(&a).is_err());
    }

    #[test]
    fn keys_and_ifscs() {
        assert!(BankKey::from_hex("abc").is_none());
        assert!(is_ifsc("HDFC0001234"));
        assert!(!is_ifsc("HDFC1001234"));
        assert!(!is_ifsc("hdfc0001234"));
        assert_eq!(bank_name("HDFC0001234"), "HDFC Bank");
        assert_eq!(bank_name("ZZZZ0001234"), "ZZZZ");
    }
}
