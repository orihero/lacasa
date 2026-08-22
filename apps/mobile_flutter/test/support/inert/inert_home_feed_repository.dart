/// An inert stand-in for [HomeFeedRepository].
///
/// **Why this exists.** `homeFeedRepositoryProvider` unconditionally builds a
/// live repository around `LaCasaApi.create()` now that the bundled fixture
/// repositories — and the `FLUTTER_TEST` guard in `lib/api/app_mode.dart`
/// that used to force them — are gone. Any widget test that mounts the real
/// app router therefore drags the Home shell in with it, and an
/// un-overridden Home feed provider fires real HTTP out of the test process.
/// That does not fail cleanly: it hangs, and the test dies on
/// `pumpAndSettle timed out` with nothing pointing at the cause. Overriding
/// the provider with this class is what keeps that from happening.
///
/// **It is deliberately inert.** Every method returns the emptiest value its
/// signature allows and none of them throw, so a screen built on top of it
/// renders its empty state and settles immediately. Nothing here is seed
/// data, and nothing here is stable enough to assert against — an empty feed
/// is the *absence* of a fixture, not a small one.
///
/// **A test that wants real behaviour must not reach for this.** If the feed
/// content is part of what the test is checking — rail ordering, card
/// contents, an error path, a call being made at all — override
/// `homeFeedRepositoryProvider` with a purpose-built fake from
/// `test/features/home/support/` instead, one that returns the ads that test
/// is about and can record what was asked of it.
library;

import 'package:lacasa_mobile/api/api.dart' show Ad, AdFilters, AgentSummary;
import 'package:lacasa_mobile/features/home/data/home_feed_repository.dart';

/// The feed and the top-agents rail are both empty, and neither call fails.
class InertHomeFeedRepository implements HomeFeedRepository {
  const InertHomeFeedRepository();

  @override
  Future<List<Ad>> fetchFeed({AdFilters filters = const AdFilters()}) async =>
      const [];

  @override
  Future<List<AgentSummary>> fetchTopAgents() async => const [];
}
