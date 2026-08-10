/// `GET /api/statistics/ads` and `GET /api/statistics/coworkers` response
/// shapes. Both are aggregates, not bucketed time series — see the API
/// contract survey's explicit answer #2. There is no server-side "12-point
/// daily Created/Sold series" endpoint; a screen that wants one (SCREENS.md
/// §24/§4.6) either buckets [ActivityEvent] rows itself client-side, or —
/// what the seed fixtures do — uses the static §4.6 series directly, since
/// the fixture repository never hits a real endpoint anyway. This file
/// intentionally has no "DashboardChartPoint"-style model: that shape has
/// no wire contract to mirror, so it belongs to whichever feature renders
/// it (`work_dashboard`), not to `lib/api/`.
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
