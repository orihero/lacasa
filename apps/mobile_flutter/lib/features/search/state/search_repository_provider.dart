/// Builds the one shipping [SearchRepository] — [LiveSearchRepository] over
/// [LaCasaApi] — same shape as
/// `features/home/state/home_feed_repository_provider.dart`. This used to
/// pick between a bundled fixture and the live API via a `search_mode.dart`
/// compile-time switch; both are gone, and tests override this provider
/// directly instead.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/live_search_repository.dart';
import '../data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return LiveSearchRepository(LaCasaApi.create());
});
