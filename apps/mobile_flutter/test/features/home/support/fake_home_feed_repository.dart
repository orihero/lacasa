/// A controllable [HomeFeedRepository] fake for widget tests — no network,
/// no fixture-file coupling, so a test can hand it exactly the ads/agents
/// it wants to assert against, or make it throw.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/data/home_feed_repository.dart';

class FakeHomeFeedRepository implements HomeFeedRepository {
  FakeHomeFeedRepository({
    List<Ad>? ads,
    List<AgentSummary>? agents,
    Set<String>? savedAdIds,
    this.feedError,
    this.topAgentsError,
  }) : ads = ads ?? const [],
       agents = agents ?? const [],
       savedAdIds = savedAdIds ?? const {};

  final List<Ad> ads;
  final List<AgentSummary> agents;
  final Set<String> savedAdIds;

  /// When set, [fetchFeed] throws this instead of returning [ads].
  final Object? feedError;

  /// When set, [fetchTopAgents] throws this instead of returning [agents].
  final Object? topAgentsError;

  int fetchFeedCallCount = 0;
  int saveCallCount = 0;
  int unsaveCallCount = 0;

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

  @override
  Future<Set<String>> fetchInitialSavedAdIds() async => savedAdIds;

  @override
  Future<void> saveAd(String adId) async {
    saveCallCount++;
  }

  @override
  Future<void> unsaveAd(String adId) async {
    unsaveCallCount++;
  }
}
