/// `GET /api/my/ads/stage-counts` response. Field names on the wire are the
/// numeric `AD_STAGE` keys spelled out as English words (`stage1`/`stage2`/
/// `stage3`), which do NOT line up with [AdStage]'s own "1"/"2"/"3" wire
/// strings at a glance — `stage1` is ACTIVE, `stage2` is SOLD, `stage3` is
/// DRAFT, same order [AdStage.fromWire] uses. Named fields after their
/// meaning, not their wire key, so a call site never has to remember which
/// number means what.
library;

class AdStageCounts {
  final int active;
  final int sold;
  final int draft;

  const AdStageCounts({
    required this.active,
    required this.sold,
    required this.draft,
  });

  int get total => active + sold + draft;

  factory AdStageCounts.fromJson(Map<String, dynamic> json) {
    return AdStageCounts(
      active: (json['stage1'] as num?)?.toInt() ?? 0,
      sold: (json['stage2'] as num?)?.toInt() ?? 0,
      draft: (json['stage3'] as num?)?.toInt() ?? 0,
    );
  }
}
