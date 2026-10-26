import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:uuid/uuid.dart';

/// Where one document is.
sealed class DocState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class DocUploading extends DocState {
  const new();
}

final class DocUploaded extends DocState {
  const new(this.uploadId);

  final String uploadId;

  @override
  List<Object?> get props => [uploadId];
}

final class DocFailed extends DocState {
  const new({this.tooLarge = false});

  final bool tooLarge;

  @override
  List<Object?> get props => [tooLarge];
}

class AddCustomerState extends Equatable {
  const new({
    this.docs = const {},
    this.submitting = false,
    this.failure,
    this.reference,
  });

  final Map<KycKind, DocState> docs;
  final bool submitting;
  final AuthFailureCode? failure;

  /// Set once the admin has the request: "SC-1042".
  final String? reference;

  /// The documents the admin needs: the bank proof only with the subsidy.
  static List<KycKind> required({required bool subsidy}) => [
    KycKind.aadhaar,
    KycKind.pan,
    KycKind.electricityBill,
    if (subsidy) KycKind.bankProof,
  ];

  /// Upload ids of the documents that are up.
  Map<KycKind, String> get uploaded => {
    for (final MapEntry(:key, :value) in docs.entries)
      if (value case DocUploaded(:final uploadId)) key: uploadId,
  };

  int missing({required bool subsidy}) =>
      required(subsidy: subsidy).where((k) => docs[k] is! DocUploaded).length;

  AddCustomerState copyWith({
    Map<KycKind, DocState>? docs,
    bool? submitting,
    AuthFailureCode? Function()? failure,
    String? reference,
  }) => AddCustomerState(
    docs: docs ?? this.docs,
    submitting: submitting ?? this.submitting,
    failure: failure == null ? this.failure : failure(),
    reference: reference ?? this.reference,
  );

  @override
  List<Object?> get props => [docs, submitting, failure, reference];
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

  Future<void> addDocument(KycKind kind, UploadFile file) async {
    _setDoc(kind, const DocUploading());
    try {
      final id = await _uploads.upload(file, UploadPurpose.kyc);
      _setDoc(kind, DocUploaded(id));
    } on UploadTooLarge {
      _setDoc(kind, const DocFailed(tooLarge: true));
    } on AuthFailure {
      _setDoc(kind, const DocFailed());
    }
  }

  void _setDoc(KycKind kind, DocState doc) {
    if (isClosed) return;
    emit(state.copyWith(docs: {...state.docs, kind: doc}));
  }

  Future<void> submit(
    CustomerDraft Function(Map<KycKind, String>) draft,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, failure: () => null));
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
        emit(state.copyWith(submitting: false, failure: () => failure.code));
      }
    }
  }
}
