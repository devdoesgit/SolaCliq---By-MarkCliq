import 'package:api_client/api_client.dart' as api;
import 'package:solacliq/app/data/api_call.dart';

/// A company's legal form, as on its registration.
enum BusinessType {
  proprietorship,
  partnership,
  llp,
  privateLimited,
  publicLimited,
  other,
}

/// What a solar company sends to register with SolaCliq.
class CompanyRegistration {
  const new({
    required this.legalName,
    required this.businessType,
    required this.gstin,
    required this.addressLine1,
    required this.city,
    required this.pinCode,
    required this.ownerName,
    required this.email,
    required this.phone,
    this.tradeName,
    this.addressLine2,
  });

  final String legalName;

  /// Shown in the app; the server uses the legal name when this is null.
  final String? tradeName;
  final BusinessType businessType;
  final String gstin;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String pinCode;
  final String ownerName;
  final String email;

  /// Ten digits.
  final String phone;
}

/// Registers a solar company. The server saves it as pending; MarkCliq
/// reviews it and approves or rejects it.
class CompanyRegistrationRepository {
  new(this._api);

  final api.OnboardingApi _api;

  Future<void> register(CompanyRegistration r) => apiCall(
    () => _api.registerOrg(
      orgRegistrationCreate: api.OrgRegistrationCreate(
        legalName: r.legalName,
        tradeName: r.tradeName,
        businessType: api.BusinessType.values.byName(r.businessType.name),
        gstin: r.gstin,
        addressLine1: r.addressLine1,
        addressLine2: r.addressLine2,
        city: r.city,
        pinCode: r.pinCode,
        ownerName: r.ownerName,
        email: r.email,
        phone: r.phone,
      ),
    ),
  );
}
