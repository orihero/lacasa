/// Offline stand-in for [NotificationsRepository] — SCREENS.md §4.4's 5
/// rows, verbatim, no network. What this screen renders from by default
/// (see `notifications_mode.dart`).
library;

import '../../../shared/shared.dart';
import 'notifications_repository.dart';

class FixtureNotificationsRepository implements NotificationsRepository {
  const FixtureNotificationsRepository();

  @override
  Future<List<WorkNotificationFixture>> fetchNotifications() async =>
      workNotificationsFixture;
}
