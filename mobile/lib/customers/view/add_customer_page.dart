import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/dev/quick_forms.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/auth/view/auth_text.dart';
import 'package:solacliq/customers/cubit/add_customer_cubit.dart';
import 'package:solacliq/customers/data/india.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/customers/view/add_customer_sent_page.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/uploads/view/pick_photo.dart';
import 'package:solacliq/workspace/data/workspace.dart';

/// An agent registers a customer in three steps (who, site, KYC), checks
/// it, and sends it for the admin to approve.
class AddCustomerPage extends StatelessWidget {
  const new({required this.workspace, super.key});

  final MemberWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddCustomerCubit(
        context.read<UploadRepository>(),
        context.read<RegistrationRepository>(),
        orgId: workspace.orgId,
      ),
      child: AddCustomerFlow(workspace: workspace),
    );
  }
}

enum _Step { details, site, docs, review }

class AddCustomerFlow extends StatefulWidget {
  const new({required this.workspace, super.key});

  final MemberWorkspace workspace;

  @override
  State<AddCustomerFlow> createState() => _AddCustomerFlowState();
}

class _AddCustomerFlowState extends State<AddCustomerFlow> {
  _Step _step = _Step.details;

  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _cityPin = TextEditingController();
  final _discomText = TextEditingController();
  final _consumer = TextEditingController();
  final _sanctioned = TextEditingController();
  final _proposed = TextEditingController();
  final _commission = TextEditingController();
  final _commissionNote = TextEditingController();
  String? _state;
  String? _discom;
  ConnectionType _connection = ConnectionType.residential;
  Roof? _roof;
  bool _subsidy = true;
  bool _consent = false;
  final _errors = <String, String?>{};

  late final List<TextEditingController> _controllers = [
    _name,
    _mobile,
    _email,
    _address,
    _cityPin,
    _discomText,
    _consumer,
    _sanctioned,
    _proposed,
    _commission,
    _commissionNote,
  ];

  static final _cityPinPattern = RegExp(r'^(.+?)[\s,]+([1-9]\d{5})$');

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _clear(String key) {
    if (_errors[key] != null) setState(() => _errors[key] = null);
  }

  List<String>? get _discoms => discomsByState[_state];

  String get _provider =>
      _discoms == null ? _discomText.text.trim() : _discom ?? '';

  /// "9814022671" as Indians write it: "+91 98140 22671".
  static String _spacedMobile(String text) {
    final d = AuthValidators.digits(text);
    return d.length == 10 ? '+91 ${d.substring(0, 5)} ${d.substring(5)}' : d;
  }

  static num? _kw(String text) {
    final value = num.tryParse(text.replaceAll(RegExp('[^0-9.]'), ''));
    return value == null || value <= 0 ? null : value;
  }

  /// Quick forms (development): fills this step's blanks with samples.
  void _fillStep() {
    switch (_step) {
      case _Step.details:
        context
          ..fillBlank(_name, 'Rajinder Example')
          ..fillBlank(_mobile, '98140 22671')
          ..fillBlank(_email, 'rajinder@example.com')
          ..fillBlank(_address, 'H.No 214, Phase 7')
          ..fillBlank(_cityPin, 'Mohali 160062');
        if (_state == null) {
          _state = 'Punjab';
          _discom = discomsByState['Punjab']!.first;
        }
      case _Step.site:
        final discoms = _discoms;
        if (discoms == null) {
          context.fillBlank(_discomText, 'PSPCL');
        } else {
          _discom ??= discoms.first;
        }
        context
          ..fillBlank(_consumer, '3002 1457 8890')
          ..fillBlank(_sanctioned, '5')
          ..fillBlank(_proposed, '5');
        _roof ??= Roof.rcc;
      case _Step.docs:
        _consent = true;
      case _Step.review:
        break;
    }
  }

