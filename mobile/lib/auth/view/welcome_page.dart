import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/app/routes.dart';
import 'package:solacliq/l10n/l10n.dart';

/// The first screen: the install photo with two sample status pills, the
/// headline, and the two ways in: get started (the intro, then log in) or
/// request SolaCliq for a solar company.
class WelcomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SolaColors.cream,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: const _Content(),
                  ),
                ),
              ),
            ),
            SolaBottomBar(
              children: [
                SolaButton(
                  key: const Key('welcome_get_started'),
                  label: l10n.getStarted,
                  onPressed: () => unawaited(context.push(AppRoutes.intro)),
                ),
                SolaButton(
                  key: const Key('welcome_request_access'),
                  label: l10n.runEpc,
                  variant: SolaButtonVariant.link,
                  icon: SolaIcons.building,
                  onPressed: () =>
                      unawaited(context.push(AppRoutes.requestAccess)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new();

  /// How far the photo reaches, and where the text starts over its fade.
  static const _photoHeight = 480.0;
  static const _textTop = 446.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _photoHeight,
          child: Semantics(
            image: true,
            label: l10n.welcomePhotoLabel,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.22, 0.55, 1],
                  colors: [
                    SolaColors.photoShade,
                    SolaColors.photoShadeClear,
                    SolaColors.creamClear,
                    SolaColors.cream,
                  ],
                ),
              ),
              child: Image(
                image: SolaPhotos.heroInstall.provider,
                fit: BoxFit.cover,
                alignment: const Alignment(0.16, -0.4),
              ),
            ),
          ),
        ),
        Positioned(
          left: SolaSpace.space20,
          top: top + SolaSpace.space12,
          child: ExcludeSemantics(
            child: Row(
              spacing: SolaSpace.space6,
              children: [
                SolaPill(
                  l10n.welcomeLive,
                  tone: SolaTone.live,
                  icon: SolaIcons.bolt,
                ),
                SolaPill(l10n.welcomeStage, tone: SolaTone.light),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SolaSpace.space20,
            _textTop,
            SolaSpace.space20,
            SolaSpace.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: SolaSpace.space12,
            children: [
              SolaEyebrow(l10n.welcomeEyebrow),
              SolaText(l10n.welcomeHeadline, style: SolaTextStyle.display),
              SolaText(l10n.welcomeBody, color: SolaColors.muted),
              Row(
                spacing: SolaSpace.space10,
                children: [
                  const SolaAvatarStack(
                    ring: SolaColors.cream,
                    overlap: 4,
                    avatars: [
                      SolaAvatar(initials: 'HS', size: 30),
                      SolaAvatar(
                        initials: 'PN',
                        size: 30,
                        color: SolaColors.skyAvatar,
                      ),
                      SolaAvatar(
                        initials: 'RA',
                        size: 30,
                        color: SolaColors.brown,
                        foreground: SolaColors.cream,
                      ),
                      SolaAvatar(
                        initials: 'MJ',
                        size: 30,
                        color: SolaColors.butter,
                      ),
                    ],
                  ),
                  Flexible(
                    child: SolaText(
                      l10n.welcomeFor,
                      style: SolaTextStyle.small,
                      color: SolaColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
