/// An inert stand-in for [SavedListingsRepository].
///
/// Nothing is saved, and asking costs nothing: [fetchSavedAds] answers with an
/// empty list immediately and never throws. That is the whole contract.
///
/// **Why it exists.** `savedListingsRepositoryProvider` now unconditionally
/// builds its live implementation around `LaCasaApi.create()` — the bundled
/// fixture repositories are gone, and with them the `FLUTTER_TEST` guard in
/// `lib/api/app_mode.dart` that used to swap them in. Any widget test that
/// mounts the real app router mounts a shell reaching this repository among
/// many others, so an un-overridden provider fires real HTTP out of the test
/// process. That does not fail cleanly, it *hangs*, and the test dies on
/// `pumpAndSettle timed out` with nothing pointing at the cause. Overriding
/// the provider with this class is what stops that.
///
/// **It is deliberately useless.** Empty is the one answer no test should ever
/// find worth asserting against, which is the point: this can never quietly
/// become the thing under test. A test that actually wants saved-listings
/// behaviour — rows to render, an error path, a call it counts — must say so
/// explicitly by overriding the provider with a purpose-built fake from
/// `test/features/saved_listings/support/` instead of leaning on this one.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/saved_listings/data/saved_listings_repository.dart';

/// See this library's doc comment.
class InertSavedListingsRepository implements SavedListingsRepository {
  const InertSavedListingsRepository();

  @override
  Future<List<Ad>> fetchSavedAds() async => const <Ad>[];
}
