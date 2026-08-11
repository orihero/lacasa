/// Chooses which [HomeFeedRepository] the Home feed screen runs on: the
/// real [LaCasaApi] (default) or bundled fixtures.
///
/// This used to default OFF (fixtures) because the feature was being built
/// and verified screen-by-screen with no backend running. The app is no
/// longer at that stage, so per `lib/api/app_mode.dart` — the single source
/// of truth every `*_mode.dart` switch now resolves its default through —
/// a plain `flutter run`/release build with no `--dart-define`s talks to
/// the real API. Fixtures remain reachable two ways: the global
/// `LACASA_USE_FIXTURES=true` opt-in (all features at once), or this
/// feature's own override below (this feature only). `flutter test` always
/// gets fixtures regardless, so no widget test fires real HTTP by
/// accident — see `app_mode.dart`'s doc comment for the guard.
///
/// **To force the Home feed to fixtures** (e.g. while the backend is down,
/// or for an offline demo):
/// ```
/// flutter run --dart-define=LACASA_HOME_LIVE_API=false
/// ```
///
/// **To point the Home feed at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
/// (that define is `lib/api/env.dart`'s own switch, unrelated to this one
/// — it changes *where* live requests go, not *whether* they're made).
///
/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
library;

import '../../../api/app_mode.dart';

final bool useLiveHomeFeedApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_HOME_LIVE_API', defaultValue: ''),
);
