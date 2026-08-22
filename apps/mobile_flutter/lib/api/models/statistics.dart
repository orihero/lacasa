/// `GET /api/statistics/ads`, `GET /api/statistics/ads/series`,
/// `GET /api/statistics/coworkers`, and `GET /api/statistics/coworkers/summary`
/// response shapes.
///
/// [AdsStatistics]/[ActivityEvent] predate the bucketed/summary endpoints
/// below and were built when this file's own doc comment said "there is no
/// server-side bucketed time series endpoint" — that gap is closed now:
/// [AdsSeries] is exactly that endpoint's response, zero-filled per-bucket
/// so a chart never has to guess "zero" from "not fetched." Similarly
/// [CoworkerSummary] is the server-side fold of [ActivityEvent] rows a
/// screen previously had to do itself client-side over the raw
/// `GET /statistics/coworkers` feed.
library;

import 'enums.dart';
import 'wire_timestamp.dart';

/// `GET /statistics/ads?filterType=`. A pair of totals for the *whole*
/// selected range — no per-day breakdown, no delta vs. a previous period
/// (the API has no previous-period figure to compare against, so don't
/// invent one — see `apps/console`'s own choice to omit it).
class AdsStatistics {
  final int adsNewCount;
  final int adsSoldCount;

  const AdsStatistics({required this.adsNewCount, required this.adsSoldCount});

  factory AdsStatistics.fromJson(Map<String, dynamic> json) {
    return AdsStatistics(
      adsNewCount: (json['adsNewCount'] as num?)?.toInt() ?? 0,
      adsSoldCount: (json['adsSoldCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One row of `GET /statistics/coworkers`'s raw event list
/// (`CoworkerStatisticEvent`). This endpoint **ignores its own
/// `filterType` query param entirely** — always returns the agent's full,
/// unfiltered event history — and does no server-side grouping: a caller
/// wanting "ads/leads/sales per coworker" (SCREENS.md §24's Coworker
/// statistics section) must fold this list itself, keyed on [coworkerId].
class ActivityEvent {
  final String id;
  final String agentId;

  /// Empty string (not `null`) when the event has no coworker attached —
  /// same convention as `Ad.coworkerId`/`Lead.coworkerId`.
  final String coworkerId;
  final String adId;
  final String leadId;
  final ActivityEventStage stage;
  final DateTime createdAt;

  const ActivityEvent({
    required this.id,
    required this.agentId,
    required this.coworkerId,
    required this.adId,
    required this.leadId,
    required this.stage,
    required this.createdAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json) {
    return ActivityEvent(
      id: json['id'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      coworkerId: json['coworkerId'] as String? ?? '',
      adId: json['adId'] as String? ?? '',
      leadId: json['leadId'] as String? ?? '',
      stage: ActivityEventStage.fromWire((json['stage'] as num?)?.toInt()),
      createdAt: json['createdAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['createdAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// `GET /statistics/ads/series`'s `granularity` — server-chosen, never
/// caller-supplied: hourly when the resolved `from`/`to` range spans ≤24h,
/// daily otherwise (`granularityFor` in
/// `apps/api/src/services/statisticsService.js`).
enum SeriesGranularity {
  hour,
  day,
  unknown;

  static SeriesGranularity fromWire(String? value) => switch (value) {
    'hour' => SeriesGranularity.hour,
    'day' => SeriesGranularity.day,
    _ => SeriesGranularity.unknown,
  };
}

/// One entry of `GET /statistics/ads/series`'s `buckets[]`.
class AdsSeriesBucket {
  final DateTime bucketStart;
  final int adCreatedCount;
  final int adSoldCount;

  const AdsSeriesBucket({
    required this.bucketStart,
    required this.adCreatedCount,
    required this.adSoldCount,
  });

  factory AdsSeriesBucket.fromJson(Map<String, dynamic> json) {
    return AdsSeriesBucket(
      bucketStart: json['bucketStart'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(
              json['bucketStart'] as Map<String, dynamic>,
            )
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      adCreatedCount: (json['adCreatedCount'] as num?)?.toInt() ?? 0,
      adSoldCount: (json['adSoldCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `GET /statistics/ads/series?filterType=|from=&to=` — the bucketed
/// sibling of [AdsStatistics]. `buckets` is zero-filled: every bucket
/// between [from] and [to] appears whether or not any event landed in it.
/// `400 validation` server-side (surfaced as [ApiErrorException]) if the
/// resolved range would need more than 744 buckets — see
/// `StatisticsResource.series`'s doc comment.
class AdsSeries {
  final SeriesGranularity granularity;
  final DateTime from;
  final DateTime to;
  final List<AdsSeriesBucket> buckets;

  const AdsSeries({
    required this.granularity,
    required this.from,
    required this.to,
    required this.buckets,
  });

  factory AdsSeries.fromJson(Map<String, dynamic> json) {
    return AdsSeries(
      granularity: SeriesGranularity.fromWire(json['granularity'] as String?),
      from: json['from'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['from'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      to: json['to'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['to'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      buckets:
          (json['buckets'] as List<dynamic>?)
              ?.map((e) => AdsSeriesBucket.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// One row of `GET /statistics/coworkers/summary` — per-coworker totals
/// folded server-side from the same [ActivityEvent] rows `coworkers()`
/// exposes raw. Always one row per coworker of the calling agent, including
/// one with zero activity (every count at `0`, never omitted — an idle
/// coworker is a real fact worth showing, not hiding).
class CoworkerSummary {
  final String coworkerId;
  final int adsCreatedCount;
  final int adsSoldCount;
  final int leadsCreatedCount;

  /// `null` — never a fabricated timestamp — for a coworker who has never
  /// triggered a tracked event. When non-null, it's a max over *every*
  /// activity-event type this coworker has ever logged, not just the three
  /// counted fields above.
  final DateTime? lastActiveAt;

  const CoworkerSummary({
    required this.coworkerId,
    required this.adsCreatedCount,
    required this.adsSoldCount,
    required this.leadsCreatedCount,
    required this.lastActiveAt,
  });

  factory CoworkerSummary.fromJson(Map<String, dynamic> json) {
    final rawLastActive = json['lastActiveAt'];
    return CoworkerSummary(
      coworkerId: json['coworkerId'] as String? ?? '',
      adsCreatedCount: (json['adsCreatedCount'] as num?)?.toInt() ?? 0,
      adsSoldCount: (json['adsSoldCount'] as num?)?.toInt() ?? 0,
      leadsCreatedCount: (json['leadsCreatedCount'] as num?)?.toInt() ?? 0,
      lastActiveAt: rawLastActive is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(rawLastActive)
          : null,
    );
  }
}
