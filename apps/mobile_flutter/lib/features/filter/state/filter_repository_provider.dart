/// Builds the one [FilterRepository] the sheet uses. `FilterSheet` and its
/// count notifier read through this provider instead of constructing a
/// repository themselves — which is also the seam widget tests override to
/// swap in a fake (the bundled-fixture implementation and
/// `filter_mode.dart`'s compile-time switch are gone; live is the only
/// shipping implementation now).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/filter_repository.dart';
import '../data/live_filter_repository.dart';

final filterRepositoryProvider = Provider<FilterRepository>((ref) {
  return LiveFilterRepository(LaCasaApi.create());
});
