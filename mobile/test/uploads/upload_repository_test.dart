import 'dart:async';
import 'dart:typed_data';

import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/auth/auth.dart';
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

    const mb = 1024 * 1024;
    for (final (purpose, limit, problem) in [
      (UploadPurpose.kyc, 50 * mb, UploadProblem.documentTooLarge),
      (UploadPurpose.receipt, 10 * mb, UploadProblem.tooLarge),
      (UploadPurpose.proof, 10 * mb, UploadProblem.tooLarge),
    ]) {
      test('${purpose.name}: up to ${limit ~/ mb} MB goes', () async {
        final file = UploadFile(name: 'a.pdf', bytes: Uint8List(limit));
        await repository('https://x').upload('o1', file, purpose);
        expect(transfers, hasLength(1));
      });

      test('${purpose.name}: over it is refused unsent', () async {
        final big = UploadFile(name: 'a.pdf', bytes: Uint8List(limit + 1));
        await expectLater(
          repository('https://x').upload('o1', big, purpose),
          throwsA(
            isA<UploadRefused>().having((e) => e.problem, 'problem', problem),
          ),
        );
        expect(apiCalls, isEmpty);
      });
    }

    test('the whole transfer has no time limit, only idleness has', () async {
      final file = UploadFile(name: 'a.pdf', bytes: Uint8List(50 * mb));
      await repository('https://x').upload('o1', file, UploadPurpose.kyc);
      // dio's send timeout is for the whole transfer: zero turns it off.
      expect(transfers.single.sendTimeout, Duration.zero);
    });

    test('a big file is sent from disk, never read into memory', () async {
      var largest = 0;
      var total = 0;
      transfer.httpClientAdapter = _Server((stream, _) async {
        await for (final piece in stream) {
          total += piece.length;
          if (piece.length > largest) largest = piece.length;
        }
      });
      final piece = Uint8List(64 * 1024);
      final file = await UploadFile.read(
        name: 'deed.pdf',
        length: 50 * mb,
        open: () => Stream.fromIterable(
          Iterable.generate(50 * mb ~/ piece.length, (_) => piece),
        ),
      );
      expect(file.bytes, isNull);
      final seen = <int>[];
      await repository('https://x')
          .upload('o1', file, UploadPurpose.kyc, onProgress: seen.add);
      expect(total, 50 * mb);
      expect(largest, lessThanOrEqualTo(64 * 1024));
      expect(seen.last, 100);
    });

    testWidgets('nothing moving for 60 seconds fails', (tester) async {
      transfer.httpClientAdapter = _Server((_, cancel) => cancel!);
      Object? failed;
      unawaited(
        repository('https://x')
            .upload('o1', photo, UploadPurpose.kyc)
            .then<void>((_) {}, onError: (Object e) => failed = e),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 55));
      expect(failed, isNull);
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(seconds: 1));
      expect(failed, isA<AuthFailure>());
    });

    test('removing a file stops its upload', () async {
      transfer.httpClientAdapter = _Server((_, cancel) => cancel!);
      final cancelled = Completer<void>();
      final sending = repository('https://x')
          .upload('o1', photo, UploadPurpose.kyc, cancelled: cancelled.future);
      cancelled.complete();
      await expectLater(sending, throwsA(isA<AuthFailure>()));
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
      expect(odd.problemFor(UploadPurpose.kyc), isNull);
      expect(
        file('photo.heic', []).contentType,
        UploadCreateContentTypeEnum.imageSlashJpeg,
      );
    });
  });
}

/// Storage that does what [handle] says with the bytes.
class _Server implements HttpClientAdapter {
  new(this.handle);

  final Future<void> Function(Stream<Uint8List> body, Future<void>? cancel)
  handle;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await handle(requestStream!, cancelFuture);
    if (options.cancelToken?.isCancelled ?? false) {
      throw DioException.requestCancelled(
        requestOptions: options,
        reason: null,
      );
    }
    return jsonBody(200, null);
  }

  @override
  void close({bool force = false}) {}
}
