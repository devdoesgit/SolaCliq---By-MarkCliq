import 'package:api_client/api_client.dart' as api;
import 'package:equatable/equatable.dart';
import 'package:solacliq/app/data/api_call.dart';
import 'package:solacliq/customers/data/registration_repository.dart';

/// The account for salary or commission payouts. The number comes back
/// masked; only [last4] is known after saving.
class PayoutBank extends Equatable {
  const new({this.holder, this.last4, this.ifsc, this.bankName});

  final String? holder;
  final String? last4;
  final String? ifsc;
  final String? bankName;

  @override
  List<Object?> get props => [holder, last4, ifsc, bankName];
}

/// The person's own details, the same in every company they work with.
class PersonalDetails extends Equatable {
  const new({this.phone, this.address, this.emergencyContact, this.bank});

  final String? phone;
  final String? address;
  final String? emergencyContact;
  final PayoutBank? bank;

  @override
  List<Object?> get props => [phone, address, emergencyContact, bank];
}

enum AppLanguage { en, hi, pa }

class AppSettings extends Equatable {
  const new({
    required this.push,
    required this.whatsapp,
    required this.sound,
    required this.language,
  });

  final bool push;
  final bool whatsapp;
  final bool sound;
  final AppLanguage language;

  AppSettings copyWith({
    bool? push,
    bool? whatsapp,
    bool? sound,
    AppLanguage? language,
  }) => AppSettings(
    push: push ?? this.push,
    whatsapp: whatsapp ?? this.whatsapp,
    sound: sound ?? this.sound,
    language: language ?? this.language,
  );

  @override
  List<Object> get props => [push, whatsapp, sound, language];
}

enum DocumentStatus { verified, inReview, needsFix }

/// A document a company holds for the person: a worker's ID, a customer's
/// KYC.
class MyDocument extends Equatable {
  const new({required this.kind, required this.status, this.detail});

  final KycKind kind;
  final DocumentStatus status;
  final String? detail;

  @override
  List<Object?> get props => [kind, status, detail];
}

class MyDocuments extends Equatable {
  const new({required this.items, this.uploadedBy});

  final List<MyDocument> items;

  /// The agent who collected a customer's KYC.
  final String? uploadedBy;

  @override
  List<Object?> get props => [items, uploadedBy];
}

/// The person's details, payout bank, settings and documents.
class ProfileRepository {
  new(this._api);

  final api.ProfileApi _api;

  Future<PersonalDetails> details() async {
    final response = await apiCall(_api.getMyDetails);
    return _details(response.data!);
  }

  /// Saves what is passed; null fields stay as they are.
  Future<PersonalDetails> saveDetails({
    String? phone,
    String? address,
    String? emergencyContact,
  }) async {
    final response = await apiCall(
      () => _api.updateMyDetails(
        personalDetails: api.PersonalDetails(
          phone: phone,
          address: address,
          emergencyContact: emergencyContact,
        ),
      ),
    );
    return _details(response.data!);
  }

  Future<PersonalDetails> saveBank({
    required String holder,
    required String accountNumber,
    required String ifsc,
  }) async {
    final response = await apiCall(
      () => _api.updateMyDetails(
        personalDetails: api.PersonalDetails(
          bank: api.PayoutBank(
            holder: holder,
            accountNumber: accountNumber,
            ifsc: ifsc,
          ),
        ),
      ),
    );
    return _details(response.data!);
  }

  Future<AppSettings> settings() async {
    final response = await apiCall(_api.getMySettings);
    return _settings(response.data!);
  }

  Future<AppSettings> saveSettings(AppSettings s) async {
    final response = await apiCall(
      () => _api.updateMySettings(
        settings: api.Settings(
          push: s.push,
          whatsapp: s.whatsapp,
          sound: s.sound,
          language: api.SettingsLanguageEnum.values.byName(s.language.name),
        ),
      ),
    );
    return _settings(response.data!);
  }

  Future<MyDocuments> documents(String orgId) async {
    final response = await apiCall(() => _api.listMyDocuments(orgId: orgId));
    final list = response.data!;
    return MyDocuments(
      uploadedBy: list.uploadedBy,
      items: [
        for (final d in list.items)
          MyDocument(
            kind: KycKind.values.byName(d.kind.name),
            detail: d.detail,
            status: switch (d.status) {
              api.DocumentStatus.verified => DocumentStatus.verified,
              api.DocumentStatus.inReview => DocumentStatus.inReview,
              api.DocumentStatus.needsFix => DocumentStatus.needsFix,
            },
          ),
      ],
    );
  }

  static PersonalDetails _details(api.PersonalDetails d) => PersonalDetails(
    phone: d.phone,
    address: d.address,
    emergencyContact: d.emergencyContact,
    bank: switch (d.bank) {
      final b? => PayoutBank(
        holder: b.holder,
        last4: b.accountLast4,
        ifsc: b.ifsc,
        bankName: b.bankName,
      ),
      null => null,
    },
  );

  static AppSettings _settings(api.Settings s) => AppSettings(
    push: s.push,
    whatsapp: s.whatsapp,
    sound: s.sound,
    language: AppLanguage.values.byName(s.language.name),
  );
}
