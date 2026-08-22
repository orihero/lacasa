/// A controllable [HomeFeedRepository] fake for widget tests — no network,
/// no fixture-file coupling, so a test can hand it exactly the ads/agents
/// it wants to assert against, or make it throw.
///
/// Used to also fake the saved/favourited-ad-id set; that seam moved to
/// `lib/shared/state/favourite_ad_ids_repository.dart` (see its doc
/// comment), so its fake moved too — see
/// `test/shared/support/fake_favourite_ad_ids_repository.dart`.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/data/home_feed_repository.dart';

class FakeHomeFeedRepository implements HomeFeedRepository {
  FakeHomeFeedRepository({
    List<Ad>? ads,
    List<AgentSummary>? agents,
    this.adsFor,
    this.feedError,
    this.topAgentsError,
  }) : ads = ads ?? const [],
       agents = agents ?? const [];

  final List<Ad> ads;

  /// When set, [fetchFeed] answers through this instead of returning [ads]
  /// flat — the way a test stands in for the server actually honouring the
  /// category chip's `type`, rather than just recording that it was sent.
  final List<Ad> Function(AdFilters filters)? adsFor;
  final List<AgentSummary> agents;

  /// When set, [fetchFeed] throws this instead of returning [ads].
  final Object? feedError;

  /// When set, [fetchTopAgents] throws this instead of returning [agents].
  final Object? topAgentsError;

  /// Held open by a test that needs to see what a rail renders **while** a
  /// request is still in flight — the skeleton a Retry tap is supposed to
  /// show, say. Both fetches await it before answering anything.
  ///
  /// Deliberately mutable, unlike everything above it: the interesting
  /// sequence is "let the first load settle (into data, or into the error
  /// that puts the retry card on screen), *then* hold the second one open",
  /// and a `final` field set at construction cannot express that. Without a
  /// gate there is no frame to assert on at all — an `async` method that
  /// returns or throws immediately completes in the same microtask drain as
  /// the `pump` that would have rendered the skeleton, so the test would see
  /// only the settled result either way and could not tell the fixed
  /// behaviour from the broken one.
  Future<void>? gate;

  int fetchFeedCallCount = 0;

  /// Every [AdFilters] [fetchFeed] has been called with, in order — the
  /// category chip row narrows the feed by re-requesting it, so "which
  /// filter did the chip send, and did it send one at all" is the thing
  /// those tests need to see.
  final List<AdFilters> feedFilterLog = [];

  @override
  Future<List<Ad>> fetchFeed({AdFilters filters = const AdFilters()}) async {
    fetchFeedCallCount++;
    feedFilterLog.add(filters);
    if (gate != null) await gate;
    if (feedError != null) throw feedError!;
    return adsFor?.call(filters) ?? ads;
  }

  /// Counted for the same reason [fetchFeedCallCount] is: pull-to-refresh
  /// invalidates the Top Agents rail's provider as well as the feed's, and
  /// "the gesture refetched everything on the screen, not just the list"
  /// is only observable here.
  int fetchTopAgentsCallCount = 0;

  @override
  Future<List<AgentSummary>> fetchTopAgents() async {
    fetchTopAgentsCallCount++;
    if (gate != null) await gate;
    if (topAgentsError != null) throw topAgentsError!;
    return agents;
  }
}
