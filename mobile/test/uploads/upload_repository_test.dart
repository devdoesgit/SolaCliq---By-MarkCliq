import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

import '../helpers/helpers.dart';

void main() {
  late List<RequestOptions> transfers;
  late Dio transfer;

  UploadRepository repository(String url) {
    final api = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = FakeAdapter(
        (o) async => jsonBody(201, {
          'upload_id': 'up-1',
          'url': url,
          'method': 'PUT',
          'headers': {'x-amz-acl': 'private'},
          'expires_at': '2026-10-26T10:00:00Z',
        }),
      );
    return UploadRepository(UploadsApi(api), transfer);
  }

  setUp(() {
    transfers = [];
    transfer = Dio()
      ..httpClientAdapter = FakeAdapter((o) async {
        transfers.add(o);
        return jsonBody(200, null);
      });
  });

  final photo = UploadFile(name: 'receipt.jpg', bytes: Uint8List(10));

  group(UploadRepository, () {
    test('puts the bytes to the presigned URL, returns the id', () async {
      final id = await repository('https://storage.example.com/u/1?sig=x')
          .upload(photo, UploadPurpose.receipt);
      expect(id, 'up-1');
      expect(transfers.single.method, 'PUT');
      expect(transfers.single.uri.host, 'storage.example.com');
      expect(transfers.single.headers['x-amz-acl'], 'private');
      expect(transfers.single.headers['content-type'], 'image/jpeg');
    });

    test('the mock .invalid host is treated as already uploaded', () async {
      final id = await repository('https://uploads.mock.invalid/u/1')
          .upload(photo, UploadPurpose.kyc);
      expect(id, 'up-1');
      expect(transfers, isEmpty);
    });

    test('over 10 MB is refused before asking the server', () async {
      final big = UploadFile(
        name: 'big.jpg',
        bytes: Uint8List(UploadRepository.maxBytes + 1),
      );
      await expectLater(
        repository('https://x').upload(big, UploadPurpose.kyc),
        throwsA(isA<UploadTooLarge>()),
      );
    });

    test('content type comes from the file name', () {
      expect(
        UploadFile(name: 'a.PDF', bytes: Uint8List(1)).contentType,
        UploadCreateContentTypeEnum.applicationSlashPdf,
      );
      expect(UploadFile(name: 'a.heic', bytes: Uint8List(1)).contentType, null);
    });
  });
}
