import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/profile/data/profile_repository.dart';

/// The account a person's commission or salary is paid into. The saved
/// number is never shown back, only its last four digits.
class BankPage extends StatefulWidget {
  const new({required this.title, super.key});

  /// "Bank for payouts" or "Bank for salary".
  final String title;

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  late Future<PersonalDetails> _loaded = _fetch();
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _ifsc = TextEditingController();
  PayoutBank? _bank;
  final _errors = <String, String?>{};
  String? _error;
  bool _saving = false;
  bool _saved = false;

  static final _numberPattern = RegExp(r'^\d{6,18}$');
  static final _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  Future<PersonalDetails> _fetch() async {
    final d = await context.read<ProfileRepository>().details();
    _bank = d.bank;
    _holder.text = d.bank?.holder ?? '';
    _ifsc.text = d.bank?.ifsc ?? '';
    return d;
  }

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    context
      ..fillBlank(_holder, 'Meena Example (illustrative)')
      ..fillBlank(_number, '50100229144100')
      ..fillBlank(_ifsc, 'HDFC0001234');
    final number = _number.text.replaceAll(RegExp(r'\s'), '');
    final ifsc = _ifsc.text.trim().toUpperCase();
    setState(() {
      _errors
        ..['holder'] = _holder.text.trim().isEmpty ? l10n.errorHolder : null
        ..['number'] = _numberPattern.hasMatch(number)
            ? null
            : l10n.errorAccountNumber
        ..['ifsc'] = _ifscPattern.hasMatch(ifsc) ? null : l10n.errorIfsc;
      _error = null;
      _saved = false;
    });
    if (_errors.values.any((e) => e != null)) return;
    final repo = context.read<ProfileRepository>();
    setState(() => _saving = true);
    try {
      final d = await repo.saveBank(
        holder: _holder.text.trim(),
        accountNumber: number,
        ifsc: ifsc,
      );
      if (!mounted) return;
      setState(() {
        _bank = d.bank;
        _number.clear();
        _saved = true;
      });
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.code.message(l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final error = _error;
    final last4 = _bank?.last4;
    return SolaScreen(
      background: SolaBackground.stone,
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: widget.title,
      ),
      body: LoadView(
        future: _loaded,
        failedTitle: l10n.detailsLoadFailed,
        onRetry: () => setState(() => _loaded = _fetch()),
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SolaSpace.space14,
          children: [
            SolaText(l10n.bankIntro, color: SolaColors.muted),
            SolaGroup(
              children: [
                SolaFieldRow(
                  key: const ValueKey('bank_holder'),
                  label: l10n.accountHolder,
                  controller: _holder,
                  error: _errors['holder'],
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _errors['holder'] = null,
                ),
                SolaFieldRow(
                  key: const ValueKey('bank_number'),
                  label: l10n.accountNumber,
                  controller: _number,
                  placeholder: last4 == null
                      ? null
                      : l10n.accountNumberSaved(last4),
                  error: _errors['number'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _errors['number'] = null,
                ),
                SolaFieldRow(
                  key: const ValueKey('bank_ifsc'),
                  label: l10n.ifscLabel,
                  controller: _ifsc,
                  error: _errors['ifsc'],
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => _errors['ifsc'] = null,
                ),
                if (_bank?.bankName case final name?)
                  SolaKeyValueRow(l10n.bankNameLabel, name),
              ],
            ),
            if (_saved)
              SolaBanner(
                title: l10n.savedTitle,
                body: l10n.bankSavedBody,
                tone: SolaTone.success,
                icon: SolaIcons.check,
              ),
            if (error != null)
              SolaNotice(
                key: const Key('failure_notice'),
                title: error,
                announce: true,
              ),
          ],
        ),
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('bank_save'),
            label: l10n.saveLabel,
            onPressed: _saving ? null : () => unawaited(_save()),
          ),
        ],
      ),
    );
  }
}
