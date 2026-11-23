import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';

/// Where a lead stands (F20).
enum LeadStatus { fresh, contacted, won, lost }

/// A landing-page lead the company's admin handed to this Sales Agent.
class Lead extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.phone,
    required this.source,
    required this.status,
    required this.receivedAt,
    this.city,
    this.email,
    this.monthlyBill,
    this.roofType,
    this.message,
    this.note,
    this.answers = const {},
  });

  final String id;
  final String name;

  /// Ten digits.
  final String phone;
  final String source;
  final LeadStatus status;
  final DateTime receivedAt;
  final String? city;
  final String? email;
  final String? monthlyBill;
  final String? roofType;
  final String? message;
  final String? note;

  /// The form's other answers, by question.
  final Map<String, String> answers;

  /// Still to be worked: new or contacted.
  bool get open => status == LeadStatus.fresh || status == LeadStatus.contacted;

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    source,
    status,
    receivedAt,
    city,
    email,
    monthlyBill,
    roofType,
    message,
    note,
    answers,
  ];
}

/// The agent's leads: their list, one lead, and working it.
class LeadRepository {
  const new(this._api);

  final api.LeadsApi _api;

  /// Every lead handed to the caller, newest first.
  Future<List<Lead>> mine(String orgId) => allPages((cursor) async {
    final response = await apiCall(
      () => _api.listMyLeads(orgId: orgId, cursor: cursor, limit: pageSizeMax),
    );
    final page = response.data!;
    return ([for (final l in page.items) _summary(l)], page.page.nextCursor);
  });

  Future<Lead> get(String orgId, String leadId) async {
    final response = await apiCall(
      () => _api.getLead(orgId: orgId, leadId: leadId),
    );
    return _lead(response.data!);
  }

  /// Changes the status, or the note (an empty one removes it).
  Future<Lead> update(
    String orgId,
    String leadId, {
    LeadStatus? status,
    String? note,
  }) async {
    final response = await apiCall(
      () => _api.updateLead(
        orgId: orgId,
        leadId: leadId,
        leadUpdate: api.LeadUpdate(
          status: status == null ? null : _toApi(status),
          note: note,
        ),
      ),
    );
    return _lead(response.data!);
  }

  static Lead _summary(api.LeadSummary l) => Lead(
    id: l.id,
    name: l.name,
    phone: l.phone,
    source: l.source_,
    status: _fromApi(l.status),
    receivedAt: l.receivedAt,
    city: l.city,
  );

  static Lead _lead(api.Lead l) => Lead(
    id: l.id,
    name: l.name,
    phone: l.phone,
    source: l.source_,
    status: _fromApi(l.status),
    receivedAt: l.receivedAt,
    city: l.city,
    email: l.email,
    monthlyBill: l.monthlyBill,
    roofType: l.roofType,
    message: l.message,
    note: l.note,
    answers: l.extra,
  );

  static LeadStatus _fromApi(api.LeadStatus s) => switch (s) {
    api.LeadStatus.new_ => LeadStatus.fresh,
    api.LeadStatus.contacted => LeadStatus.contacted,
    api.LeadStatus.won => LeadStatus.won,
    api.LeadStatus.lost => LeadStatus.lost,
  };

  static api.LeadStatus _toApi(LeadStatus s) => switch (s) {
    LeadStatus.fresh => api.LeadStatus.new_,
    LeadStatus.contacted => api.LeadStatus.contacted,
    LeadStatus.won => api.LeadStatus.won,
    LeadStatus.lost => api.LeadStatus.lost,
  };
}
