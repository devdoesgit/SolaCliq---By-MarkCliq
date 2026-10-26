import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/customers/data/registration_repository.dart';

enum KycStatus { inReview, needsFix, approved }

/// `approved` waits for the customer's advance; `payable` once it is paid.
enum CommissionStatus { inReview, approved, payable, paid }

/// What an admin wrote, and who.
class AdminNote extends Equatable {
  const new({required this.text, required this.by});

  final String text;
  final String by;

  @override
  List<Object> get props => [text, by];
}

/// A commission agent's commission on one customer.
class Commission extends Equatable {
  const new({
    required this.amountPaise,
    required this.status,
    this.proposedPaise,
    this.adminNote,
    this.payableSince,
    this.paidOn,
  });

  final int amountPaise;
  final CommissionStatus status;

  /// What the agent asked, when the admin changed it.
  final int? proposedPaise;
  final AdminNote? adminNote;
  final DateTime? payableSince;
  final DateTime? paidOn;

  @override
  List<Object?> get props => [
    amountPaise,
    status,
    proposedPaise,
    adminNote,
    payableSince,
    paidOn,
  ];
}

/// A customer the person added, as listed.
class CustomerSummary extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.systemKw,
    required this.place,
    required this.kyc,
    required this.detail,
    required this.sentAt,
    this.commission,
  });

  final String id;
  final String name;
  final num systemKw;
  final String place;
  final KycStatus kyc;

  /// One line on where it stands, from the server.
  final String detail;
  final DateTime sentAt;
  final Commission? commission;

  @override
  List<Object?> get props => [
    id,
    name,
    systemKw,
    place,
    kyc,
    detail,
    sentAt,
    commission,
  ];
}

/// The document an admin sent back.
class ReturnedDocument extends Equatable {
  const new({required this.kind, required this.title, required this.note});

  final KycKind kind;
  final String title;
  final AdminNote note;

  @override
  List<Object> get props => [kind, title, note];
}

/// One customer the person added: KYC, install, advance and commission.
class CustomerDetail extends Equatable {
  const new({
    required this.summary,
    required this.phone,
    this.stageIndex,
    this.stageCount,
    this.stageLabel,
    this.returned,
    this.documentsVerified,
    this.documentsDetail,
    this.advancePaidOn,
    this.advanceDue = false,
  });

  final CustomerSummary summary;
  final String phone;
  final int? stageIndex;
  final int? stageCount;
  final String? stageLabel;
  final ReturnedDocument? returned;
  final bool? documentsVerified;
  final String? documentsDetail;
  final DateTime? advancePaidOn;
  final bool advanceDue;

  @override
  List<Object?> get props => [
    summary,
    phone,
    stageIndex,
    stageCount,
    stageLabel,
    returned,
    documentsVerified,
    documentsDetail,
    advancePaidOn,
    advanceDue,
  ];
}

/// The customers a Sales person added, and fixes to their documents.
class CustomerRepository {
  new(this._api);

  final api.CustomersApi _api;

  /// Newest first.
  Future<List<CustomerSummary>> mine(String orgId) async {
    final response = await apiCall(() => _api.listMyCustomers(orgId: orgId));
    return [
      for (final c in response.data!.items)
        _summary(
          id: c.id,
          name: c.name,
          systemKw: c.systemKw,
          place: c.place,
          kyc: c.kycStatus,
          detail: c.detail,
          sentAt: c.sentAt,
          commission: c.commission,
        ),
    ];
  }

  Future<CustomerDetail> get(String orgId, String customerId) async {
    final response = await apiCall(
      () => _api.getMyCustomer(orgId: orgId, customerId: customerId),
    );
    return _detail(response.data!);
  }

  /// Sends a clearer copy of the document the admin sent back.
  Future<CustomerDetail> replaceDocument({
    required String orgId,
    required String customerId,
    required KycKind kind,
    required String uploadId,
  }) async {
    final response = await apiCall(
      () => _api.replaceCustomerDocument(
        orgId: orgId,
        customerId: customerId,
        kind: api.KycKind.values.byName(kind.name),
        replaceCustomerDocumentRequest: api.ReplaceCustomerDocumentRequest(
          uploadId: uploadId,
        ),
      ),
    );
    return _detail(response.data!);
  }

  static CustomerDetail _detail(api.CustomerDetail c) => CustomerDetail(
    summary: _summary(
      id: c.id,
      name: c.name,
      systemKw: c.systemKw,
      place: c.place,
      kyc: c.kycStatus,
      detail: c.detail,
      sentAt: c.sentAt,
      commission: c.commission,
    ),
    phone: c.phone,
    stageIndex: c.stage?.index,
    stageCount: c.stage?.count,
    stageLabel: c.stage?.label,
    returned: switch (c.returned) {
      final r? => ReturnedDocument(
        kind: KycKind.values.byName(r.kind.name),
        title: r.title,
        note: _note(r.note),
      ),
      null => null,
    },
    documentsVerified: c.documents == null
        ? null
        : c.documents!.status == api.DocumentStatus.verified,
    documentsDetail: c.documents?.detail,
    advancePaidOn: _date(c.advance?.paidOn),
    advanceDue: c.advance?.status == api.CustomerDetailAdvanceStatusEnum.due,
  );

  static CustomerSummary _summary({
    required String id,
    required String name,
    required num systemKw,
    required String place,
    required api.KycStatus kyc,
    required String detail,
    required DateTime sentAt,
    required api.Commission? commission,
  }) => CustomerSummary(
    id: id,
    name: name,
    systemKw: systemKw,
    place: place,
    kyc: switch (kyc) {
      api.KycStatus.inReview => KycStatus.inReview,
      api.KycStatus.needsFix => KycStatus.needsFix,
      api.KycStatus.approved => KycStatus.approved,
    },
    detail: detail,
    sentAt: sentAt,
    commission: switch (commission) {
      final c? => Commission(
        amountPaise: c.amount,
        proposedPaise: c.proposedAmount,
        status: switch (c.status) {
          api.CommissionStatus.inReview => CommissionStatus.inReview,
          api.CommissionStatus.approved => CommissionStatus.approved,
          api.CommissionStatus.payable => CommissionStatus.payable,
          api.CommissionStatus.paid => CommissionStatus.paid,
        },
        adminNote: c.adminNote == null ? null : _note(c.adminNote!),
        payableSince: _date(c.payableSince),
        paidOn: _date(c.paidOn),
      ),
      null => null,
    },
  );

  static AdminNote _note(api.TaskNote n) => AdminNote(
    text: n.text,
    by: n.by.role == null ? n.by.name : '${n.by.name} · ${n.by.role}',
  );

  static DateTime? _date(String? iso) =>
      iso == null ? null : DateTime.parse(iso);
}
