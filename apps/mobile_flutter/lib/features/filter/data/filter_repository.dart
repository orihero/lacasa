/// Data-access seam for `filter-sheet`'s live result-count preview
/// (SCREENS.md §5: "field changes debounce 300ms and update a live
/// result-count preview inside the sheet"). Two implementations —
/// [FixtureFilterRepository] (bundled, no network) and
/// [LiveFilterRepository] (the real [LaCasaApi]) — see `filter_mode.dart`
/// for which one the app wires up by default.
///
/// There is deliberately only one method here. `GET /ads` has no
/// lightweight "count only" shape (`apps/api/src/services/adService.js`'s
/// `listAds` always returns the full serialized row set), so a "live
/// count" is really "fetch the full filtered list and read `.length`" —
/// documented here rather than hidden behind a name that implies a
/// cheaper query exists server-side.
library;

import '../../../api/api.dart';

abstract class FilterRepository {
  /// Number of ads that would match [filters] right now. Re-issues the
  /// full `GET /ads` fetch under the hood and returns its length — see
  /// this file's doc comment. Zero matches is a normal, non-error result
  /// (returns `0`); network/parsing failures still throw the usual
  /// [ApiException] hierarchy so the caller can show a scoped retry
  /// affordance around just the count row rather than losing the whole
  /// sheet.
  Future<int> countMatching(AdFilters filters);
}
