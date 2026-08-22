/// A controllable [NotificationsRepository] fake for widget tests — no
/// network, same shape as
/// `test/features/saved_listings/support/fake_saved_listings_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/features/work_misc/data/notifications_repository.dart';
import 'package:lacasa_mobile/features/work_misc/data/work_notification.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    List<WorkNotification>? notifications,
    this.error,
    this.hold,
  }) : notifications = notifications ?? const [];

  final List<WorkNotification> notifications;
  final Object? error;

  /// When set, [fetchNotifications] awaits this before returning.
  final Completer<void>? hold;

  int fetchCallCount = 0;
  int markAllReadCallCount = 0;

  @override
  Future<List<WorkNotification>> fetchNotifications() async {
    fetchCallCount++;
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
    return notifications;
  }

  @override
  Future<void> markAllRead() async {
    markAllReadCallCount++;
  }
}
