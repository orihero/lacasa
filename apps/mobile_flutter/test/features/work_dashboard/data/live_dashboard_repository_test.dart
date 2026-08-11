// LiveDashboardRepository: a thin adapter over LaCasaApi, whose one piece of
// behaviour beyond forwarding is the StatisticsFilter.all -> .thisMonth
// remap on fetchAdsSeries — see that method's own doc comment for why. This
// was found by exercising the real GET /statistics/ads/series endpoint
// against a running apps/api: filterType is optional and the server
// silently defaults to "today" when it's omitted, which is exactly what
// StatisticsFilter.all.wireOrNull (null) used to send unremapped, making
// dashboard's "All" pick show real all-time stat tiles next to a chart
// quietly showing only today. fetchAdsStatistics has no such remap — that
// endpoint genuinely has a real all-time mode, confirmed against the same
// running server.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_dashboard/data/live_dashboard_repository.dart';

import '../../../api/support/fake_transport.dart';

void main() {
  late FakeTransport transport;

  ApiClient buildClient() => ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage('tok'),
    baseUrl: 'https://api.example.com',
  );

  Map<String, dynamic> emptySeries() => {
    'granularity': 'day',
    'from': {'seconds': 0},
    'to': {'seconds': 0},
    'buckets': <Map<String, dynamic>>[],
  };

  test(
    'fetchAdsSeries(.all) sends filterType=thisMonth, not an omitted filterType',
    () async {
      transport = FakeTransport((req) async => emptySeries());
      final repository = LiveDashboardRepository(LaCasaApi(buildClient()));

      await repository.fetchAdsSeries(StatisticsFilter.all);

      expect(transport.requests.single.query!['filterType'], 'thisMonth');
    },
  );

  test(
    'fetchAdsSeries(.today/.thisWeek/.thisMonth) pass the filter through unchanged',
    () async {
      for (final filter in [
        StatisticsFilter.today,
        StatisticsFilter.thisWeek,
        StatisticsFilter.thisMonth,
      ]) {
        transport = FakeTransport((req) async => emptySeries());
        final repository = LiveDashboardRepository(LaCasaApi(buildClient()));

        await repository.fetchAdsSeries(filter);

        expect(
          transport.requests.single.query!['filterType'],
          filter.wireOrNull,
        );
      }
    },
  );

  test(
    'fetchAdsStatistics(.all) sends an omitted filterType — a real all-time mode, unlike the series endpoint',
    () async {
      transport = FakeTransport(
        (req) async => {'adsNewCount': 0, 'adsSoldCount': 0},
      );
      final repository = LiveDashboardRepository(LaCasaApi(buildClient()));

      await repository.fetchAdsStatistics(StatisticsFilter.all);

      expect(transport.requests.single.query!['filterType'], isNull);
    },
  );
}