  bool _validate() {
    if (context.quickForms) _fillStep();
    final l10n = context.l10n;
    setState(() {
      _errors.clear();
      switch (_step) {
        case _Step.details:
          _errors
            ..['name'] = AuthValidators.required(
              _name.text,
              l10n.fieldFullName,
              l10n,
            )
            ..['mobile'] = AuthValidators.mobile(_mobile.text, l10n)
            ..['email'] = AuthValidators.email(_email.text.trim(), l10n)
            ..['address'] = AuthValidators.required(
              _address.text,
              l10n.fieldHouse,
              l10n,
            )
            ..['cityPin'] = _cityPinPattern.hasMatch(_cityPin.text.trim())
                ? null
                : l10n.errorCityPin
            ..['state'] = _state == null ? l10n.errorChoose : null;
        case _Step.site:
          _errors
            ..['discom'] = _provider.isEmpty ? l10n.errorChoose : null
            ..['consumer'] = AuthValidators.required(
              _consumer.text,
              l10n.fieldConsumerNo,
              l10n,
            )
            ..['sanctioned'] = _kw(_sanctioned.text) == null
                ? l10n.errorKw
                : null
            ..['proposed'] = _kw(_proposed.text) == null ? l10n.errorKw : null
            ..['roof'] = _roof == null ? l10n.errorChoose : null;
        case _Step.docs:
          _errors['consent'] = _consent ? null : l10n.errorCustomerConsent;
        case _Step.review:
          break;
      }
    });
    return _errors.values.every((e) => e == null);
  }

