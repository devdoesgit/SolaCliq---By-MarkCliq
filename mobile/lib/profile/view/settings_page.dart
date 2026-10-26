import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/app/widgets/back_to.dart';
import 'package:solacliq/app/widgets/load_view.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/profile/data/profile_repository.dart';

/// The app's version, set at build time (`--dart-define=APP_VERSION=`).
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0');

/// Notifications and language, the same on every phone the person uses.
/// Each change saves straight away.
class SettingsPage extends StatefulWidget {
  const new({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<AppSettings> _loaded = _repo.settings();
  AppSettings? _settings;

  ProfileRepository get _repo => context.read<ProfileRepository>();

  Future<void> _save(AppSettings next) async {
    final before = _settings;
    setState(() => _settings = next);
    try {
      await _repo.saveSettings(next);
    } on AuthFailure {
      // Put it back, so the screen never shows a setting that isn't saved.
      if (mounted) setState(() => _settings = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SolaScreen(
      navBar: SolaNavBar(
        leading: const BackTo(fallback: AppRoutes.home),
        title: l10n.settings,
      ),
      body: LoadView(
        future: _loaded,
        failedTitle: l10n.settingsLoadFailed,
        onRetry: () => setState(() => _loaded = _repo.settings()),
        builder: (context, loaded) {
          final s = _settings ??= loaded;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: SolaSpace.space14,
            children: [
              SolaSectionLabel(l10n.notifications),
              SolaGroup(
                children: [
                  SolaToggleRow(
                    key: const Key('settings_push'),
                    title: l10n.pushNotifications,
                    subtitle: l10n.pushNotificationsSub,
                    value: s.push,
                    onChanged: (v) => unawaited(_save(s.copyWith(push: v))),
                  ),
                  SolaToggleRow(
                    key: const Key('settings_whatsapp'),
                    title: l10n.whatsappUpdates,
                    subtitle: l10n.whatsappUpdatesSub,
                    value: s.whatsapp,
                    onChanged: (v) => unawaited(_save(s.copyWith(whatsapp: v))),
                  ),
                  SolaToggleRow(
                    key: const Key('settings_sound'),
                    title: l10n.soundSetting,
                    subtitle: l10n.soundSettingSub,
                    value: s.sound,
                    onChanged: (v) => unawaited(_save(s.copyWith(sound: v))),
                  ),
                ],
              ),
              SolaSectionLabel(l10n.languageLabel),
              SolaSegmented<AppLanguage>(
                key: const ValueKey('settings_language'),
                label: l10n.languageLabel,
                selected: s.language,
                onChanged: (v) => unawaited(_save(s.copyWith(language: v))),
                choices: [
                  SolaChoice(AppLanguage.en, l10n.languageEnglish),
                  SolaChoice(AppLanguage.hi, l10n.languageHindi),
                  SolaChoice(AppLanguage.pa, l10n.languagePunjabi),
                ],
              ),
              if (s.language != AppLanguage.en)
                SolaText(
                  l10n.languageSoon,
                  style: SolaTextStyle.small,
                  color: SolaColors.muted,
                ),
              const SizedBox(height: SolaSpace.space10),
              SolaText(
                l10n.appVersion(appVersion),
                style: SolaTextStyle.meta,
                color: SolaColors.muted,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
