/// A do-nothing [SearchRepository] for tests that never look at search
/// results.
///
/// **Why this exists.** `searchRepositoryProvider` now builds
/// [LiveSearchRepository] around `LaCasaApi.create()` unconditionally — the
/// bundled `FixtureSearchRepository` is gone, and with it the
/// `lib/api/app_mode.dart` guard that used to force fixtures whenever
/// `FLUTTER_TEST` was set. Any widget test that mounts the real router
/// therefore reaches the listing-search screen's provider on its way through
/// the shell and fires a real `GET /ads` out of the test process. That does
/// not fail loudly; it hangs, and the test dies on `pumpAndSettle timed out`
/// with nothing in the failure pointing at the network as the cause.
/// Overriding the provider with this class replaces that hang with an
/// instant, empty, deterministic answer.
///
/// **It is deliberately inert.** [fetchPage] answers one empty last page
/// (`items: []`, `nextCursor: null`) for every set of filters, every sort,
/// and every cursor — it does not record its arguments, does not paginate,
/// and never throws an [ApiException]. A screen driven by it renders its
/// empty state and settles. That is the whole contract.
///
/// **Do not reach for this when the search behaviour is the thing under
/// test.** A test that asserts on results, on query/sort plumbing, on
/// infinite scroll, or on error handling wants a purpose-built fake from
/// `test/features/search/support/` — one that returns seeded [Ad]s, hands
/// back a non-null [AdPage.nextCursor] so the paged fetch loop actually
/// loops, or throws to exercise the failure path. This class exists only so
/// that the *other* tests, the ones that merely pass through the screen, do
/// not have to care.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/search/data/search_repository.dart';

class InertSearchRepository implements SearchRepository {
  const InertSearchRepository();

  @override
  Future<AdPage> fetchPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    String? cursor,
  }) async => const AdPage(items: [], nextCursor: null);
}
