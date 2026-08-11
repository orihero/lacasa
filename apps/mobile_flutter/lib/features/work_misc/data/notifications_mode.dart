/// Chooses which [NotificationsRepository] `notifications` runs on: the
/// real [LaCasaApi] via [LiveNotificationsRepository]'s real `GET
/// /notifications` call (default) or bundled fixtures — resolved through
/// `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to.
///
/// Contract ruling §7.11 left a live mode explicitly optional — at the
/// time it was written there was no dedicated notifications endpoint, so
/// "no live-mode ruling to make" was the honest position. `GET
/// /notifications` exists now, and [LiveNotificationsRepository] calls it
/// directly rather than synthesizing a feed client-side (see that file's own
/// doc comment for the client-side-synthesis approach it replaced, and why
/// all 4 of SCREENS.md §4.4's notification kinds are covered where the old
/// synthesis could only honestly manage 3), so the same global inversion
/// applies here as everywhere else: no `--dart-define`s means live.
///
/// **To force `notifications` to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_NOTIFICATIONS_LIVE_API=false
/// ```
///
/// **To point `notifications` at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveNotificationsApi = resolveUseLiveApi(
  const String.fromEnvironment(
    'LACASA_NOTIFICATIONS_LIVE_API',
    defaultValue: '',
  ),
);
