/// Chooses which [ContactRepository] the sheet runs on: the real
/// [LaCasaApi] (default) or bundled fixtures. Resolves through
/// `lib/api/app_mode.dart` — the single source of truth every
/// `*_mode.dart` switch's default now defers to. This one deserved a
/// warning the others didn't, back when fixtures were the default:
///
/// **The fixture repository accepts every submission and sends nothing.**
/// For a read-only feed, "fixtures by default" means the screen renders
/// offline; for a form whose entire purpose is delivering a message to a
/// human, it used to mean a user could be shown "Message sent
/// successfully." for a message that reached nobody — which is why this
/// switch, unlike the others at the time, had to be turned on by hand in
/// any build a real person used. The inversion in `app_mode.dart` fixes
/// that: this form is now live by default like everything else, and it is
/// fixtures — not live — that requires an explicit opt-in
/// (`LACASA_CONTACT_LIVE_API=false`, or the global
/// `LACASA_USE_FIXTURES=true`). `flutter test` still always gets
/// fixtures, so no widget test can silently send a real message.
///
/// **To force the contact form to fixtures** (accepts and discards,
/// useful for local development or a demo):
/// ```
/// flutter run --dart-define=LACASA_CONTACT_LIVE_API=false
/// ```
///
/// **To point the contact form at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
///
/// Note that even live, the server answers 503 `contact_unconfigured`
/// unless it has `TG_CONTACT_CHAT_ID` set — the sheet surfaces that
/// distinctly rather than as a generic failure, since no amount of
/// retrying fixes it.
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveContactApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_CONTACT_LIVE_API', defaultValue: ''),
);
