import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/chip_group.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/auth/cubit/submit_cubit.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/auth/widgets/failure_notice.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/quotes/data/quote_repository.dart';
import 'package:solacliq/quotes/view/quote_sent_page.dart';

/// Asks verified companies nearby for a solar quote: what for, where, the
/// bill, the roof and when. Becomes a lead; the company that accepts calls.
class QuoteRequestPage extends StatelessWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubmitCubit(),
      child: QuoteRequestView(account: account),
    );
  }
}

class QuoteRequestView extends StatefulWidget {
  const new({required this.account, super.key});

  final Account account;

  @override
  State<QuoteRequestView> createState() => _QuoteRequestViewState();
}

class _QuoteRequestViewState extends State<QuoteRequestView> {
  final _pin = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  QuoteFor _for = QuoteFor.home;
  BillBand? _bill;
  RoofType _roof = RoofType.rcc;
  QuoteTimeline? _when;
  bool _consent = false;
  final _errors = <String, String?>{};

  bool get _needsPhone => widget.account.phone == null;

  @override
  void dispose() {
    _pin.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (context.quickForms) {
      context
        ..fillBlank(_pin, '160055')
        ..fillBlank(_city, 'Mohali');
      if (_needsPhone) context.fillBlank(_phone, '98765 43210');
      _bill ??= BillBand.from3000To6000;
      _when ??= QuoteTimeline.exploring;
      _consent = true;
    }
    final l10n = context.l10n;
    setState(() {
      _errors
        ..['pin'] = RegExp(r'^[1-9]\d{5}$').hasMatch(_pin.text.trim())
            ? null
            : l10n.errorPinCode
        ..['city'] = AuthValidators.required(_city.text, l10n.fieldCity, l10n)
        ..['bill'] = _bill == null ? l10n.errorChoose : null
        ..['when'] = _when == null ? l10n.errorChoose : null
        ..['phone'] = _needsPhone
            ? AuthValidators.mobile(_phone.text, l10n)
            : null
        ..['consent'] = _consent ? null : l10n.errorConsent;
    });
    if (_errors.values.any((e) => e != null)) return;
    final quotes = context.read<QuoteRepository>();
    final router = GoRouter.of(context);
    final city = _city.text.trim();
    final phone = _needsPhone
        ? AuthValidators.digits(_phone.text)
        : widget.account.phone!;
    await context.read<SubmitCubit>().submit(() async {
      final estimate = await quotes.request(
        quoteFor: _for,
        pinCode: _pin.text.trim(),
        city: city,
        billBand: _bill!,
        roof: _roof,
        timeline: _when!,
        phone: _needsPhone ? phone : null,
      );
      unawaited(
        router.pushReplacement(
          AppRoutes.quoteSent,
          extra: QuoteSentArgs(estimate: estimate, city: city, phone: phone),
        ),
      );
    });
  }

  String? _error(String key) => _errors[key];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SubmitCubit>().state;
    final phone = widget.account.phone;
    return SolaScreen(
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home, close: true),
        title: l10n.quoteBandTitle,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space8),
          SolaTitleBlock(
            title: l10n.quoteHeadline,
            subtitle: l10n.quoteSubtitle,
          ),
          const SizedBox(height: SolaSpace.space18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SolaSpace.space16,
            children: [
              if (state.status == SubmitStatus.failure)
                FailureNotice(state: state),
              SolaSegmented<QuoteFor>(
                key: const ValueKey('quote_for'),
                label: l10n.quoteFor2,
                selected: _for,
                onChanged: (v) => setState(() => _for = v),
                choices: [
                  SolaChoice(QuoteFor.home, l10n.quoteForHome),
                  SolaChoice(QuoteFor.business, l10n.quoteForBusiness),
                  SolaChoice(QuoteFor.farm, l10n.quoteForFarm),
                ],
              ),
              SolaGroup(
                children: [
                  SolaFieldRow(
                    key: const ValueKey('quote_pin'),
                    label: l10n.fieldPinCode,
                    controller: _pin,
                    error: _error('pin'),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.postalCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  SolaFieldRow(
                    key: const ValueKey('quote_city'),
                    label: l10n.fieldCity,
                    controller: _city,
                    error: _error('city'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.addressCity],
                  ),
                  if (_needsPhone)
                    SolaFieldRow(
                      key: const ValueKey('quote_phone'),
                      label: l10n.mobileForQuote,
                      prefixText: '+91 ',
                      placeholder: l10n.phonePlaceholder,
                      controller: _phone,
                      error: _error('phone'),
                      keyboardType: TextInputType.phone,
                      autofillHints: const [
                        AutofillHints.telephoneNumberNational,
                      ],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                ],
              ),
              ChipGroup<BillBand>(
                key: const ValueKey('quote_bill'),
                label: l10n.monthlyBill,
                selected: _bill,
                error: _error('bill'),
                onChanged: (v) => setState(() => _bill = v),
                choices: [
                  SolaChoice(BillBand.under1500, l10n.billUnder1500b),
                  SolaChoice(BillBand.from1500To3000, l10n.bill1500To3000b),
                  SolaChoice(BillBand.from3000To6000, l10n.bill3000To6000b),
                  SolaChoice(BillBand.over6000, l10n.billOver6000b),
                ],
              ),
              ChipGroup<RoofType>(
                key: const ValueKey('quote_roof'),
                label: l10n.roof,
                selected: _roof,
                onChanged: (v) => setState(() => _roof = v),
                choices: [
                  SolaChoice(RoofType.rcc, l10n.roofRcc2),
                  SolaChoice(RoofType.tinShed, l10n.roofTin),
                  SolaChoice(RoofType.other, l10n.roofOther),
                ],
              ),
              // Not in the designs, but the contract needs it to route the
              // lead.
              ChipGroup<QuoteTimeline>(
                key: const ValueKey('quote_when'),
                label: l10n.when,
                selected: _when,
                error: _error('when'),
                onChanged: (v) => setState(() => _when = v),
                choices: [
                  SolaChoice(QuoteTimeline.thisMonth, l10n.whenThisMonth),
                  SolaChoice(QuoteTimeline.in1To3Months, l10n.when1To3),
                  SolaChoice(QuoteTimeline.exploring, l10n.whenExploring),
                ],
              ),
              SolaGroup(
                children: [
                  SolaToggleRow(
                    key: const Key('quote_consent'),
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v),
                    title: phone == null
                        ? l10n.quoteConsent2
                        : l10n.quoteConsent(_spaced(phone)),
                  ),
                ],
              ),
              if (_error('consent') case final error?)
                SolaText(
                  error,
                  style: SolaTextStyle.meta,
                  color: SolaColors.danger,
                ),
            ],
          ),
        ],
      ),
      bottom: SolaBottomBar(
        children: [
          SolaButton(
            key: const Key('quote_submit'),
            label: l10n.getMyQuote,
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  /// "9876511223" → "98765 11223", as Indians write mobile numbers.
  static String _spaced(String phone) => phone.length == 10
      ? '${phone.substring(0, 5)} ${phone.substring(5)}'
      : phone;
}
