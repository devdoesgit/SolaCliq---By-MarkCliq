import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

/// The most files one document holds.
const maxFilesPerDocument = 5;

/// Where one file is.
sealed class DocState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

final class DocUploading extends DocState {
  const new([this.percent = 0]);

  final int percent;

  @override
  List<Object?> get props => [percent];
}

final class DocUploaded extends DocState {
  const new(this.uploadId);

  final String uploadId;

  @override
  List<Object?> get props => [uploadId];
}

final class DocFailed extends DocState {
  const new({this.problem});

  /// Refused on the phone (too big); null when the upload itself failed.
  final UploadProblem? problem;

  @override
  List<Object?> get props => [problem];
}

/// One picked file of one document.
class KycFile extends Equatable {
  const new({required this.id, required this.state, this.side});

  /// On this phone only: keys its row.
  final int id;
  final DocumentSide? side;
  final DocState state;

  @override
  List<Object?> get props => [id, side, state];
}

/// Files in the order they're sent: front, back, then the rest as added.
List<KycFile> inSendOrder(List<KycFile> files) => [
  ...files.where((f) => f.side == DocumentSide.front),
  ...files.where((f) => f.side == DocumentSide.back),
  ...files.where((f) => f.side == null),
];

/// The files that are up, as the API takes them.
List<DocumentUpload> uploadedOf(List<KycFile> files) => [
  for (final f in inSendOrder(files))
    if (f.state case DocUploaded(:final uploadId))
      DocumentUpload(uploadId, side: f.side),
];

/*
  The files an agent is adding to KYC documents (F5)
  ----------------------------------------------------------------------
  - each file uploads by itself, as soon as it's picked, and can be
    retried (a new URL) or removed, which stops it
  - removing only forgets it here: the server sweeps what was never used
  - shared by Add customer and Fix document, which each show `changed`
*/
class KycUploader {
  new(this._uploads, {required this.orgId, required this.changed});

  final UploadRepository _uploads;
  final String orgId;
  final void Function(Map<KycKind, List<KycFile>> files) changed;

  Map<KycKind, List<KycFile>> _files = const {};
  final _picked = <int, UploadFile>{};
  final _cancels = <int, Completer<void>>{};
  int _lastId = 0;
  bool _closed = false;

  Future<void> add(KycKind kind, UploadFile file, {DocumentSide? side}) async {
    final files = _files[kind] ?? const [];
    if (files.length >= maxFilesPerDocument) return;
    final id = ++_lastId;
    _picked[id] = file;
    _set(kind, [
      ...files,
      KycFile(id: id, side: side, state: const DocUploading()),
    ]);
    await _send(kind, id);
  }

  Future<void> retry(KycKind kind, int id) async {
    if (!_picked.containsKey(id) || _cancels.containsKey(id)) return;
    _update(kind, id, const DocUploading());
    await _send(kind, id);
  }

  void remove(KycKind kind, int id) {
    _cancels.remove(id)?.complete();
    _picked.remove(id);
    _set(kind, [
      for (final f in _files[kind] ?? const <KycFile>[])
        if (f.id != id) f,
    ]);
  }

  void close() {
    _closed = true;
    for (final cancel in _cancels.values) {
      cancel.complete();
    }
    _cancels.clear();
  }

  Future<void> _send(KycKind kind, int id) async {
    final file = _picked[id];
    if (file == null) return;
    final cancel = _cancels[id] = Completer<void>();
    try {
      final uploadId = await _uploads.upload(
        orgId,
        file,
        UploadPurpose.kyc,
        cancelled: cancel.future,
        onProgress: (percent) => _update(kind, id, DocUploading(percent)),
      );
      _update(kind, id, DocUploaded(uploadId));
    } on UploadRefused catch (refused) {
      _update(kind, id, DocFailed(problem: refused.problem));
    } on AuthFailure {
      _update(kind, id, const DocFailed());
    } finally {
      if (_cancels[id] == cancel) _cancels.remove(id);
    }
  }

  void _update(KycKind kind, int id, DocState state) {
    final files = _files[kind] ?? const [];
    // Removed meanwhile, or the same percent again.
    if (!files.any((f) => f.id == id && f.state != state)) return;
    _set(kind, [
      for (final f in files)
        if (f.id == id) KycFile(id: id, side: f.side, state: state) else f,
    ]);
  }

  void _set(KycKind kind, List<KycFile> files) {
    if (_closed) return;
    _files = {
      for (final MapEntry(:key, :value) in _files.entries)
        if (key != kind) key: value,
      if (files.isNotEmpty) kind: files,
    };
    changed(_files);
  }
}
