/// `/api/statistics` — behind `dashboard` (§24). See `models/statistics.dart`
/// for why neither endpoint here returns a bucketed time series.
library;

import '../api_client.dart';
import '../models/statistics.dart';

/// `GET /statistics/ads`'s `filterType` query param. [all] is a client-only
/// sentinel meaning "send no `filterType` at all" — the server's own
/// fallback for a missing/unrecognized value is already "no date filter",
/// so this just makes that explicit rather than sending the literal string
/// `"all"` (which the server would also treat as unrecognized-and-thus-no-
/// filter, but sending nothing is the honest expression of what [all]
/// means).
enum StatisticsFilter {
  all,
  today,
  thisWeek,
  thisMonth;

  String? get wireOrNull => switch (this) {
    StatisticsFilter.all => null,
    StatisticsFilter.today => 'today',
    StatisticsFilter.thisWeek => 'thisWeek',
    StatisticsFilter.thisMonth => 'thisMonth',
  };
}

class StatisticsResource {
  final ApiClient _client;

  const StatisticsResource(this._client);

  /// `GET /statistics/ads?filterType=`. [filterType] genuinely narrows the
  /// range server-side (`today`/`thisWeek`/`thisMonth`) — this is the one
  /// statistics endpoint where the selector actually does something (see
  /// [coworkers] below).
  Future<AdsStatistics> ads({StatisticsFilter filterType = StatisticsFilter.all}) async {
    final json = await _client.request(
      method: 'GET',
      path: '/statistics/ads',
      query: {'filterType': filterType.wireOrNull},
    );
    return AdsStatistics.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /statistics/coworkers`. **Ignores any date-range concept
  /// entirely** — always returns every [ActivityEvent] ever recorded for
  /// the caller's agent, unfiltered. There is no `filterType` param to pass
  /// here; a caller that wants "this week's coworker activity" must filter
  /// [ActivityEvent.createdAt] client-side over the full list this returns.
  Future<List<ActivityEvent>> coworkers() async {
    final json = await _client.request(
      method: 'GET',
      path: '/statistics/coworkers',
    );
    return (json as List<dynamic>)
        .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
