/*
  A sign-up between the code and the details
  ----------------------------------------------------------------------
  - the one-time token the code gave, and the email it proved
  - in memory only: never stored, never in a route (a route can be
    restored and logged). Closing the app means starting again, with a
    new code
*/
class PendingSignup {
  String? _email;
  String? _token;

  /// The proven email; null when there's no sign-up in progress.
  String? get email => _email;

  /// Its setup token.
  String? get token => _token;

  /// Remembers what the code proved.
  void hold({required String email, required String token}) {
    _email = email;
    _token = token;
  }

  /// Forgets everything.
  void clear() {
    _email = null;
    _token = null;
  }
}
