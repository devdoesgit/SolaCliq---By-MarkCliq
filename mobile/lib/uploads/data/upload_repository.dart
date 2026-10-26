import 'dart:typed_data';

import 'package:api_client/api_client.dart' as api;
import 'package:dio/dio.dart';
import 'package:solacliq/app/data/api_call.dart';

/// What a file is for; the server keeps receipts and KYC apart.
enum UploadPurpose { receipt, kyc, proof }

/// The file is over the 10 MB the server accepts.
class UploadTooLarge implements Exception {
  const new();
}

/// A file picked on the phone, ready to upload.
class UploadFile {
  const new({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  /// The type the server accepts for [name], or null if it takes none.
  api.UploadCreateContentTypeEnum? get contentType {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => api.UploadCreateContentTypeEnum.imageSlashJpeg,
      'png' => api.UploadCreateContentTypeEnum.imageSlashPng,
      'pdf' => api.UploadCreateContentTypeEnum.applicationSlashPdf,
      _ => null,
    };
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

  /// Uploads [file] and returns its upload id, to attach to a record.
  Future<String> upload(UploadFile file, UploadPurpose purpose) async {
    if (file.bytes.length > maxBytes) throw const UploadTooLarge();
    final type =
        file.contentType ?? api.UploadCreateContentTypeEnum.imageSlashJpeg;
    final response = await apiCall(
      () => _api.createUpload(
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
