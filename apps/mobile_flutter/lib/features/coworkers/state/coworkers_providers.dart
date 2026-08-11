/// Riverpod state for the three coworker screens.
///
/// **[coworkersListProvider] is not `.autoDispose`.** `coworkers-list` is a
/// screen a user pushes into, backs out of (to `add-coworker`/
/// `coworker-detail`) and returns to repeatedly within one Work-tab visit —
/// exactly `agentsDirectoryProvider`'s own reasoning
/// (`features/agents/state/agents_providers.dart`) for why re-fetching on
/// every glance back would be wasteful. `add_coworker_screen.dart`/
/// `coworker_detail_screen.dart` call `ref.invalidate(coworkersListProvider)`
/// after a successful create/update/delete so the roster is fresh the
/// moment the user lands back on it, rather than relying on a rebuild that
/// might not happen.
///
/// **[coworkerSummariesProvider] is independent of [coworkersListProvider]**
/// — the failure-isolation rule WORK_TAB_CONTRACT.md §6 asks for
/// ("Independent providers per independently-failable section"). A
/// coworker's row still renders (name, avatar, phone) if the summary fetch
/// fails; only the derived listings-count/last-active figures on that row
/// degrade to "…"/"—". This used to be two providers
/// ([coworkerAdsProvider]/[coworkerActivityProvider], each folded
/// client-side) — now one, since `GET /statistics/coworkers/summary` does
/// that fold server-side (see `data/coworkers_repository.dart`'s own doc
/// comment for why).
///
/// **[coworkerDetailProvider] is `.autoDispose.family`**, matching
/// `agentDetailProvider`/`EditListingScreen`'s own detail-by-id shape per
/// WORK_TAB_CONTRACT.md §6: several can be alive on one back stack at once
/// (unlikely here, since nothing else in this cluster pushes a second
/// coworker-detail on top of the first, but the convention is uniform
/// across every detail-by-id screen in this app), and state should die with
/// the route rather than accumulate one entry per coworker ever opened.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'coworkers_repository_provider.dart';

class CoworkersListNotifier extends AsyncNotifier<List<Coworker>> {
  @override
  Future<List<Coworker>> build() =>
      ref.read(coworkersRepositoryProvider).list();
}

final coworkersListProvider =
    AsyncNotifierProvider<CoworkersListNotifier, List<Coworker>>(
      CoworkersListNotifier.new,
    );

/// Backing data for [summaryFor] (`coworker_metrics.dart`) — one
/// [CoworkerSummary] row per coworker, fetched once per `coworkers-list`
/// visit and reused by `coworker-detail`.
final coworkerSummariesProvider = FutureProvider<List<CoworkerSummary>>((ref) {
  return ref.read(coworkersRepositoryProvider).summary();
});

/// One coworker, for `coworker-detail`. Fatal for that screen: an error
/// here means there is no form to render, matching
/// `agentDetailProvider`'s identical split between "fatal" (identity) and
/// "non-fatal" (a secondary section) fetches.
final coworkerDetailProvider = FutureProvider.autoDispose
    .family<Coworker, String>((ref, coworkerId) {
      return ref.read(coworkersRepositoryProvider).getById(coworkerId);
    });
