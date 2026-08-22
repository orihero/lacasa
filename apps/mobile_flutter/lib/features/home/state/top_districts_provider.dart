/// Home's Top Districts rail, derived — not fetched.
///
/// "Top districts" has no backing entity anywhere: `regions.json` is a flat
/// picker vocabulary with no popularity, ordering or imagery, and there is
/// no `/districts` route to add one to. The only popularity signal that
/// exists in this system is **how many active listings carry a given
/// `Ad.district` string**, so that is what this rail states, literally.
///
/// It derives that from [homeFeedAdsProvider], the list Featured Listings
/// and Explore Nearby already render — no second request, no independent
/// failure mode, and the loading/error/empty states come along for free
/// (same pattern `LiveHomeFeedRepository.fetchTopAgents` uses one tier up,
/// sorting agents by `adsCount`).
///
/// Because it derives, it also **follows the category chip row**: the feed
/// is re-fetched narrowed to the selected [AdType], so this rail ranks
/// districts within the chosen category rather than across the whole
/// catalogue. That is the intended reading — the rail sits under a lit chip
/// that says which category the screen is currently about.
///
/// **The counts are exact, not a sample:** `AdsResource.list()` sends no
/// `limit`/`cursor`, so `adService.listAds` takes its unpaged branch and
/// returns every `ACTIVE` row. **If the Home feed is ever switched to
/// `listPage`, this silently becomes "top districts on page 1"** and must
/// move to a server-side aggregate (`prisma.ad.groupBy`, already the
/// established shape in `adRepository.js`/`statisticsRepository.js`) behind
/// a new endpoint. That trigger, not tidiness, is what should motivate the
/// extra round trip.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/district_tally.dart';
import 'home_feed_providers.dart';

/// How many tiles the rail will show at most. The rail scrolls, so this is
/// a "stop being a leaderboard" bound rather than a layout one — past the
/// first handful the counts flatten out and the ordering stops meaning
/// anything.
const int maxTopDistricts = 8;

/// Districts present in the current feed, most listings first, ties broken
/// alphabetically so the order is stable across rebuilds of an unchanged
/// feed. Blank districts are skipped — `Ad.district` is free text
/// server-side (`packages/domain/src/data/regions.ts` says so explicitly),
/// so an empty string is reachable and is not a district.
final topDistrictsProvider = Provider<AsyncValue<List<DistrictTally>>>((ref) {
  return ref.watch(homeFeedAdsProvider).whenData((ads) {
    final counts = <String, int>{};
    for (final ad in ads) {
      final name = ad.district.trim();
      if (name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }

    final tallies =
        counts.entries
            .map((entry) => DistrictTally(name: entry.key, count: entry.value))
            .toList()
          ..sort((a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.name.compareTo(b.name);
          });

    return tallies.take(maxTopDistricts).toList();
  });
});
