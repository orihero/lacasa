/// Data-access seam for `filter-sheet`'s live result-count preview
/// (SCREENS.md §5: "field changes debounce 300ms and update a live
/// result-count preview inside the sheet"). One implementation ships —
/// [LiveFilterRepository], over the real [LaCasaApi]; the seam stays
/// abstract so widget tests can hand the sheet a controllable fake
/// (`test/features/filter/support/fake_filter_repository.dart`) without a
/// network stack.
///
/// There is deliberately only one method here, and it is a genuine count.
/// This used to read "`GET /ads` has no lightweight count-only shape, so a
/// live count is really fetch-the-list-and-read-`.length`" — that gap is
/// closed: `adService.js`'s `listAds` now honours `?countOnly=true` and
/// answers `{ count }` from a `prisma.ad.count()` taken against the same
/// `where` the list branch would have used. The narrowing was always
/// server-side (every `AdFilters` field is a query param Prisma applies);
/// what changed is that asking "how many?" no longer transfers the answer's
/// entire evidence.
library;

import '../../../api/api.dart';

abstract class FilterRepository {
  /// Number of ads that would match [filters] right now, counted
  /// server-side — one integer over the wire, not a list to measure. Zero
  /// matches is a normal, non-error result (returns `0`); network/parsing
  /// failures still throw the usual [ApiException] hierarchy so the caller
  /// can show a scoped retry affordance around just the count row rather
  /// than losing the whole sheet.
  Future<int> countMatching(AdFilters filters);
}
