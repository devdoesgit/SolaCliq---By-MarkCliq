import 'package:solacliq/app/app.dart';
import 'package:solacliq/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => App(config: AppConfig.development()));
}
