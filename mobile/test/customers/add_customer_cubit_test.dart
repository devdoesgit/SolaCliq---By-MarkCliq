import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/cubit/add_customer_cubit.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';

import '../helpers/helpers.dart';

void main() {
  late MockUploadRepository uploads;
  late MockRegistrationRepository registrations;
  final file = UploadFile(name: 'a.jpg', bytes: Uint8List(4));

  CustomerDraft draft(Map<KycKind, String> documents) => CustomerDraft(
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

  group(AddCustomerCubit, () {
    blocTest<AddCustomerCubit, AddCustomerState>(
      'uploads a document as KYC and records its id',
      setUp: () =>
          when(() => uploads.upload(any(), any()))
              .thenAnswer((_) async => 'up-1'),
      build: build,
      act: (c) => c.addDocument(KycKind.pan, file),
      expect: () => [
        const AddCustomerState(docs: {KycKind.pan: DocUploading()}),
        const AddCustomerState(docs: {KycKind.pan: DocUploaded('up-1')}),
      ],
      verify: (_) => verify(() => uploads.upload(file, UploadPurpose.kyc)),
    );

    blocTest<AddCustomerCubit, AddCustomerState>(
      'a failed or oversized upload can be retried',
      setUp: () =>
          when(() => uploads.upload(any(), any()))
              .thenThrow(const UploadTooLarge()),
      build: build,
      act: (c) => c.addDocument(KycKind.pan, file),
      skip: 1,
      expect: () => [
        const AddCustomerState(docs: {KycKind.pan: DocFailed(tooLarge: true)}),
      ],
    );

    test('needs the bank proof only with the subsidy', () {
      const state = AddCustomerState(
        docs: {
          KycKind.aadhaar: DocUploaded('a'),
          KycKind.pan: DocUploaded('b'),
          KycKind.electricityBill: DocUploaded('c'),
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
        docs: {KycKind.aadhaar: DocUploaded('a'), KycKind.pan: DocUploading()},
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
        expect((calls[1] as CustomerDraft).documents, {KycKind.aadhaar: 'a'});
        expect(c.state.failure, AuthFailureCode.network);
      },
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
  });
}
