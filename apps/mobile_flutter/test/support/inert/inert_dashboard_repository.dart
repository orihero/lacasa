/// A do-nothing [DashboardRepository] for tests that mount the Work tab
/// without being *about* it.
///
/// **Why this exists.** `dashboardRepositoryProvider` now unconditionally
/// builds `LiveDashboardRepository` around `LaCasaApi.create()` — the old
/// `FixtureDashboardRepository` and the `FLUTTER_TEST` guard in
/// `lib/api/app_mode.dart` that used to swap it in are both gone. Any test
/// that builds the real router therefore mounts the shell, the shell reads
/// the dashboard providers, and six live HTTP calls leave the test process.
/// That does not fail cleanly, it *hangs*: the test dies on
/// `pumpAndSettle timed out` with nothing in the failure pointing at the
/// network as the cause. Overriding the provider with this class is what
/// stops that.
///
/// **Everything here is deliberately inert**, and inert in the strongest
/// sense the return types allow: empty lists of ads, leads, coworkers and
/// activity events; zeroed ad totals; an empty, epoch-dated [AdsSeries] with
/// an [SeriesGranularity.unknown] granularity. Nothing throws, so a widget
/// that renders an error state never sees one, and no method returns a
/// number or a row that a test could accidentally end up asserting against.
///
/// **A test that wants real dashboard behaviour must not reach for this.**
/// Override `dashboardRepositoryProvider` with a purpose-built fake from
/// `test/features/<feature>/support/` instead — one that returns the exact
/// stats, series buckets and coworker rows that test is making claims about.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_dashboard/data/dashboard_repository.dart';

/// See this library's doc comment. No fields, hence `const` — construct it as
/// `const InertDashboardRepository()` at every override site.
class InertDashboardRepository implements DashboardRepository {
  const InertDashboardRepository();

  @override
  Future<AdsStatistics> fetchAdsStatistics(StatisticsFilter filter) async =>
      const AdsStatistics(adsNewCount: 0, adsSoldCount: 0);

  /// [AdsSeries] has no empty value of its own: `from`/`to` are non-nullable
  /// [DateTime]s, so the neutral answer is the epoch for both, an empty
  /// bucket list, and the granularity the wire parser itself falls back to
  /// when the server sends something it does not recognise. `DateTime` is not
  /// a constant expression, so — unlike every other method here — this one
  /// cannot return a `const` instance.
  @override
  Future<AdsSeries> fetchAdsSeries(StatisticsFilter filter) async => AdsSeries(
    granularity: SeriesGranularity.unknown,
    from: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    to: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    buckets: const <AdsSeriesBucket>[],
  );

  @override
  Future<List<ActivityEvent>> fetchCoworkerActivity() async =>
      const <ActivityEvent>[];

  @override
  Future<List<Ad>> fetchAllAds() async => const <Ad>[];

  @override
  Future<List<Lead>> fetchAllLeads() async => const <Lead>[];

  @override
  Future<List<Coworker>> fetchCoworkers() async => const <Coworker>[];
}
