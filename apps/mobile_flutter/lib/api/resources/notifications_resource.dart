/// `/api/notifications` — behind `notifications` (SCREENS.md §22). See
/// `models/notification.dart` for the wire shape and
/// `apps/api/src/services/notificationService.js`'s header comment for why
/// this is a derived, unpersisted feed with no server-side read state.
library;

import '../api_client.dart';
import '../models/notification.dart';

class NotificationsResource {
  final ApiClient _client;

  const NotificationsResource(this._client);

  /// `GET /notifications?since=&limit=` — agent/coworker only, `403
  /// forbidden` for any other role. [since] drives every row's
  /// [AppNotification.unread]: omit it and every row comes back unread (see
  /// `models/notification.dart`'s doc comment), or pass the wall-clock time
  /// the caller last looked at this screen. [limit] defaults to 50
  /// server-side, capped at 200. Throws [ApiErrorException] with `code:
  /// validation` (400) for an unparseable [since] or a non-positive
  /// [limit] — this client does not pre-validate either.
  Future<List<AppNotification>> fetch({DateTime? since, int? limit}) async {
    final json = await _client.request(
      method: 'GET',
      path: '/notifications',
      query: {'since': since?.toIso8601String(), 'limit': limit},
    );
    return (json as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
