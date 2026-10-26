import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sola_ui/sola_ui.dart';
import 'package:solacliq/account/widgets/log_out_bar.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:solacliq/app/dev/dev_tools.dart';
import 'package:solacliq/l10n/l10n.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';

/// For someone who is only an org admin: their tools are on the website,
/// so the app points there instead of opening a home.
class AdminOnlyPage extends StatefulWidget {
  const new({super.key});

  @override
  State<AdminOnlyPage> createState() => _AdminOnlyPageState();
}

class _AdminOnlyPageState extends State<AdminOnlyPage> {
  bool _copied = false;

  Future<void> _copy(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = context.read<AppConfig>();
    final url = config.websiteUrl;
    final state = context.watch<WorkspaceCubit>().state;
    final orgs = state is WorkspaceAdminOnly ? state.orgNames.join(', ') : '';
    return SolaScreen(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: SolaSpace.space26),
          SolaEyebrow(l10n.appName),
          const SizedBox(height: SolaSpace.space12),
          SolaTitleBlock(
            title: l10n.adminOnlyTitle,
            subtitle: l10n.adminOnlyBody(orgs),
            style: SolaTextStyle.largeTitle,
          ),
          const SizedBox(height: SolaSpace.space24),
          SolaCard(
            padding: const EdgeInsets.all(SolaSpace.space18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SolaSpace.space14,
              children: [
                SelectableText(
                  url,
                  style: SolaTextStyle.sheetTitle.textStyle(),
                ),
                SolaButton(
                  key: const Key('admin_copy_address'),
                  label: _copied ? l10n.addressCopied : l10n.copyAddress,
                  variant: SolaButtonVariant.cream,
                  compact: true,
                  expand: false,
                  onPressed: () => unawaited(_copy(url)),
                ),
              ],
            ),
          ),
          if (config.showDevTools) ...[
            const SizedBox(height: SolaSpace.space14),
            const DevToolsSection(),
          ],
        ],
      ),
      bottom: const LogOutBar(),
    );
  }
}
