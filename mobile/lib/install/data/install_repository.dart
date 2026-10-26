import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';

enum StageStatus { done, next, upcoming }

class InstallStage extends Equatable {
  const new({required this.name, required this.status, this.detail});

  final String name;
  final StageStatus status;
  final String? detail;

  @override
  List<Object?> get props => [name, status, detail];
}

/// `claimed`: the customer says they paid; the company confirms.
enum PaymentStatus { due, claimed, paid, later }

enum PaymentMethod { upi, bankTransfer }

class InstallPayment extends Equatable {
  const new({
    required this.id,
    required this.label,
    required this.amountPaise,
    required this.status,
    this.detail,
  });

  final String id;
  final String label;
  final int amountPaise;
  final PaymentStatus status;
  final String? detail;

  @override
  List<Object?> get props => [id, label, amountPaise, status, detail];
}

/// Who comes next, and when.
class InstallVisit extends Equatable {
  const new({
    required this.title,
    required this.startsAt,
    required this.personName,
    this.endsAt,
    this.personPhone,
  });

  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String personName;
  final String? personPhone;

  @override
  List<Object?> get props => [title, startsAt, endsAt, personName, personPhone];
}

/// A customer's own install: stages, the next visit and the payment plan.
class Install extends Equatable {
  const new({
    required this.systemKw,
    required this.place,
    required this.stageIndex,
    required this.stageCount,
    required this.totalPaise,
    required this.subsidyPaise,
    required this.stages,
    required this.payments,
    this.handedOver = false,
    this.upiUri,
    this.nextVisit,
  });

  final num systemKw;
  final String place;
  final int stageIndex;
  final int stageCount;
  final int totalPaise;
  final int subsidyPaise;
  final List<InstallStage> stages;
  final List<InstallPayment> payments;
  final bool handedOver;

  /// Pays the payment that is due, through any UPI app.
  final String? upiUri;
  final InstallVisit? nextVisit;

  /// The payment to make now, if any.
  InstallPayment? get due =>
      payments.where((p) => p.status == PaymentStatus.due).firstOrNull;

  @override
  List<Object?> get props => [
    systemKw,
    place,
    stageIndex,
    stageCount,
    totalPaise,
    subsidyPaise,
    stages,
    payments,
    handedOver,
    upiUri,
    nextVisit,
  ];
}

class InstallRepository {
  new(this._api);

  final api.InstallApi _api;

  Future<Install> mine(String orgId) async {
    final response = await apiCall(() => _api.getMyInstall(orgId: orgId));
    return _install(response.data!);
  }

  /// Tells the company the customer paid [paymentId]. Pass the same
  /// [idempotencyKey] when retrying.
  Future<Install> claim({
    required String orgId,
    required String paymentId,
    required PaymentMethod method,
    required String idempotencyKey,
  }) async {
    final response = await apiCall(
      () => _api.claimInstallPayment(
        orgId: orgId,
        paymentId: paymentId,
        idempotencyKey: idempotencyKey,
        claimInstallPaymentRequest: api.ClaimInstallPaymentRequest(
          method: switch (method) {
            PaymentMethod.upi => api.ClaimInstallPaymentRequestMethodEnum.upi,
            PaymentMethod.bankTransfer =>
              api.ClaimInstallPaymentRequestMethodEnum.bankTransfer,
          },
        ),
      ),
    );
    return _install(response.data!);
  }

  static Install _install(api.Install i) => Install(
    systemKw: i.systemKw,
    place: i.place,
    stageIndex: i.stageIndex,
    stageCount: i.stageCount,
    totalPaise: i.total,
    subsidyPaise: i.subsidy,
    handedOver: i.handedOverOn != null,
    upiUri: i.upiUri,
    nextVisit: switch (i.nextVisit) {
      final v? => InstallVisit(
        title: v.title,
        startsAt: v.startsAt,
        endsAt: v.endsAt,
        personName: v.person.name,
        personPhone: v.person.phone,
      ),
      null => null,
    },
    stages: [
      for (final s in i.stages)
        InstallStage(
          name: s.name,
          detail: s.detail,
          status: StageStatus.values.byName(s.status.name),
        ),
    ],
    payments: [
      for (final p in i.payments)
        InstallPayment(
          id: p.id,
          label: p.label,
          detail: p.detail,
          amountPaise: p.amount,
          status: PaymentStatus.values.byName(p.status.name),
        ),
    ],
  );
}
