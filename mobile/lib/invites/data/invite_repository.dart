import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/auth/auth.dart';

/// A company asking the person to join it.
class Invite extends Equatable {
  const new({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.role,
    required this.invitedBy,
    required this.invitedAt,
  });

  final String id;
  final String orgId;
  final String orgName;
  final OrgRole role;
  final String invitedBy;
  final DateTime invitedAt;

  @override
  List<Object> get props => [id, orgId, orgName, role, invitedBy, invitedAt];
}

/// Invites to join companies. Accepting updates the signed-in account.
class InviteRepository {
  new(this._api, this._auth);

  final api.OnboardingApi _api;
  final AuthRepository _auth;

  Future<List<Invite>> pending() async {
    final response = await apiCall(_api.listMyInvites);
    return [
      for (final i in response.data?.items ?? const <api.Invite>[])
        Invite(
          id: i.id,
          orgId: i.org.id,
          orgName: i.org.name,
          role: switch (i.role) {
            api.Role.orgAdmin => OrgRole.orgAdmin,
            api.Role.worker => OrgRole.worker,
            api.Role.agent => OrgRole.agent,
            api.Role.customer => OrgRole.customer,
          },
          invitedBy: i.invitedBy,
          invitedAt: i.invitedAt,
        ),
    ];
  }

  /// Joins the company; the account (and its workspaces) update at once.
  Future<void> accept(String inviteId) async {
    final response = await apiCall(() => _api.acceptInvite(inviteId: inviteId));
    final me = response.data;
    if (me != null) await _auth.applyAccount(me);
  }

  Future<void> decline(String inviteId) =>
      apiCall(() => _api.declineInvite(inviteId: inviteId));
}
