/// Picks [FixtureSavedListingsRepository] or [LiveSavedListingsRepository]
/// once, per `saved_listings_mode.dart`'s compile-time switch — same shape
/// as `features/agents/state/agents_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/live_saved_listings_repository.dart';
import '../data/saved_listings_repository.dart';

final savedListingsRepositoryProvider = Provider<SavedListingsRepository>((
  ref,
) {
  return LiveSavedListingsRepository(LaCasaApi.create());
});
