/// An inert stand-in for [NotificationsRepository].
///
/// Every repository provider in this app now builds a live implementation
/// around `LaCasaApi.create()` — the bundled fixture repositories, and the
/// `FLUTTER_TEST` guard in `lib/api/app_mode.dart` that used to force them,
/// are gone. Widget tests that mount the real router get a shell that reads
/// nearly every repository incidentally, so any provider left un-overridden
/// fires real HTTP out of the test process. That does not fail cleanly, it
/// hangs, and the test dies on `pumpAndSettle timed out` with nothing
/// pointing at the cause. This class is what those tests override
/// `notificationsRepositoryProvider` with so that never happens.
///
/// It is deliberately inert, not a miniature fixture: the notification list
/// is always empty and "mark all read" is a no-op that succeeds. That is the
/// point — an inert repository can never be the thing a test is accidentally
/// asserting against, and a screen that renders its empty state under it is
/// telling you the test never wired up real data.
///
/// A test that *wants* notification behaviour — rows, unread counts, a
/// watermark that moves — must not reach for this. Override the provider
/// with the purpose-built fake from
/// `test/features/work_misc/support/fake_notifications_repository.dart`
/// instead.
library;

import 'package:lacasa_mobile/features/work_misc/data/notifications_repository.dart';
import 'package:lacasa_mobile/features/work_misc/data/work_notification.dart';

/// No notifications, and marking them all read is a no-op that succeeds.
class InertNotificationsRepository implements NotificationsRepository {
  const InertNotificationsRepository();

  @override
  Future<List<WorkNotification>> fetchNotifications() async =>
      const <WorkNotification>[];

  @override
  Future<void> markAllRead() async {}
}
