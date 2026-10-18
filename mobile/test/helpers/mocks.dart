import 'package:api_client/api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/health/data/health_repository.dart';

class MockSystemApi extends Mock implements SystemApi;

class MockHealthRepository extends Mock implements HealthRepository;

class MockAuthRepository extends Mock implements AuthRepository;
