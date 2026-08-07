/// Riverpod state for the two agent screens. Three providers, matching
/// `agents_repository.dart`'s three methods one-for-one — the split is the
/// failure-isolation boundary that file documents, not an arbitrary one.
///
/// **[agentsDirectoryProvider] is not `.autoDispose`**, unlike the two
/// families below. It backs a *tab root* that a user leaves and returns to
/// constantly (the tab shell keeps each branch's `Navigator` alive, so the
/// screen is not even rebuilt on a tab switch — but an autoDispose provider
/// would still be torn down the moment nothing watched it). Re-fetching the
/// whole agent list every time someone glances at another tab is the one
/// thing this screen should not do. Home's feed provider is plain for the
/// same reason.
///
/// **The two families are `.autoDispose`**, matching
/// `listing_detail_providers.dart` exactly and for the same reason: they are
/// keyed by an id from a pushed route, several can be alive on one back
/// stack at once, and the state should die with the route rather than
/// accumulate one entry per agent the user ever opened.
///
/// **[agentAdsProvider] never becomes the screen's error state.** It can
/// still throw — that is not swallowed here — but `agent_ads_grid.dart`
/// renders its own scoped retry from the `AsyncError`, so a failed ads
/// fetch leaves the identity block above it standing.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'agents_repository_provider.dart';

/// The whole agent directory — `agents-directory`'s only fetch.
class AgentsDirectoryNotifier extends AsyncNotifier<List<AgentSummary>> {
  @override
  Future<List<AgentSummary>> build() =>
      ref.read(agentsRepositoryProvider).fetchAgents();
}

final agentsDirectoryProvider =
    AsyncNotifierProvider<AgentsDirectoryNotifier, List<AgentSummary>>(
      AgentsDirectoryNotifier.new,
    );

/// One agent's profile header. Fatal for `agent-profile`: an error here
/// means there is no person to render, and the screen shows a full-width
/// not-found/retry state rather than an empty identity block.
final agentDetailProvider = FutureProvider.autoDispose
    .family<AgentDetail, String>((ref, agentId) {
      return ref.read(agentsRepositoryProvider).fetchAgent(agentId);
    });

/// One agent's active listings, for the profile's "Ads List" grid.
final agentAdsProvider = FutureProvider.autoDispose.family<List<Ad>, String>((
  ref,
  agentId,
) {
  return ref.read(agentsRepositoryProvider).fetchAgentAds(agentId);
});
