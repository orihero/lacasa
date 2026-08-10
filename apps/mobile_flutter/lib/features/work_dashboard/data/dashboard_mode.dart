/// Chooses which [DashboardRepository] `dashboard` runs on: bundled
/// fixtures (default) or the real [LaCasaApi]. Same compile-time-switch
/// pattern as every other Work feature (`WORK_TAB_CONTRACT.md` §6) —
/// defaults OFF so this screen renders sensibly with zero network.
///
/// **To point Dashboard at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_WORK_DASHBOARD_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveWorkDashboardApi = bool.fromEnvironment(
  'LACASA_WORK_DASHBOARD_LIVE_API',
);
