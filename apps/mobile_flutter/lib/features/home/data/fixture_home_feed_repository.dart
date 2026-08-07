/// Offline stand-in for [HomeFeedRepository], backed by
/// `home_feed_fixtures.dart`'s SCREENS.md §4 seed data. No network, no
/// [LaCasaApi] dependency — this is what the Home feed renders from by
/// default (see `home_feed_mode.dart`), which is how the build spec's "must
/// render sensibly with NO network available" requirement is met.
library;

import '../../../api/api.dart';
import 'home_feed_fixtures.dart';
import 'home_feed_repository.dart';

class FixtureHomeFeedRepository implements HomeFeedRepository {
  const FixtureHomeFeedRepository();

  @override
  Future<List<Ad>> fetchFeed() async => homeFeedFixtureAds;

  @override
  Future<List<AgentSummary>> fetchTopAgents() async {
    final sorted = [...homeFeedFixtureAgents]
      ..sort((a, b) => b.adsCount.compareTo(a.adsCount));
    return sorted.take(5).toList();
  }

  @override
  Future<Set<String>> fetchInitialSavedAdIds() async =>
      homeFeedFixtureSavedAdIds;

  @override
  Future<void> saveAd(String adId) async {}

  @override
  Future<void> unsaveAd(String adId) async {}
}
