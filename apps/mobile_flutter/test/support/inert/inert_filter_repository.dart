/// Inert stand-in for [FilterRepository], used by the ambient provider
/// overrides that every widget test installs.
///
/// The app no longer ships bundled fixture repositories: each repository
/// provider now builds its live implementation around `LaCasaApi.create()`
/// unconditionally, even under `FLUTTER_TEST`. Widget tests that build the
/// real router mount a shell touching nearly every repository, so any
/// provider left un-overridden fires real HTTP from the test process and
/// the test dies on `pumpAndSettle timed out`. This class exists purely to
/// absorb those incidental calls: it answers instantly, never throws, and
/// never touches the network.
///
/// It is deliberately inert, not a simulation. `countMatching` always
/// reports zero matches regardless of the [AdFilters] passed, so a test
/// that asserts on the filter sheet's live result-count preview — or on
/// anything else derived from filtering — must not rely on this class.
/// Such a test should override `filterRepositoryProvider` with a
/// purpose-built fake from `test/features/filter/support/` instead.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/data/filter_repository.dart';

/// See the library doc comment: an always-empty, never-throwing
/// [FilterRepository] for tests that do not care about filtering.
class InertFilterRepository implements FilterRepository {
  const InertFilterRepository();

  /// Always `0` — "no ads match" is a normal, non-error result for the
  /// live count row, so the filter sheet renders its empty-count state
  /// without spinning or retrying.
  @override
  Future<int> countMatching(AdFilters filters) async => 0;
}
