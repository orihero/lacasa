/// Picks [FixtureHomeFeedRepository] or [LiveHomeFeedRepository] once, per
/// `home_feed_mode.dart`'s compile-time switch. Every other Home-feed
/// provider reads through this one instead of constructing a repository
/// itself.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/fixture_home_feed_repository.dart';
import '../data/home_feed_mode.dart';
import '../data/home_feed_repository.dart';
import '../data/live_home_feed_repository.dart';

final homeFeedRepositoryProvider = Provider<HomeFeedRepository>((ref) {
  if (useLiveHomeFeedApi) {
    return LiveHomeFeedRepository(LaCasaApi.create());
  }
  return const FixtureHomeFeedRepository();
});
