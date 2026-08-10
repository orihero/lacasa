/// Chooses which [LeadsRepository] the `leads` feature runs on: bundled
/// fixtures (default) or the real [LaCasaApi]. Same reasoning and same
/// off-by-default direction as `features/home/data/home_feed_mode.dart` —
/// this feature must render sensibly with no network at all.
///
/// **To point the leads screens at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_LEADS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveLeadsApi = bool.fromEnvironment('LACASA_LEADS_LIVE_API');
