import 'package:solacliq/app/app.dart';
import 'package:solacliq/bootstrap.dart';
import 'package:solacliq/push/push_controller.dart';

Future<void> main() async {
  await bootstrap(
    () => App(config: AppConfig.development(), push: FirebasePushMessaging()),
  );
}
