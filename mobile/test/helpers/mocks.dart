import 'package:api_client/api_client.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:solacliq/auth/auth.dart';
import 'package:solacliq/customers/data/customer_repository.dart';
import 'package:solacliq/customers/data/registration_repository.dart';
import 'package:solacliq/expenses/data/expense_repository.dart';
import 'package:solacliq/health/data/health_repository.dart';
import 'package:solacliq/home/data/home_repository.dart';
import 'package:solacliq/install/data/install_repository.dart';
import 'package:solacliq/invites/data/invite_repository.dart';
import 'package:solacliq/notifications/data/notification_repository.dart';
import 'package:solacliq/profile/data/profile_repository.dart';
import 'package:solacliq/tasks/data/task_repository.dart';
import 'package:solacliq/uploads/data/upload_repository.dart';
import 'package:solacliq/workspace/cubit/workspace_cubit.dart';

class MockSystemApi extends Mock implements SystemApi;

class MockHealthRepository extends Mock implements HealthRepository;

class MockAuthRepository extends Mock implements AuthRepository;

class MockWorkspaceCubit extends MockCubit<WorkspaceState>
    implements WorkspaceCubit;

class MockHomeRepository extends Mock implements HomeRepository;

class MockInviteRepository extends Mock implements InviteRepository;

class MockExpenseRepository extends Mock implements ExpenseRepository;

class MockUploadRepository extends Mock implements UploadRepository;

class MockRegistrationRepository extends Mock implements RegistrationRepository;

class MockTaskRepository extends Mock implements TaskRepository;

class MockNotificationRepository extends Mock implements NotificationRepository;

class MockCustomerRepository extends Mock implements CustomerRepository;

class MockProfileRepository extends Mock implements ProfileRepository;

class MockInstallRepository extends Mock implements InstallRepository;
