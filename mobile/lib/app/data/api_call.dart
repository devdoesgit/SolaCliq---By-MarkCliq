import 'package:dio/dio.dart';
import 'package:solacliq/auth/data/auth_failure.dart';

/// Runs an API request, turning a network or server error into an
/// [AuthFailure] that screens show through `SubmitCubit`.
Future<T> apiCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw AuthFailure.fromDio(error);
  }
}

/// Every item of a paged list, following `next_cursor`.
///
/// For screens that need the whole list (a month's expense total, every
/// done task), not a feed. [page] fetches one page from a cursor (null
/// for the first) and returns its items and the next cursor. Stops after
/// [maxPages] pages as a safety net against a server that never ends.
Future<List<T>> allPages<T>(
  Future<(List<T>, String?)> Function(String? cursor) page, {
  int maxPages = 20,
}) async {
  final items = <T>[];
  String? cursor;
  for (var i = 0; i < maxPages; i++) {
    final (batch, next) = await page(cursor);
    items.addAll(batch);
    if (next == null) break;
    cursor = next;
  }
  return items;
}

/// The page size for [allPages]: the API's largest.
const pageSizeMax = 100;
