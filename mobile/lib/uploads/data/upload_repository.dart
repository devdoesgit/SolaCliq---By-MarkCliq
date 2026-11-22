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

/// A file picked on the phone, ready to upload.
class UploadFile {
  const new({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

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
        bytes.length >= magic.length &&
        Iterable<int>.generate(magic.length).every((i) => bytes[i] == magic[i]);
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
    return bytes.length > max ? problem : null;
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

  /*
    How long sending may take: 2 minutes, and a second for each 64 KB
    (about 0.5 Mbps), as dio's send timeout is for the whole transfer.
    The signed URL only has to be valid when it starts
  */
  static Duration _timeToSend(int bytes) =>
      const Duration(minutes: 2) + Duration(seconds: bytes ~/ (64 * 1024));

  /// Uploads [file] for the company [orgId] and returns its upload id, to
  /// attach to one of that company's records. [UploadRefused] before
  /// anything is sent when the file is over [purpose]'s limit.
  Future<String> upload(
    String orgId,
    UploadFile file,
    UploadPurpose purpose,
  ) async {
    if (file.problemFor(purpose) case final problem?) {
      throw UploadRefused(problem);
    }
    final type = file.contentType;
    final response = await apiCall(
      () => _api.createUpload(
        orgId: orgId,
        uploadCreate: api.UploadCreate(
          contentType: type,
          sizeBytes: file.bytes.length,
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
      await apiCall(
        () => _transfer.requestUri<void>(
          url,
          data: Stream.fromIterable([file.bytes]),
          options: Options(
            method: slot.method.value,
            sendTimeout: _timeToSend(file.bytes.length),
            headers: {
              ...slot.headers,
              Headers.contentLengthHeader: file.bytes.length,
              Headers.contentTypeHeader: type.value,
            },
          ),
        ),
      );
    }
    return slot.uploadId;
  }
}
