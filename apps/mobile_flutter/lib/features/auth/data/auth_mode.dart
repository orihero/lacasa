/// Chooses which [AuthRepository] the app runs on: the real [LaCasaApi]
/// (default) or bundled fixtures. Resolves through
/// `lib/api/app_mode.dart` — the single source of truth every
/// `*_mode.dart` switch's default now defers to — rather than
/// hand-rolling its own `false`.
///
/// Unlike most of this app's fixtures, going live here changes more than
/// what one screen renders: it is what makes a session (and therefore the
/// role-aware tab bar, and everything behind the Work tab) real instead of
/// simulated. That is exactly why fixtures being the default used to be
/// the safer choice while auth was unverified against a real backend, and
/// exactly why it no longer is now that it's finished: a plain `flutter
/// run` should sign a real person into a real session, not a simulated
/// one. `FixtureAuthRepository`'s own doc comment covers what fixtures
/// still get you for free when explicitly chosen — a persisted session
/// that survives a relaunch, without a server.
///
/// **To force auth to fixtures** (e.g. offline development, or a demo):
/// ```
/// flutter run --dart-define=LACASA_AUTH_LIVE_API=false
/// ```
///
/// **To point auth at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveAuthApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_AUTH_LIVE_API', defaultValue: ''),
);
