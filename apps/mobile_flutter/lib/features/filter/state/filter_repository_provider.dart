/// Picks [FixtureFilterRepository] or [LiveFilterRepository] once, per
/// `filter_mode.dart`'s compile-time switch. `FilterSheet` and its count
/// notifier read through this one instead of constructing a repository
/// themselves.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/filter_mode.dart';
import '../data/filter_repository.dart';
import '../data/fixture_filter_repository.dart';
import '../data/live_filter_repository.dart';

final filterRepositoryProvider = Provider<FilterRepository>((ref) {
  if (useLiveFilterApi) {
    return LiveFilterRepository(LaCasaApi.create());
  }
  return const FixtureFilterRepository();
});