  void _next() {
    if (!_validate()) return;
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  void _back() {
    if (_step == _Step.details) {
      _leave();
    } else {
      setState(() => _step = _Step.values[_step.index - 1]);
    }
  }

  void _leave() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  /// The documents that go with the customer: the uploaded ones, plus with
  /// quick forms (development) a sample for each required one not picked.
  Map<KycKind, String> _documents(Map<KycKind, String> uploaded) => {
    ...uploaded,
    if (context.quickForms)
      for (final kind in AddCustomerState.required(subsidy: _subsidy))
        if (!uploaded.containsKey(kind)) kind: QuickForms.sampleUploadId,
  };

  CustomerDraft _draft(Map<KycKind, String> uploaded) {
    final documents = _documents(uploaded);
    final cityPin = _cityPinPattern.firstMatch(_cityPin.text.trim())!;
    return CustomerDraft(
      name: _name.text.trim(),
      phone: AuthValidators.digits(_mobile.text),
      email: _email.text.trim(),
      address: _address.text.trim(),
      city: cityPin.group(1)!,
      pinCode: cityPin.group(2)!,
      state: _state!,
      discom: _provider,
      consumerNumber: AuthValidators.digits(_consumer.text),
      sanctionedLoadKw: _kw(_sanctioned.text)!,
      connectionType: _connection,
      proposedKw: _kw(_proposed.text)!,
      roof: _roof!,
      subsidy: _subsidy,
      documents: documents,
      consent: _consent,
      commissionPaise: widget.workspace.earnsCommission
          ? _commissionPaise
          : null,
      commissionNote: _commissionNote.text.trim().isEmpty
          ? null
          : _commissionNote.text.trim(),
    );
  }

  /// The commission typed in rupees, as paise.
  int? get _commissionPaise {
    final rupees = int.tryParse(_commission.text.replaceAll(RegExp(r'\D'), ''));
    return rupees == null || rupees <= 0 ? null : rupees * 100;
  }

  Future<void> _pick(
    String title,
    List<String> options,
    String? selected,
    ValueChanged<String> onPicked,
  ) async {
    final picked = await showSolaSheet<String>(
      context: context,
      title: title,
      doneLabel: context.l10n.cancel,
      builder: (sheet) => SolaGroup(
        children: [
          for (final option in options)
            SolaListRow(
              key: ValueKey('option_$option'),
              title: option,
              trailing: option == selected
                  ? const SolaIcon(SolaIcons.check)
                  : null,
              onTap: () => Navigator.of(sheet).pop(option),
            ),
        ],
      ),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  String _roofLabel(AppLocalizations l10n, Roof roof) => switch (roof) {
    Roof.rcc => l10n.roofRccFull,
    Roof.tinShed => l10n.roofTinShed,
    Roof.other => l10n.roofOther2,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<AddCustomerCubit>().state;
    final (title, subtitle) = switch (_step) {
      _Step.details => (l10n.whoIsCustomer, l10n.asOnAadhaar),
      _Step.site => (l10n.siteTitle, l10n.siteSubtitle),
      _Step.docs => (l10n.kycTitle, l10n.kycSubtitle),
      _Step.review => (
        l10n.checkSubmit,
        l10n.checkSubmitBody(_name.text.trim().split(' ').first),
      ),
    };
    return BlocListener<AddCustomerCubit, AddCustomerState>(
      listenWhen: (a, b) => a.reference == null && b.reference != null,
      listener: (context, state) => context.pushReplacement(
        AppRoutes.addCustomerSent,
        extra: AddCustomerSentArgs(
          firstName: _name.text.trim().split(' ').first,
          documents: _documents(state.uploaded).length,
          reference: state.reference!,
          commissionPaise: widget.workspace.earnsCommission
              ? _commissionPaise
              : null,
        ),
      ),
      child: PopScope(
        canPop: _step == _Step.details,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: SolaScreen(
          background: SolaBackground.stone,
          navBar: SolaNavBar(
            leading: SolaCircleButton(
              key: const Key('nav_back'),
              icon: SolaIcons.back,
              semanticsLabel: l10n.back,
              onPressed: _back,
            ),
            title: _step == _Step.review ? l10n.reviewLabel : l10n.newCustomer,
            subtitle: _step == _Step.review
                ? null
                : l10n.stepOf('${_step.index + 1}', '3'),
            trailing: SolaTextLink(
              l10n.cancel,
              key: const Key('add_customer_cancel'),
              onPressed: _leave,
            ),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step != _Step.review)
                Padding(
                  padding: const EdgeInsets.only(top: SolaSpace.space6),
                  child: SolaSegmentBar(
                    height: 4,
                    segments: [
                      for (var i = 0; i < 3; i++)
                        SolaSegment(
                          1,
                          i <= _step.index ? SolaColors.sun : SolaColors.track,
                        ),
                    ],
                  ),
                ),
              SizedBox(
                height: _step == _Step.review
                    ? SolaSpace.space8
                    : SolaSpace.space18,
              ),
              SolaTitleBlock(title: title, subtitle: subtitle),
              SizedBox(
                height: _step == _Step.review
                    ? SolaSpace.space16
                    : SolaSpace.space20,
              ),
              switch (_step) {
                _Step.details => _details(l10n),
                _Step.site => _site(l10n),
                _Step.docs => _docs(l10n, state),
                _Step.review => _review(l10n, state),
              },
            ],
          ),
          bottom: SolaBottomBar(children: _actions(l10n, state)),
        ),
      ),
    );
  }

  List<Widget> _actions(AppLocalizations l10n, AddCustomerState state) {
    switch (_step) {
      case _Step.details || _Step.site:
        return [
          SolaButton(
            key: const Key('add_customer_next'),
            label: l10n.next,
            onPressed: _next,
          ),
        ];
      case _Step.docs:
        final total = AddCustomerState.required(subsidy: _subsidy).length;
        // Quick forms (development) let the step pass without photos.
        final missing = context.quickForms
            ? 0
            : state.missing(subsidy: _subsidy);
        return [
          SolaText(
            missing == 0
                ? l10n.docsAll('$total')
                : l10n.docsCount('${total - missing}', '$total'),
            style: SolaTextStyle.meta,
            color: SolaColors.muted,
            textAlign: TextAlign.center,
          ),
          SolaButton(
            key: const Key('add_customer_review'),
            label: missing == 0 ? l10n.reviewLabel : l10n.addMore('$missing'),
            variant: SolaButtonVariant.dark,
            onPressed: missing == 0 ? _next : null,
          ),
        ];
      case _Step.review:
        return [
          if (state.failure case final failure?)
            SolaNotice(
              key: const Key('failure_notice'),
              title: failure.message(l10n),
              announce: true,
            ),
          SolaButton(
            key: const Key('add_customer_submit'),
            label: l10n.submitToAdmin,
            onPressed: state.submitting ? null : _submit,
          ),
        ];
    }
  }

  Widget _details(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaGroup(
          children: [
            SolaFieldRow(
              key: const ValueKey('customer_name'),
              label: l10n.fieldFullName,
              controller: _name,
              error: _errors['name'],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clear('name'),
            ),
            SolaFieldRow(
              key: const ValueKey('customer_mobile'),
              label: l10n.fieldMobile2,
              prefixText: '+91 ',
              controller: _mobile,
              error: _errors['mobile'],
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                LengthLimitingTextInputFormatter(11),
              ],
              onChanged: (_) => _clear('mobile'),
            ),
            SolaFieldRow(
              key: const ValueKey('customer_email'),
              label: l10n.emailLoginNote,
              controller: _email,
              error: _errors['email'],
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clear('email'),
            ),
          ],
        ),
        SolaGroup(
          children: [
            SolaFieldRow(
              key: const ValueKey('customer_address'),
              label: l10n.fieldHouse,
              controller: _address,
              error: _errors['address'],
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clear('address'),
            ),
            SolaFieldRow(
              key: const ValueKey('customer_city_pin'),
              label: l10n.fieldCityPin,
              controller: _cityPin,
              error: _errors['cityPin'],
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _clear('cityPin'),
            ),
            SolaValueRow(
              key: const Key('customer_state'),
              label: l10n.fieldState,
              value: _state ?? l10n.chooseState,
              error: _errors['state'],
              onTap: () => unawaited(
                _pick(l10n.fieldState, indianStates, _state, (v) {
                  if (v != _state) {
                    final options = discomsByState[v];
                    // One provider in the state: nothing to choose.
                    _discom = options?.length == 1 ? options!.first : null;
                  }
                  _state = v;
                  _errors['state'] = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _site(AppLocalizations l10n) {
    final discoms = _discoms;
    final discom = _discom;
    final kwFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      LengthLimitingTextInputFormatter(6),
    ];
    final kwSuffix = SolaText(l10n.kwSuffix, color: SolaColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaGroup(
          children: [
            if (discoms == null)
              SolaFieldRow(
                key: const ValueKey('customer_discom'),
                label: l10n.fieldDiscom,
                placeholder: l10n.discomOther,
                controller: _discomText,
                error: _errors['discom'],
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => _clear('discom'),
              )
            else
              SolaValueRow(
                key: const Key('customer_discom'),
                label: l10n.fieldDiscom,
                value: discom == null
                    ? l10n.chooseDiscom
                    : l10n.discomInState(discom, _state!),
                error: _errors['discom'],
                onTap: () => unawaited(
                  _pick(l10n.fieldDiscom, discoms, discom, (v) {
                    _discom = v;
                    _errors['discom'] = null;
                  }),
                ),
              ),
            SolaFieldRow(
              key: const ValueKey('customer_consumer'),
              label: l10n.fieldConsumerNo,
              controller: _consumer,
              error: _errors['consumer'],
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clear('consumer'),
            ),
            SolaFieldRow(
              key: const ValueKey('customer_sanctioned'),
              label: l10n.fieldSanctioned,
              controller: _sanctioned,
              error: _errors['sanctioned'],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: kwFormatters,
              trailing: kwSuffix,
              onChanged: (_) => _clear('sanctioned'),
            ),
          ],
        ),
        SolaSegmented<ConnectionType>(
          key: const ValueKey('customer_connection'),
          label: l10n.connectionType,
          selected: _connection,
          onChanged: (v) => setState(() => _connection = v),
          choices: [
            SolaChoice(ConnectionType.residential, l10n.connResidential),
            SolaChoice(ConnectionType.commercial, l10n.connCommercial),
            SolaChoice(ConnectionType.industrial, l10n.connIndustrial),
          ],
        ),
        SolaGroup(
          children: [
            SolaFieldRow(
              key: const ValueKey('customer_proposed'),
              label: l10n.fieldProposed,
              controller: _proposed,
              error: _errors['proposed'],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: kwFormatters,
              trailing: kwSuffix,
              onChanged: (_) => _clear('proposed'),
            ),
            SolaValueRow(
              key: const Key('customer_roof'),
              label: l10n.fieldRoof,
              value: _roof == null ? l10n.chooseRoof : _roofLabel(l10n, _roof!),
              error: _errors['roof'],
              onTap: () => unawaited(_pickRoof(l10n)),
            ),
            SolaToggleRow(
              key: const Key('customer_subsidy'),
              title: l10n.subsidyToggle,
              subtitle: l10n.subsidyToggleSub,
              titleStyle: SolaTextStyle.rowTitle,
              value: _subsidy,
              onChanged: (v) => setState(() => _subsidy = v),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickRoof(AppLocalizations l10n) async {
    final labels = {for (final r in Roof.values) _roofLabel(l10n, r): r};
    await _pick(
      l10n.fieldRoof,
      labels.keys.toList(),
      _roof == null ? null : _roofLabel(l10n, _roof!),
      (v) {
        _roof = labels[v];
        _errors['roof'] = null;
      },
    );
  }

  Future<void> _addDocument(KycKind kind, String title) async {
    final cubit = context.read<AddCustomerCubit>();
    final file = await pickDocumentPhoto(context, title);
    if (file != null) await cubit.addDocument(kind, file);
  }

  Widget _docs(AppLocalizations l10n, AddCustomerState state) {
    final docs = [
      (KycKind.aadhaar, l10n.docAadhaar, l10n.docAadhaarSub, SolaGlyph.card),
      (KycKind.pan, l10n.docPan, l10n.docPanSub, SolaGlyph.card),
      (KycKind.electricityBill, l10n.docBill, l10n.docBillSub, SolaGlyph.bill),
      if (_subsidy)
        (KycKind.bankProof, l10n.docBank, l10n.docBankSub, SolaGlyph.passbook),
      (KycKind.roofPhoto, l10n.docRoof, l10n.docRoofSub, null),
    ];
    final company = widget.workspace.orgName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space14,
      children: [
        SolaGroup(
          children: [
            for (final (kind, title, detail, glyph) in docs)
              _DocRow(
                key: ValueKey('doc_${kind.name}'),
                title: title,
                detail: switch (state.docs[kind]) {
                  DocFailed(tooLarge: true) => l10n.fileTooBig,
                  DocFailed() => l10n.uploadFailed,
                  _ => detail,
                },
                failed: state.docs[kind] is DocFailed,
                glyph: glyph,
                doc: state.docs[kind],
                onAdd: () => unawaited(_addDocument(kind, title)),
              ),
          ],
        ),
        SolaGroup(
          children: [
            SolaToggleRow(
              key: const Key('customer_consent'),
              title: l10n.consentShare(
                _name.text.trim().split(' ').first,
                company,
              ),
              value: _consent,
              onChanged: (v) => setState(() {
                _consent = v;
                _errors['consent'] = null;
              }),
            ),
          ],
        ),
        if (_errors['consent'] case final error?)
          Semantics(
            liveRegion: true,
            child: SolaText(
              error,
              style: SolaTextStyle.meta,
              color: SolaColors.danger,
            ),
          ),
      ],
    );
  }

  Widget _review(AppLocalizations l10n, AddCustomerState state) {
    final documents = _documents(state.uploaded);
    final added = [
      if (documents.containsKey(KycKind.aadhaar)) l10n.docShortAadhaar,
      if (documents.containsKey(KycKind.pan)) l10n.docShortPan,
      if (documents.containsKey(KycKind.electricityBill)) l10n.docShortBill,
      if (_subsidy && documents.containsKey(KycKind.bankProof))
        l10n.docShortBank,
      if (documents.containsKey(KycKind.roofPhoto)) l10n.docShortRoof,
    ];
    Widget section(String label, _Step step, List<Widget> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space8,
      children: [
        SolaSectionLabel(
          label,
          trailing: SolaTextLink(
            l10n.edit,
            key: ValueKey('review_edit_${step.name}'),
            style: SolaTextStyle.small,
            onPressed: () => setState(() => _step = step),
          ),
        ),
        SolaGroup(children: rows),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SolaSpace.space16,
      children: [
        section(l10n.sectionCustomer, _Step.details, [
          SolaKeyValueRow(l10n.kvName, _name.text.trim()),
          SolaKeyValueRow(l10n.kvMobile, _spacedMobile(_mobile.text)),
          SolaKeyValueRow(l10n.kvEmail, _email.text.trim()),
        ]),
        section(l10n.sectionSite, _Step.site, [
          SolaKeyValueRow(
            l10n.kvDiscom,
            l10n.discomValue(_provider, _consumer.text.trim()),
          ),
          SolaKeyValueRow(
            l10n.kvSystem,
            l10n.systemValue(
              '${_kw(_proposed.text)}',
              _roof == Roof.rcc ? l10n.roofRcc2 : _roofLabel(l10n, _roof!),
            ),
          ),
          SolaKeyValueRow(
            l10n.kvSubsidy,
            _subsidy ? l10n.pmSuryaGhar : l10n.subsidyNone,
          ),
        ]),
        section(l10n.sectionDocs, _Step.docs, [
          SolaKeyValueRow(l10n.kvAdded, added.join(', ')),
        ]),
        if (widget.workspace.earnsCommission)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SolaSpace.space8,
            children: [
              SolaSectionLabel(l10n.yourCommission),
              SolaGroup(
                children: [
                  SolaFieldRow(
                    key: const ValueKey('add_customer_commission'),
                    label: l10n.commissionAmountLabel,
                    controller: _commission,
                    prefixText: '₹ ',
                    error: _errors['commission'],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _clear('commission'),
                  ),
                  SolaFieldRow(
                    key: const ValueKey('add_customer_commission_note'),
                    label: l10n.commissionNoteLabel,
                    controller: _commissionNote,
                    placeholder: l10n.commissionNotePlaceholder,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
              SolaText(
                l10n.commissionReviewNote(_name.text.trim().split(' ').first),
                style: SolaTextStyle.small,
                color: SolaColors.muted,
              ),
            ],
          )
        else
          SolaText(
            l10n.salariedNoCommission,
            style: SolaTextStyle.small,
            color: SolaColors.muted,
          ),
      ],
    );
  }

  /// Commission agents enter their commission before submitting.
  void _submit() {
    if (widget.workspace.earnsCommission) {
      context.fillBlank(_commission, '6000');
      if (_commissionPaise == null) {
        setState(() => _errors['commission'] = context.l10n.errorCommission);
        return;
      }
    }
    unawaited(context.read<AddCustomerCubit>().submit(_draft));
  }
}

/// One KYC document: its picture, what it is, and "Add" or "Uploaded".
class _DocRow extends StatelessWidget {
  const new({
    required super.key,
    required this.title,
    required this.detail,
    required this.failed,
    required this.glyph,
    required this.doc,
    required this.onAdd,
  });

  final String title;
  final String detail;
  final bool failed;
  final SolaGlyph? glyph;
  final DocState? doc;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = (key! as ValueKey<String>).value;
    final canAdd = doc is! DocUploading && doc is! DocUploaded;
    return SolaListRow(
      title: title,
      subtitle: detail,
      // The whole row adds the photo, not only its button.
      onTap: canAdd ? onAdd : null,
      leading: SolaThumb(
        glyph: glyph,
        icon: glyph == null ? SolaIcons.home : null,
      ),
      trailing: switch (doc) {
        DocUploaded() => SolaPill(
          l10n.uploaded,
          tone: SolaTone.success,
          icon: SolaIcons.check,
        ),
        DocUploading() => Semantics(
          label: l10n.uploading,
          child: const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: SolaColors.ink,
            ),
          ),
        ),
        _ => SolaButton(
          key: ValueKey('${id}_add'),
          label: failed ? l10n.retry : l10n.add,
          semanticsLabel: '${failed ? l10n.retry : l10n.add}: $title',
          icon: SolaIcons.camera,
          variant: SolaButtonVariant.dark,
          small: true,
          expand: false,
          onPressed: onAdd,
        ),
      },
    );
  }
}
