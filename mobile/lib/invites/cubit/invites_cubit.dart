import 'package:bloc/bloc.dart';
import 'package:solacliq/auth/data/auth_failure.dart';
import 'package:solacliq/invites/data/invite_repository.dart';

/// Invites waiting for the person, for the banner on the personal home.
/// Empty until loaded; a failed load leaves it empty (the banner is extra).
class InvitesCubit extends Cubit<List<Invite>> {
  new(this._invites) : super(const []);

  final InviteRepository _invites;

  Future<void> load() async {
    try {
      final pending = await _invites.pending();
      if (!isClosed) emit(pending);
    } on AuthFailure {
      // Keep what is shown; the next refresh tries again.
    }
  }
}
