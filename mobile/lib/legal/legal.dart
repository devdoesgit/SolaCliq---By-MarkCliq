import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:solacliq/app/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// The version of the Terms of Use and Privacy Policy this build of the
/// app shows when someone signs up or registers a company (F16). Keep it
/// equal to the backend's `TERMS_VERSION` (`backend/src/terms.rs`). An
/// older app sending an older version is fine: the server records it and
/// asks again after login.
const termsVersion = 1;

/// SolaCliq's legal documents, public pages on the website, built from
/// `legal/*.md`.
enum LegalPage {
  terms('terms'),
  privacy('privacy'),
  companyTerms('company-terms');

  new(this.path);

  /// The page's path on the website.
  final String path;

  Uri url(AppConfig config) => Uri.parse('${config.websiteUrl}/$path');
}

/// Opens [page] in the phone's browser.
void openLegalPage(BuildContext context, LegalPage page) {
  final url = page.url(context.read<AppConfig>());
  unawaited(launchUrl(url, mode: LaunchMode.externalApplication));
}
