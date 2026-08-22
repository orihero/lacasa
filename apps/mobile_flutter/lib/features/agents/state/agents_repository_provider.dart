/// Picks [FixtureAgentsRepository] or [LiveAgentsRepository] once, per
/// `agents_mode.dart`'s compile-time switch — same shape as
/// `features/home/state/home_feed_repository_provider.dart` and
/// `features/search/state/search_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/agents_repository.dart';
import '../data/live_agents_repository.dart';

final agentsRepositoryProvider = Provider<AgentsRepository>((ref) {
  return LiveAgentsRepository(LaCasaApi.create());
});
