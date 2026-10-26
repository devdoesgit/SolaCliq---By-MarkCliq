/// Holds the email and password someone just signed up with, in memory only,
/// so verifying the email can log them straight in instead of asking for the
/// password again. Taken once; never written to storage.
class PendingLogin {
  String? _email;
  String? _password;

  /// Remembers the details of a sign-up in progress.
  void hold({required String email, required String password}) {
    _email = email;
    _password = password;
  }

  /// The password for [email], once; null if there is none.
  String? take(String email) {
    final password = email == _email ? _password : null;
    clear();
    return password;
  }

  /// Forgets everything.
  void clear() {
    _email = null;
    _password = null;
  }
}
