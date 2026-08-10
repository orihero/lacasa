/// Chooses which [NotificationsRepository] `notifications` runs on:
/// bundled fixtures (default, and the only ruling contract §7.11 actually
/// makes) or [LiveNotificationsRepository]'s best-effort synthesis — same
/// idiom as `features/agents/data/agents_mode.dart`.
///
/// **To point this screen at the real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_NOTIFICATIONS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

const bool useLiveNotificationsApi = bool.fromEnvironment(
  'LACASA_NOTIFICATIONS_LIVE_API',
);
