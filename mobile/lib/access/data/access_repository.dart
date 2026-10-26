import 'package:api_client/api_client.dart' as api;
import 'package:solacliq/app/data/api_call.dart';

/// A solar company asking for SolaCliq. MarkCliq follows up.
class AccessRepository {
  new(this._api);

  final api.OnboardingApi _api;

  Future<void> requestAccess({
    required String companyName,
    required String ownerName,
    required String phone,
    required String city,
    required String email,
  }) => apiCall(
    () => _api.requestAccess(
      accessRequestCreate: api.AccessRequestCreate(
        companyName: companyName,
        ownerName: ownerName,
        phone: phone,
        city: city,
        email: email,
      ),
    ),
  );
}
