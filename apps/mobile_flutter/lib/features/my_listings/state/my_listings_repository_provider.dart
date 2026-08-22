/// Picks [FixtureMyListingsRepository] or [LiveMyListingsRepository] once,
/// per `my_listings_mode.dart`'s compile-time switch — same shape as
/// `features/search/state/search_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/live_my_listings_repository.dart';
import '../data/my_listings_repository.dart';

final myListingsRepositoryProvider = Provider<MyListingsRepository>((ref) {
  return LiveMyListingsRepository(LaCasaApi.create());
});
