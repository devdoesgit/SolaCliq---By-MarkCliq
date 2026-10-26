import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:solacliq/home/data/home_repository.dart';

/// The kinds of person the Prism mock can return from `/me` and log in,
/// named after the examples in `api/openapi.yaml`. Development flavor only.
enum MockPersona {
  personal('personal'),
  customer('customer'),
  worker('worker'),
  agent('agent'),
  sales('sales'),
  multiOrg('multi_org'),
  orgAdmin('org_admin');

  new(this.example);

  /// The example's name in the contract.
  final String example;

  /// From `--dart-define=MOCK_PERSONA=<example>`; null when unset or
  /// unknown.
  static MockPersona? fromDefine() {
    const value = String.fromEnvironment('MOCK_PERSONA');
    for (final persona in values) {
      if (persona.example == value) return persona;
    }
    return null;
  }
}

/// Picks the Prism mock's named examples with its `Prefer: example=`
/// header, so one mock can play every person and moment in the designs. A
/// real backend ignores the header. Development flavor only.
class MockPersonaInterceptor extends Interceptor {
  new([MockPersona? initial]) : persona = ValueNotifier(initial);

  /// The person the mock plays; null for the contract's default.
  final ValueNotifier<MockPersona?> persona;

  /// Whether the mock has an invite waiting (the prototype's "simulate an
  /// invite").
  final ValueNotifier<bool> inviteWaiting = ValueNotifier(false);

  /// Whether the mock customer's system is handed over, so their home
  /// shows live energy.
  final ValueNotifier<bool> handedOver = ValueNotifier(false);

  static final _orgHome = RegExp(r'^/orgs/[^/]+/home$');
  static final _tasks = RegExp(r'^/orgs/[^/]+/tasks$');
  static final _task = RegExp(
    r'^/orgs/[^/]+/tasks/([^/]+)(/photos|/checklist/[^/]+|/submit|/problems)?$',
  );
  static final _expense = RegExp(r'^/orgs/[^/]+/expenses/([^/]+)(/receipt)?$');

  /// Sample task ids in the contract, by the example that plays them.
  /// Other ids play an assigned task.
  static const _taskExamples = {
    '01928f6e-0000-7000-8000-000000000a02': 'returned',
    '01928f6e-0000-7000-8000-000000000a04': 'submitted',
    '01928f6e-0000-7000-8000-000000000a05': 'approved',
    '01928f6e-0000-7000-8000-000000000a07': 'cancelled',
    '01928f6e-0000-7000-8000-000000000a09': 'approved',
  };
  static final _accept = RegExp(r'^/invites/[^/]+/accept$');
  static final _notifications = RegExp(r'^/orgs/[^/]+/notifications$');
  static final _customers = RegExp(r'^/orgs/[^/]+/my-customers$');
  static final _customer = RegExp(
    r'^/orgs/[^/]+/my-customers/([^/]+)(/documents/[^/]+)?$',
  );
  static final _documents = RegExp(r'^/orgs/[^/]+/me/documents$');
  static final _install = RegExp(r'^/orgs/[^/]+/my-install(/payments/.+)?$');

  /// Sample customer ids in the contract, by the example that plays them.
  static const _customerExamples = {
    '01928f6e-0000-7000-8000-0000000000c1': 'needs_fix',
    '01928f6e-0000-7000-8000-0000000000c2': 'in_review',
    '01928f6e-0000-7000-8000-0000000000c3': 'approved',
    '01928f6e-0000-7000-8000-0000000000c4': 'payable',
    '01928f6e-0000-7000-8000-0000000000c5': 'paid',
    '01928f6e-0000-7000-8000-0000000000c6': 'sales_needs_fix',
    '01928f6e-0000-7000-8000-0000000000c7': 'sales_in_review',
    '01928f6e-0000-7000-8000-0000000000c8': 'sales_installing',
  };

  bool get _sales => persona.value == MockPersona.sales;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final example = _exampleFor(options);
    if (example != null) options.headers['Prefer'] = 'example=$example';
    handler.next(options);
  }

  String? _exampleFor(RequestOptions options) {
    final path = options.path;
    if (path == '/me' || path == '/auth/login') return persona.value?.example;
    if (path == '/me/invites') return inviteWaiting.value ? 'one' : 'none';
    if (_accept.hasMatch(path)) return 'worker';
    if (_tasks.hasMatch(path)) {
      return options.queryParameters['view'] as String?;
    }
    if (_task.firstMatch(path) case final m?) {
      return switch (m.group(2)) {
        '/submit' => 'submitted',
        '/problems' => 'reported',
        // The mock keeps no state: a photo or tick returns the task as it
        // was, and the app keeps its own progress on top.
        _ => _taskExamples[m.group(1)] ?? 'assigned',
      };
    }
    if (_expense.firstMatch(path) case final m?) {
      return m.group(2) != null ||
              m.group(1) != '01928f6e-0000-7000-8000-0000000000f3'
          ? 'in_review'
          : 'needs_fix';
    }
    if (_orgHome.hasMatch(path)) {
      final role = options.extra[HomeRepository.mockExampleKey] as String?;
      return switch (role) {
        'customer' when handedOver.value => 'customer_live',
        'agent' when _sales => 'sales',
        _ => role,
      };
    }
    if (path == '/me/notifications') return 'personal';
    if (_notifications.hasMatch(path)) {
      return switch (persona.value) {
        MockPersona.customer => 'customer',
        MockPersona.agent || MockPersona.multiOrg => 'agent',
        MockPersona.sales => 'sales',
        _ => 'worker',
      };
    }
    if (_customers.hasMatch(path)) return _sales ? 'sales' : 'agent';
    if (_customer.firstMatch(path) case final m?) {
      return m.group(2) != null
          ? 'in_review'
          : _customerExamples[m.group(1)] ?? 'approved';
    }
    if (_documents.hasMatch(path)) {
      return persona.value == MockPersona.customer ? 'customer' : 'worker';
    }
    if (_install.firstMatch(path) case final m?) {
      if (m.group(1) != null) return 'claimed';
      return handedOver.value ? 'live' : 'before';
    }
    return null;
  }

  void dispose() {
    persona.dispose();
    inviteWaiting.dispose();
    handedOver.dispose();
  }
}
