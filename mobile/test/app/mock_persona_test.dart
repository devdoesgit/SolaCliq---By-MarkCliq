import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solacliq/app/dev/mock_persona.dart';
import 'package:solacliq/home/data/home_repository.dart';

void main() {
  late MockPersonaInterceptor mock;

  setUp(() => mock = MockPersonaInterceptor(MockPersona.worker));
  tearDown(() => mock.dispose());

  String? prefer(String path, [Map<String, Object?> extra = const {}]) {
    final options = RequestOptions(path: path, extra: extra);
    mock.onRequest(options, RequestInterceptorHandler());
    return options.headers['Prefer'] as String?;
  }

  test('picks the named example for the person and the moment', () {
    expect(prefer('/me'), 'example=worker');
    expect(prefer('/me/invites'), 'example=none');
    mock.inviteWaiting.value = true;
    expect(prefer('/me/invites'), 'example=one');
    expect(prefer('/quote-requests'), isNull);
  });

  test('company homes by role, live energy once handed over', () {
    const extra = {HomeRepository.mockExampleKey: 'customer'};
    expect(prefer('/orgs/o1/home', extra), 'example=customer');
    mock.handedOver.value = true;
    expect(prefer('/orgs/o1/home', extra), 'example=customer_live');
    expect(
      prefer('/orgs/o1/home', {HomeRepository.mockExampleKey: 'worker'}),
      'example=worker',
    );
  });
}
