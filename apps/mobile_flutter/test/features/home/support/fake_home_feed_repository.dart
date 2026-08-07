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
    this.feedError,
    this.topAgentsError,
  }) : ads = ads ?? const [],
       agents = agents ?? const [];

  final List<Ad> ads;
  final List<AgentSummary> agents;

  /// When set, [fetchFeed] throws this instead of returning [ads].
  final Object? feedError;

  /// When set, [fetchTopAgents] throws this instead of returning [agents].
  final Object? topAgentsError;

  int fetchFeedCallCount = 0;

  @override
  Future<List<Ad>> fetchFeed() async {
    fetchFeedCallCount++;
    if (feedError != null) throw feedError!;
    return ads;
  }

  @override
  Future<List<AgentSummary>> fetchTopAgents() async {
    if (topAgentsError != null) throw topAgentsError!;
    return agents;
  }
}
