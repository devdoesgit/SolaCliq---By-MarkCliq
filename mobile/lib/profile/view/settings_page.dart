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
import 'package:solacliq/push/push_controller.dart';

/// Notification settings, the same on every phone the person uses. The
/// app is English only, so there's no language choice.
/// Each change saves straight away.
class SettingsPage extends StatefulWidget {
  const new({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<AppSettings> _loaded = _repo.settings();
  AppSettings? _settings;

  /// Android blocks the app's notifications (F12): checked on opening and
  /// on coming back from Android settings.
  bool _blocked = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAllowed());
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(_checkAllowed()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _checkAllowed() async {
    final push = context.read<PushController?>();
    if (push == null) return;
    final allowed = await push.allowed();
    if (mounted) setState(() => _blocked = !allowed);
  }

  ProfileRepository get _repo => context.read<ProfileRepository>();

  Future<void> _save(AppSettings next) async {
    final before = _settings;
    setState(() {
      _settings = next;
    });
    try {
      await _repo.saveSettings(next);
    } on AuthFailure {
      // Put it back, so the screen never shows a setting that isn't saved.
      if (mounted) {
        setState(() {
          _settings = before;
        });
      }
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
        onRetry: () => setState(() {
          _loaded = _repo.settings();
        }),
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
              if (_blocked && s.push)
                SolaNotice(
                  key: const Key('settings_push_blocked'),
                  title: l10n.pushBlockedTitle,
                  body: l10n.pushBlockedBody,
                  tone: SolaTone.warning,
                  action: SolaButton(
                    key: const Key('settings_open_android'),
                    label: l10n.pushOpenSettings,
                    variant: SolaButtonVariant.white,
                    compact: true,
                    expand: false,
                    onPressed: () => unawaited(
                      context.read<PushController?>()?.openSettings(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
