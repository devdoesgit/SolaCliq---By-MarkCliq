import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:api_client/api_client.dart' as api;
import 'package:dio/dio.dart';
import 'package:solacliq/app/data/api_call.dart';

/// What a file is for; the server keeps receipts and KYC apart.
enum UploadPurpose { receipt, kyc, proof }

/// Why a picked file can't be uploaded, found before anything is sent.
enum UploadProblem {
  /// Over the 10 MB the server takes for a receipt or photo.
  tooLarge,

  /// Over the 50 MB the server takes for a KYC document.
  documentTooLarge,
}

/// The file was refused on the phone; nothing was uploaded.
class UploadRefused implements Exception {
  const new(this.problem);

  final UploadProblem problem;

  @override
  String toString() => 'UploadRefused($problem)';
}

/*
  A file ready to upload
  ----------------------------------------------------------------------
  - a picked file stays on disk and is streamed from there: five 50 MB
    documents are never in memory (F5)
  - a camera shot (10 MB at most) may be held as bytes
*/
class UploadFile {
  new({required this.name, required Uint8List this.bytes})
    : length = bytes.length,
      head = Uint8List.sublistView(bytes, 0, min(bytes.length, _headBytes)),
      path = null,
      open = (() => _pieces(bytes));

  /// [open] gives the content from the start, each time it's called.
  const new streamed({
    required this.name,
    required this.length,
    required this.head,
    required this.open,
    this.path,
  }) : bytes = null;

  final String name;
  final int length;

  /// The first bytes, enough to tell the type.
  final Uint8List head;
  final Stream<List<int>> Function() open;

  /// Where it is, for a preview; null when it isn't a plain file.
  final String? path;

  /// The content, only for a file held in memory.
  final Uint8List? bytes;

  static const _headBytes = 8;
  static const int _piece = 64 * 1024;

  /// Reads just enough of [open] to know its type.
  static Future<UploadFile> read({
    required String name,
    required int length,
    required Stream<List<int>> Function() open,
    String? path,
  }) async {
    final head = <int>[];
    await for (final piece in open()) {
      head.addAll(piece.take(_headBytes - head.length));
      if (head.length >= _headBytes) break;
    }
    return UploadFile.streamed(
      name: name,
      length: length,
      head: Uint8List.fromList(head),
      open: open,
      path: path,
    );
  }

  // In pieces, so that progress (and a stall) can be seen.
  static Stream<List<int>> _pieces(Uint8List bytes) async* {
    for (var at = 0; at < bytes.length; at += _piece) {
      yield Uint8List.sublistView(bytes, at, min(at + _piece, bytes.length));
    }
  }

  /*
    The type to declare: from the name, else from the first bytes, else
    JPEG. Never a refusal: what the file really shows is the admin's to
    judge (owner, 2026-11-22)
  */
  api.UploadCreateContentTypeEnum get contentType {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg' || 'jpeg':
        return api.UploadCreateContentTypeEnum.imageSlashJpeg;
      case 'png':
        return api.UploadCreateContentTypeEnum.imageSlashPng;
      case 'pdf':
        return api.UploadCreateContentTypeEnum.applicationSlashPdf;
    }
    bool starts(List<int> magic) =>
        head.length >= magic.length &&
        Iterable<int>.generate(magic.length).every((i) => head[i] == magic[i]);
    if (starts(const [0x89, 0x50, 0x4E, 0x47])) {
      return api.UploadCreateContentTypeEnum.imageSlashPng;
    }
    if (starts(const [0x25, 0x50, 0x44, 0x46])) {
      return api.UploadCreateContentTypeEnum.applicationSlashPdf;
    }
    return api.UploadCreateContentTypeEnum.imageSlashJpeg;
  }

  /// Why it can't be uploaded as [purpose] (only its size), or null.
  UploadProblem? problemFor(UploadPurpose purpose) {
    final (max, problem) = purpose == UploadPurpose.kyc
        ? (UploadRepository.maxKycBytes, UploadProblem.documentTooLarge)
        : (UploadRepository.maxBytes, UploadProblem.tooLarge);
    return length > max ? problem : null;
  }
}

/// Uploads files to private storage: the server hands out a short-lived
/// presigned URL and the bytes go straight there, never through the API.
class UploadRepository {
  /// [_transfer] sends the bytes; it must not carry the API's auth header.
  new(this._api, this._transfer);

  final api.UploadsApi _api;
  final Dio _transfer;

  static const int maxBytes = 10 * 1024 * 1024;
  static const int maxKycBytes = 50 * 1024 * 1024;

  /// An upload with no bytes moving for this long has failed.
  static const idleLimit = Duration(seconds: 60);

  /// Uploads [file] for the company [orgId] and returns its upload id, to
  /// attach to one of that company's records. [UploadRefused] before
  /// anything is sent when the file is over [purpose]'s limit. Completing
  /// [cancelled] stops it.
  Future<String> upload(
    String orgId,
    UploadFile file,
    UploadPurpose purpose, {
    void Function(int percent)? onProgress,
    Future<void>? cancelled,
  }) async {
    if (file.problemFor(purpose) case final problem?) {
      throw UploadRefused(problem);
    }
    final type = file.contentType;
    final response = await apiCall(
      () => _api.createUpload(
        orgId: orgId,
        uploadCreate: api.UploadCreate(
          contentType: type,
          sizeBytes: file.length,
          purpose: switch (purpose) {
            UploadPurpose.receipt => api.UploadCreatePurposeEnum.receipt,
            UploadPurpose.kyc => api.UploadCreatePurposeEnum.kyc,
            UploadPurpose.proof => api.UploadCreatePurposeEnum.proof,
          },
        ),
      ),
    );
    final slot = response.data!;
    final url = Uri.parse(slot.url);
    // The development mock hands out `.invalid` URLs that nothing serves;
    // treat those as already uploaded.
    if (!url.host.endsWith('.invalid')) {
      await _put(
        url,
        file,
        method: slot.method.value,
        headers: {
          ...slot.headers,
          Headers.contentLengthHeader: file.length,
          Headers.contentTypeHeader: type.value,
        },
        onProgress: onProgress,
        cancelled: cancelled,
      );
    }
    return slot.uploadId;
  }

  /*
    Sends the bytes
    --------------------------------------------------------------------
    - no limit on the whole transfer (dio's send timeout is one): it
      fails after [idleLimit] with nothing moving, however big the file
    - the signed URL only has to be valid when it starts
  */
  Future<void> _put(
    Uri url,
    UploadFile file, {
    required String method,
    required Map<String, dynamic> headers,
    void Function(int percent)? onProgress,
    Future<void>? cancelled,
  }) async {
    final token = CancelToken();
    void stop() {
      if (!token.isCancelled) token.cancel();
    }

    var idle = Timer(idleLimit, stop);
    unawaited(cancelled?.then((_) => stop()));
    try {
      await apiCall(
        () => _transfer.requestUri<void>(
          url,
          data: file.open(),
          cancelToken: token,
          onSendProgress: (sent, _) {
            idle.cancel();
            idle = Timer(idleLimit, stop);
            if (file.length > 0) {
              onProgress?.call(min(100, sent * 100 ~/ file.length));
            }
          },
          options: Options(
            method: method,
            sendTimeout: Duration.zero,
            headers: headers,
          ),
        ),
      );
    } finally {
      idle.cancel();
    }
  }
}
