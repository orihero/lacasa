/// Chooses which [ContactRepository] the sheet runs on. Same compile-time
/// switch shape as every other feature here (`home_feed_mode.dart` has the
/// full reasoning), but this one deserves a warning the others don't:
///
/// **The fixture repository accepts every submission and sends nothing.**
/// For a read-only feed, "fixtures by default" means the screen renders
/// offline; for a form whose entire purpose is delivering a message to a
/// human, it means a user can be shown "Message sent successfully." for a
/// message that reached nobody. That is the correct default for local
/// development and for the widget tests — and it is exactly why this
/// switch, unlike the others, must be turned on in any build a real person
/// will use.
///
/// ```
/// flutter run \
///   --dart-define=LACASA_CONTACT_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
///
/// Note that even with this on, the server answers 503
/// `contact_unconfigured` unless it has `TG_CONTACT_CHAT_ID` set — the
/// sheet surfaces that distinctly rather than as a generic failure, since
/// no amount of retrying fixes it.
const bool useLiveContactApi = bool.fromEnvironment('LACASA_CONTACT_LIVE_API');
