import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/cubit/add_customer_cubit.dart';
import 'package:solacliq/customers/data/kyc_files.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

import '../helpers/helpers.dart';

void main() {
  late MockUploadRepository uploads;
  late MockRegistrationRepository registrations;
  final file = UploadFile(
    name: 'a.jpg',
    bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
  );

  CustomerDraft draft(Map<KycKind, List<DocumentUpload>> documents) =>
      CustomerDraft(
        name: 'Test',
        phone: '9814022671',
        email: 't@example.com',
        address: 'H 1',
        city: 'Mohali',
        pinCode: '160062',
        state: 'Punjab',
        discom: 'PSPCL',
        consumerNumber: '3002',
        sanctionedLoadKw: 5,
        connectionType: ConnectionType.residential,
        proposedKw: 5,
        roof: Roof.rcc,
        subsidy: false,
        documents: documents,
        consent: true,
      );

  setUpAll(() {
    registerFallbackValue(file);
    registerFallbackValue(UploadPurpose.kyc);
    registerFallbackValue(draft(const {}));
  });

  setUp(() {
    uploads = MockUploadRepository();
    registrations = MockRegistrationRepository();
  });

  AddCustomerCubit build() =>
      AddCustomerCubit(uploads, registrations, orgId: 'o1');

  test('the land document and signature are required; name change is not', () {
    expect(AddCustomerState.required(subsidy: false), [
      KycKind.aadhaar,
      KycKind.pan,
      KycKind.electricityBill,
      KycKind.landDocument,
      KycKind.signature,
    ]);
    expect(
      AddCustomerState.required(subsidy: true),
      contains(KycKind.bankProof),
    );
    expect(
      AddCustomerState.required(subsidy: true),
      isNot(contains(KycKind.nameChange)),
    );
  });

  group(AddCustomerCubit, () {
    blocTest<AddCustomerCubit, AddCustomerState>(
      'uploads a document as KYC and records its id',
      setUp: () => when(
        () => uploads.upload(
          any(),
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
          cancelled: any(named: 'cancelled'),
        ),
      ).thenAnswer((_) async => 'up-1'),
      build: build,
      act: (c) => c.addDocument(KycKind.pan, file),
      expect: () => [
        const AddCustomerState(
          docs: {
            KycKind.pan: [KycFile(id: 1, state: DocUploading())],
          },
        ),
        const AddCustomerState(
          docs: {
            KycKind.pan: [KycFile(id: 1, state: DocUploaded('up-1'))],
          },
        ),
      ],
      verify: (_) => verify(
        () => uploads.upload(
          'o1',
          file,
          UploadPurpose.kyc,
          onProgress: any(named: 'onProgress'),
          cancelled: any(named: 'cancelled'),
        ),
      ),
    );

    blocTest<AddCustomerCubit, AddCustomerState>(
      'a failed or oversized upload can be retried',
      setUp: () => when(
        () => uploads.upload(
          any(),
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
          cancelled: any(named: 'cancelled'),
        ),
      ).thenThrow(const UploadRefused(UploadProblem.tooLarge)),
      build: build,
      act: (c) => c.addDocument(KycKind.pan, file),
      skip: 1,
      expect: () => [
        const AddCustomerState(
          docs: {
            KycKind.pan: [
              KycFile(id: 1, state: DocFailed(problem: UploadProblem.tooLarge)),
            ],
          },
        ),
      ],
    );

    test('needs the bank proof only with the subsidy', () {
      const state = AddCustomerState(
        docs: {
          KycKind.aadhaar: [KycFile(id: 1, state: DocUploaded('a'))],
          KycKind.pan: [KycFile(id: 1, state: DocUploaded('b'))],
          KycKind.electricityBill: [KycFile(id: 1, state: DocUploaded('c'))],
          KycKind.landDocument: [KycFile(id: 1, state: DocUploaded('d'))],
          KycKind.signature: [KycFile(id: 1, state: DocUploaded('e'))],
        },
      );
      expect(state.missing(subsidy: false), 0);
      expect(state.missing(subsidy: true), 1);
    });

    blocTest<AddCustomerCubit, AddCustomerState>(
      'submits the uploaded documents with one key for retries',
      setUp: () {
        when(
          () => registrations.submit(
            orgId: any(named: 'orgId'),
            idempotencyKey: any(named: 'idempotencyKey'),
            draft: any(named: 'draft'),
          ),
        ).thenThrow(const AuthFailure(AuthFailureCode.network));
      },
      build: build,
      seed: () => const AddCustomerState(
        docs: {
          KycKind.aadhaar: [KycFile(id: 1, state: DocUploaded('a'))],
          KycKind.pan: [KycFile(id: 1, state: DocUploading())],
        },
      ),
      act: (c) async {
        await c.submit(draft);
        await c.submit(draft);
      },
      verify: (c) {
        final calls = verify(
          () => registrations.submit(
            orgId: 'o1',
            idempotencyKey: captureAny(named: 'idempotencyKey'),
            draft: captureAny(named: 'draft'),
          ),
        ).captured;
        // Two attempts: same key both times, only finished uploads sent.
        expect(calls[0], calls[2]);
        expect((calls[1] as CustomerDraft).documents, {
          KycKind.aadhaar: const [DocumentUpload('a')],
        });
        expect(c.state.failure, AuthFailureCode.network);
      },
    );

    blocTest<AddCustomerCubit, AddCustomerState>(
      'a duplicate shows who registered the customer first',
      setUp: () =>
          when(
            () => registrations.submit(
              orgId: any(named: 'orgId'),
              idempotencyKey: any(named: 'idempotencyKey'),
              draft: any(named: 'draft'),
            ),
          ).thenThrow(
            const AuthFailure(
              AuthFailureCode.registrationDuplicate,
              null,
              'Meena registered this customer on 14 Nov 2026 (SC-0002).',
            ),
          ),
      build: build,
      act: (c) => c.submit(draft),
      expect: () => [
        const AddCustomerState(submitting: true),
        const AddCustomerState(
          failure: AuthFailureCode.registrationDuplicate,
          failureDetail:
              'Meena registered this customer on 14 Nov 2026 (SC-0002).',
        ),
      ],
    );

    blocTest<AddCustomerCubit, AddCustomerState>(
      'going back to edit forgets the last refusal',
      build: build,
      seed: () => const AddCustomerState(
        failure: AuthFailureCode.registrationDuplicate,
        failureDetail: 'Meena registered this customer.',
      ),
      act: (c) => c.clearFailure(),
      expect: () => [const AddCustomerState()],
    );

    blocTest<AddCustomerCubit, AddCustomerState>(
      'success keeps the reference',
      setUp: () => when(
        () => registrations.submit(
          orgId: any(named: 'orgId'),
          idempotencyKey: any(named: 'idempotencyKey'),
          draft: any(named: 'draft'),
        ),
      ).thenAnswer((_) async => 'SC-1'),
      build: build,
      act: (c) => c.submit(draft),
      expect: () => [
        const AddCustomerState(submitting: true),
        const AddCustomerState(reference: 'SC-1'),
      ],
    );

    blocTest<AddCustomerCubit, AddCustomerState>(
      'five files a document at most, and the sixth is not sent',
      setUp: () => when(
        () => uploads.upload(
          any(),
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
          cancelled: any(named: 'cancelled'),
        ),
      ).thenAnswer((_) async => 'up'),
      build: build,
      act: (c) async {
        for (var i = 0; i < 6; i++) {
          await c.addDocument(KycKind.landDocument, file);
        }
      },
      verify: (c) {
        expect(c.state.uploaded[KycKind.landDocument], hasLength(5));
        verify(
          () => uploads.upload(
            any(),
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
            cancelled: any(named: 'cancelled'),
          ),
        ).called(5);
      },
    );

    test('front, back, or both; sent front first', () async {
      var n = 0;
      when(
        () => uploads.upload(
          any(),
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
          cancelled: any(named: 'cancelled'),
        ),
      ).thenAnswer((_) async => 'up-${++n}');
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.addDocument(KycKind.aadhaar, file, side: DocumentSide.back);
      expect(cubit.state.uploaded[KycKind.aadhaar], hasLength(1));
      await cubit.addDocument(KycKind.aadhaar, file, side: DocumentSide.front);
      expect(cubit.state.uploaded[KycKind.aadhaar], const [
        DocumentUpload('up-2', side: DocumentSide.front),
        DocumentUpload('up-1', side: DocumentSide.back),
      ]);
    });

    test('retry one file, remove one file', () async {
      var n = 0;
      when(
        () => uploads.upload(
          any(),
          any(),
          any(),
          onProgress: any(named: 'onProgress'),
          cancelled: any(named: 'cancelled'),
        ),
      ).thenAnswer((_) async {
        if (++n == 1) throw const AuthFailure(AuthFailureCode.network);
        return 'up-$n';
      });
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.addDocument(KycKind.pan, file);
      await cubit.addDocument(KycKind.pan, file);
      final first = cubit.state.docs[KycKind.pan]!.first;
      expect(first.state, const DocFailed());
      await cubit.retryFile(KycKind.pan, first.id);
      expect(cubit.state.uploaded[KycKind.pan], const [
        DocumentUpload('up-3'),
        DocumentUpload('up-2'),
      ]);
      cubit.removeFile(KycKind.pan, first.id);
      expect(cubit.state.uploaded[KycKind.pan], const [DocumentUpload('up-2')]);
    });

    test('review waits while any file is on its way', () {
      const state = AddCustomerState(
        docs: {
          KycKind.pan: [
            KycFile(id: 1, state: DocUploaded('a')),
            KycFile(id: 2, state: DocUploading(40)),
          ],
        },
      );
      expect(state.uploading, isTrue);
    });
  });
}
