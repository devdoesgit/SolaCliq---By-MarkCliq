import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/customers/data/site_point.dart';

enum ConnectionType { residential, commercial, industrial }

enum Roof { rcc, tinShed, other }

/// The KYC papers an agent photographs, in the order asked for.
enum KycKind {
  aadhaar,
  pan,
  electricityBill,
  bankProof,
  roofPhoto,
  landDocument,

  /// A photo of the customer's signature.
  signature,

  /// Why the electricity bill is in another person's name.
  nameChange,
}

/// Which side of an Aadhaar a file shows: a label, never required.
enum DocumentSide { front, back }

/// An uploaded file of one document.
class DocumentUpload extends Equatable {
  const new(this.uploadId, {this.side});

  final String uploadId;
  final DocumentSide? side;

  /// As the API takes it.
  api.DocumentFile toApi() => api.DocumentFile(
    uploadId: uploadId,
    side: side == null ? null : api.DocumentSide.values.byName(side!.name),
  );

  @override
  List<Object?> get props => [uploadId, side];
}

/// A new customer as the agent entered them, for the admin to approve.
class CustomerDraft {
  const new({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.state,
    required this.discom,
    required this.consumerNumber,
    required this.sanctionedLoadKw,
    required this.connectionType,
    required this.proposedKw,
    required this.roof,
    required this.subsidy,
    required this.documents,
    required this.consent,
    this.site,
    this.commissionPaise,
    this.commissionNote,
  });

  final String name;

  /// Ten digits.
  final String phone;
  final String email;
  final String address;
  final String city;
  final String pinCode;
  final String state;
  final String discom;
  final String consumerNumber;
  final num sanctionedLoadKw;
  final ConnectionType connectionType;
  final num proposedKw;
  final Roof roof;
  final bool subsidy;

  /// Where the site is, if the agent took it.
  final SitePoint? site;

  /// Each document's files, up to five.
  final Map<KycKind, List<DocumentUpload>> documents;
  final bool consent;

  /// Commission agents only: what they ask for this customer.
  final int? commissionPaise;
  final String? commissionNote;
}

/// Sends new customers for the company admin to approve.
class RegistrationRepository {
  new(this._api);

  final api.CustomersApi _api;

  /// The request's reference, "SC-1042". Pass the same [idempotencyKey]
  /// when retrying, so a retry never registers them twice.
  Future<String> submit({
    required String orgId,
    required String idempotencyKey,
    required CustomerDraft draft,
  }) async {
    final d = draft;
    final response = await apiCall(
      () => _api.submitCustomerRegistration(
        orgId: orgId,
        idempotencyKey: idempotencyKey,
        customerRegistrationCreate: api.CustomerRegistrationCreate(
          name: d.name,
          phone: d.phone,
          email: d.email,
          address: d.address,
          city: d.city,
          pinCode: d.pinCode,
          state: d.state,
          discom: d.discom,
          consumerNumber: d.consumerNumber,
          sanctionedLoadKw: d.sanctionedLoadKw,
          connectionType: api.ConnectionType.values.byName(
            d.connectionType.name,
          ),
          proposedKw: d.proposedKw,
          roof: api.RoofType.values.byName(d.roof.name),
          lat: d.site?.lat,
          lng: d.site?.lng,
          subsidy: d.subsidy,
          documents: [
            for (final MapEntry(:key, :value) in d.documents.entries)
              api.CustomerRegistrationCreateDocumentsInner(
                kind: api.KycKind.values.byName(key.name),
                files: [for (final file in value) file.toApi()],
              ),
          ],
          consent: d.consent,
          commission: d.commissionPaise,
          commissionNote: d.commissionNote,
        ),
      ),
    );
    return response.data!.reference;
  }
}
