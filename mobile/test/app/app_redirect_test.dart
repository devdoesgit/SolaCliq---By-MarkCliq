import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/app/app.dart';
import 'package:solacliq/app/router.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';
import 'package:solacliq/workspace/data/workspace.dart';

import '../helpers/helpers.dart';

void main() {
  const dev = AppConfig(flavor: AppFlavor.development, apiBaseUrl: '');
  final prod = AppConfig.production();
  final account = testAccount();
  final ready = WorkspaceReady(account, const PersonalWorkspace(), const [
    PersonalWorkspace(),
  ]);
  const inApp = [
    AppRoutes.home,
    AppRoutes.quote,
    AppRoutes.expense,
    AppRoutes.addCustomer,
  ];
  final everywhere = [
    ...AppRoutes.public,
    AppRoutes.splash,
    AppRoutes.useWebsite,
    ...inApp,
  ];

  /// Where each location is sent, as a map, for one state.
  Map<String, String?> sends(WorkspaceState state) => {
    for (final path in everywhere) path: appRedirect(state, path, dev),
  };

  group('appRedirect', () {
    test('while loading, everything waits on the splash', () {
      expect(sends(const WorkspaceLoading()), {
        for (final p in everywhere) p: p == AppRoutes.splash ? null : '/',
      });
    });

    test('signed out: public pages stay, others go to welcome', () {
      final result = sends(const WorkspaceSignedOut());
      for (final path in AppRoutes.public) {
        expect(result[path], isNull, reason: path);
      }
      expect(result[AppRoutes.home], AppRoutes.welcome);
      expect(result[AppRoutes.expense], AppRoutes.welcome);
      expect(result[AppRoutes.splash], AppRoutes.welcome);
    });

    test('ready: entry screens lead home, in-app screens stay', () {
      final result = sends(ready);
      for (final path in [
        ...AppRoutes.public,
        AppRoutes.splash,
        AppRoutes.useWebsite,
      ]) {
        expect(result[path], AppRoutes.home, reason: path);
      }
      for (final path in inApp) {
        expect(result[path], isNull, reason: path);
      }
    });

    test('org admin only: only the website notice', () {
      final result = sends(WorkspaceAdminOnly(account));
      expect(result[AppRoutes.useWebsite], isNull);
      expect(result[AppRoutes.home], AppRoutes.useWebsite);
    });

    test('the gallery is open in development only', () {
      expect(appRedirect(ready, AppRoutes.gallery, dev), isNull);
      expect(appRedirect(ready, AppRoutes.gallery, prod), AppRoutes.home);
    });
  });
}
