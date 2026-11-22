import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

import '../helpers/helpers.dart';

void main() {
  late List<RequestOptions> transfers;
  late Dio transfer;

  late List<RequestOptions> apiCalls;

  UploadRepository repository(String url) {
    final api = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = FakeAdapter((o) async {
        apiCalls.add(o);
        return jsonBody(201, {
          'upload_id': 'up-1',
          'url': url,
          'method': 'PUT',
          'headers': {'x-amz-acl': 'private'},
          'expires_at': '2026-10-26T10:00:00Z',
        });
      });
    return UploadRepository(UploadsApi(api), transfer);
  }

  setUp(() {
    apiCalls = [];
    transfers = [];
    transfer = Dio()
      ..httpClientAdapter = FakeAdapter((o) async {
        transfers.add(o);
        return jsonBody(200, null);
      });
  });

  // A JPEG's first bytes, then padding.
  final photo = UploadFile(
    name: 'receipt.jpg',
    bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0]),
  );

  group(UploadRepository, () {
    test('puts the bytes to the presigned URL, returns the id', () async {
      final id = await repository('https://storage.example.com/u/1?sig=x')
          .upload('o1', photo, UploadPurpose.receipt);
      expect(id, 'up-1');
      expect(apiCalls.single.path, '/orgs/o1/uploads', reason: 'per company');
      expect(transfers.single.method, 'PUT');
      expect(transfers.single.uri.host, 'storage.example.com');
      expect(transfers.single.headers['x-amz-acl'], 'private');
      expect(transfers.single.headers['content-type'], 'image/jpeg');
    });

    test('the mock .invalid host is treated as already uploaded', () async {
      final id = await repository('https://uploads.mock.invalid/u/1')
          .upload('o1', photo, UploadPurpose.kyc);
      expect(id, 'up-1');
      expect(transfers, isEmpty);
    });

    test('over 10 MB is refused before asking the server', () async {
      final big = UploadFile(
        name: 'big.jpg',
        bytes: Uint8List(UploadRepository.maxBytes + 1)
          ..setAll(0, [0xFF, 0xD8, 0xFF]),
      );
      await expectLater(
        repository('https://x').upload('o1', big, UploadPurpose.kyc),
        throwsA(
          isA<UploadRefused>().having(
            (e) => e.problem,
            'problem',
            UploadProblem.tooLarge,
          ),
        ),
      );
      expect(apiCalls, isEmpty);
    });

    test('the type comes from the name, else the bytes; nothing refused', () {
      UploadFile file(String name, List<int> head) =>
          UploadFile(name: name, bytes: Uint8List.fromList([...head, 0, 0]));
      expect(
        file('a.PDF', []).contentType,
        UploadCreateContentTypeEnum.applicationSlashPdf,
      );
      expect(
        file('scan', '%PDF'.codeUnits).contentType,
        UploadCreateContentTypeEnum.applicationSlashPdf,
      );
      // A renamed or unknown file still goes; the admin judges it.
      final odd = file('fake-receipt.jpg', 'not an image'.codeUnits);
      expect(odd.contentType, UploadCreateContentTypeEnum.imageSlashJpeg);
      expect(odd.problem, isNull);
      expect(
        file('photo.heic', []).contentType,
        UploadCreateContentTypeEnum.imageSlashJpeg,
      );
    });
  });
}
