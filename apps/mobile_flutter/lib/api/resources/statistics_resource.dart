/// `/api/statistics` — behind `dashboard` (§24). [series]/[coworkersSummary]
/// are this run's additions — see `models/statistics.dart` for the shapes
/// they return and why [ads]/[coworkers] alone used to be the whole gap
/// list here.
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
  Future<AdsStatistics> ads({
    StatisticsFilter filterType = StatisticsFilter.all,
  }) async {
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

  /// `GET /statistics/ads/series?filterType=|from=&to=` — the bucketed
  /// sibling of [ads], for a chart rather than a single pair of totals.
  /// [from]/[to], when **both** given, win over [filterType] and are sent
  /// as full ISO-8601 timestamps (the server parses them with JS's `new
  /// Date(...)`, which accepts either a bare date or a full timestamp).
  /// With neither a resolvable [filterType] nor a [from]/[to] pair, the
  /// server defaults to `today` — unlike [ads]'s all-time default, an
  /// unbounded bucketed series has no sane bound on response size, so this
  /// endpoint refuses to have one. Throws [ApiErrorException] with `code:
  /// validation` (400) if the resolved range would need more than 744
  /// buckets (about a month of hourly buckets, or two years of daily ones)
  /// — the message names the exact limit so a caller can narrow the range
  /// and retry; this client does not pre-check bucket count itself.
  Future<AdsSeries> series({
    StatisticsFilter filterType = StatisticsFilter.all,
    DateTime? from,
    DateTime? to,
  }) async {
    final json = await _client.request(
      method: 'GET',
      path: '/statistics/ads/series',
      query: {
        'filterType': filterType.wireOrNull,
        'from': from?.toIso8601String(),
        'to': to?.toIso8601String(),
      },
    );
    return AdsSeries.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /statistics/coworkers/summary` — the server-side fold of
  /// [coworkers]'s raw event feed into one [CoworkerSummary] row per
  /// coworker (ads created/sold, leads created, last-active timestamp).
  /// Unlike [coworkers], this always covers every coworker's whole history;
  /// there is no `filterType`/date-range param on this endpoint either.
  Future<List<CoworkerSummary>> coworkersSummary() async {
    final json = await _client.request(
      method: 'GET',
      path: '/statistics/coworkers/summary',
    );
    return (json as List<dynamic>)
        .map((e) => CoworkerSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
