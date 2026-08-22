/// Notification rows for `notifications_screen_test.dart`, held here rather
/// than in `lib/` — same reasoning as
/// `test/features/leads/support/lead_fixtures.dart`.
///
/// These five rows were previously `workNotificationsFixture` in
/// `lib/shared/fixtures/work_seed_data.dart`, where they were bundled into
/// the shipped app so a fixture repository could serve them at runtime. That
/// repository and that file are gone; the app has exactly one data source
/// now, the API. The rows themselves are still useful as *test* input, so
/// they moved into the test tree, which is the only place that still has a
/// reason to construct a notification by hand.
///
/// Shape assumptions the screen test leans on, worth preserving if these are
/// ever edited: every [WorkNotification.relativeTime] is distinct (the test
/// asserts `findsOneWidget` per row), at least one row is read and at least
/// one unread (the "Mark all read" affordance only shows when something is
/// unread), and every title but the first is a fused "headline — detail"
/// sentence that `notification_row.dart` splits on the em dash into the
/// mockup's two type roles.
library;

import 'package:lacasa_mobile/features/work_misc/data/work_notification.dart';

final List<WorkNotification> notificationTestRows = [
  const WorkNotification(
    id: 'notif-1',
    kind: WorkNotificationKind.lead,
    title: 'New lead: Dilnoza Yusupova is interested in your Chilonzor listing',
    relativeTime: '2 min ago',
    unread: true,
    targetId: 'lead-2001',
  ),
  const WorkNotification(
    id: 'notif-2',
    kind: WorkNotificationKind.publish,
    title:
        'Instagram post published — Bright 3-room apartment in Chilonzor is '
        'now live on Instagram',
    relativeTime: '1 h ago',
    unread: true,
    targetId: 'ad-1001',
  ),
  const WorkNotification(
    id: 'notif-3',
    kind: WorkNotificationKind.lead,
    title: 'Callback reminder — Call Aziz Karimov today at 15:00',
    relativeTime: '3 h ago',
    unread: true,
    targetId: 'lead-2002',
  ),
  const WorkNotification(
    id: 'notif-4',
    kind: WorkNotificationKind.sold,
    title: 'Listing sold — Two-room flat in Mirobod marked as Sold',
    relativeTime: 'Yesterday',
    unread: false,
    targetId: 'ad-1005',
  ),
  const WorkNotification(
    id: 'notif-5',
    kind: WorkNotificationKind.coworkerActivity,
    title:
        'Coworker added a new listing — Sardor Abdullayev created Retail '
        'space near Chorsu bazaar',
    relativeTime: '2 days ago',
    unread: false,
    targetId: 'coworker-sardor',
  ),
];
