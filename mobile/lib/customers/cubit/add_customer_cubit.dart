import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/kyc_files.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:uuid/uuid.dart';

class AddCustomerState extends Equatable {
  const new({
    this.docs = const {},
    this.submitting = false,
    this.failure,
    this.failureDetail,
    this.reference,
  });

  final Map<KycKind, List<KycFile>> docs;
  final bool submitting;
  final AuthFailureCode? failure;

  /// The server's explanation of [failure], e.g. who registered the
  /// customer first.
  final String? failureDetail;

  /// Set once the admin has the request: "SC-1042".
  final String? reference;

  /// The documents the admin needs: the bank proof only with the subsidy.
  /// The roof photo and the name change document are optional.
  static List<KycKind> required({required bool subsidy}) => [
    KycKind.aadhaar,
    KycKind.pan,
    KycKind.electricityBill,
    KycKind.landDocument,
    KycKind.signature,
    if (subsidy) KycKind.bankProof,
  ];

  /// The files that are up, by document. One is enough for a document.
  Map<KycKind, List<DocumentUpload>> get uploaded => {
    for (final MapEntry(:key, :value) in docs.entries)
      if (uploadedOf(value) case final files when files.isNotEmpty) key: files,
  };

  /// Any file still on its way: review waits for it.
  bool get uploading =>
      docs.values.any((files) => files.any((f) => f.state is DocUploading));

  int missing({required bool subsidy}) {
    final up = uploaded;
    return required(subsidy: subsidy).where((k) => !up.containsKey(k)).length;
  }

  AddCustomerState copyWith({
    Map<KycKind, List<KycFile>>? docs,
    bool? submitting,
    AuthFailureCode? Function()? failure,
    String? Function()? failureDetail,
    String? reference,
  }) => AddCustomerState(
    docs: docs ?? this.docs,
    submitting: submitting ?? this.submitting,
    failure: failure == null ? this.failure : failure(),
    failureDetail: failureDetail == null ? this.failureDetail : failureDetail(),
    reference: reference ?? this.reference,
  );

  @override
  List<Object?> get props => [
    docs,
    submitting,
    failure,
    failureDetail,
    reference,
  ];
}

/// Holds an agent's new customer across the steps: uploads each document
/// as it is added, then submits the lot for the admin to approve.
class AddCustomerCubit extends Cubit<AddCustomerState> {
  new(this._uploads, this._registrations, {required this.orgId})
    : super(const AddCustomerState());

  final UploadRepository _uploads;
  final RegistrationRepository _registrations;
  final String orgId;

  /// One per customer, so a retry can't register them twice.
  final String _idempotencyKey = const Uuid().v4();

  late final KycUploader _files = KycUploader(
    _uploads,
    orgId: orgId,
    changed: (docs) {
      if (!isClosed) emit(state.copyWith(docs: docs));
    },
  );

  Future<void> addDocument(
    KycKind kind,
    UploadFile file, {
    DocumentSide? side,
  }) => _files.add(kind, file, side: side);

  Future<void> retryFile(KycKind kind, int id) => _files.retry(kind, id);

  void removeFile(KycKind kind, int id) => _files.remove(kind, id);

  @override
  Future<void> close() {
    _files.close();
    return super.close();
  }

  /// Forgets the last refusal, once the agent goes back to change things.
  void clearFailure() {
    if (state.failure == null || isClosed) return;
    emit(state.copyWith(failure: () => null, failureDetail: () => null));
  }

  Future<void> submit(
    CustomerDraft Function(Map<KycKind, List<DocumentUpload>>) draft,
  ) async {
    if (state.submitting) return;
    emit(
      state.copyWith(
        submitting: true,
        failure: () => null,
        failureDetail: () => null,
      ),
    );
    try {
      final reference = await _registrations.submit(
        orgId: orgId,
        idempotencyKey: _idempotencyKey,
        draft: draft(state.uploaded),
      );
      if (!isClosed) {
        emit(state.copyWith(submitting: false, reference: reference));
      }
    } on AuthFailure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            submitting: false,
            failure: () => failure.code,
            failureDetail: () => failure.detail,
          ),
        );
      }
    }
  }
}
