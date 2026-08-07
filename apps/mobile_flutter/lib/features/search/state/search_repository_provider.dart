/// Picks [FixtureSearchRepository] or [LiveSearchRepository] once, per
/// `search_mode.dart`'s compile-time switch — same shape as
/// `features/home/state/home_feed_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/fixture_search_repository.dart';
import '../data/live_search_repository.dart';
import '../data/search_mode.dart';
import '../data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  if (useLiveSearchApi) {
    return LiveSearchRepository(LaCasaApi.create());
  }
  return const FixtureSearchRepository();
});
