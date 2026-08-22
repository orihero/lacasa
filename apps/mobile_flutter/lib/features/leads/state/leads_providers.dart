/// Riverpod state for the `leads` feature's list — the one list `leads-list`
/// (§30) and `leads-kanban` (§31) both render, plus its own create/update/
/// delete mutations (used by `create-lead` §33, `lead-detail` §32, and
/// indirectly by `kanban-move-sheet`'s move flow — see
/// `kanban_move_providers.dart`).
///
/// Every mutation re-fetches the full list afterward rather than patching
/// [state] locally: there is no pagination to worry about losing (`GET
/// /leads` always returns everything, see `leads_repository.dart`), and a
/// full re-fetch is exactly the signal `kanban_move_providers.dart` needs
/// to know a move has "really" landed — see contract ruling 7.5.
///
/// **The post-mutation re-fetch preserves the previously-loaded list on
/// failure** ([_refetch] simply leaves [state] alone if the re-fetch
/// throws) rather than collapsing [state] to a bare [AsyncError]. The
/// mutation itself already succeeded by the time this re-fetch runs — a
/// transient hiccup on this second, separate `GET /leads` must not
/// misrepresent a successful write as a fatal load failure, nor strand a
/// Kanban move's optimistic override (`kanban_move_providers.dart`'s
/// self-heal listener needs `next.value` to stay non-null to do its job).
/// `leads_list_screen.dart`/`leads_kanban_screen.dart` both render cached
/// data whenever `leadsProvider.hasValue`, falling back to the fatal error
/// screen only when there truly is no list to show (e.g. the very first
/// load fails).
///
/// **Every successful mutation also invalidates [dashboardLeadsProvider]**
/// (`work_dashboard`'s own, independent copy of this same `GET /leads`
/// fetch — see that provider's doc comment for why it isn't just this one
/// reused directly). Dashboard stays mounted for the whole Work-tab session
/// (`StatefulShellRoute.indexedStack`), so without this its "Active leads"
/// tile and "N need a call back" subtitle would silently go stale the
/// moment a lead is created/edited/deleted or moved on Kanban.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../work_dashboard/state/dashboard_providers.dart';
import 'leads_repository_provider.dart';

class LeadsNotifier extends AsyncNotifier<List<Lead>> {
  @override
  Future<List<Lead>> build() => ref.read(leadsRepositoryProvider).list();

  Future<Lead> createLead(LeadWriteInput input) async {
    final repo = ref.read(leadsRepositoryProvider);
    final created = await repo.create(input);
    await _refetch();
    return created;
  }

  /// Used both by `lead-detail`'s plain field-edit Save and by
  /// `kanban_move_providers.dart`'s move flow — a Kanban move is, on the
  /// wire, just another `PATCH /leads/:id`.
  Future<Lead> updateLead(String id, LeadWriteInput input) async {
    final repo = ref.read(leadsRepositoryProvider);
    final updated = await repo.update(id, input);
    await _refetch();
    return updated;
  }

  Future<void> deleteLead(String id) async {
    final repo = ref.read(leadsRepositoryProvider);
    await repo.delete(id);
    await _refetch();
  }

  /// See this file's doc comment for why a failed refetch keeps [state]'s
  /// previous value instead of discarding it, and why every call also
  /// invalidates [dashboardLeadsProvider].
  ///
  /// Deliberately **not** `state = await AsyncValue.guard(repo.list)`: on
  /// failure that would collapse [state] to a bare `AsyncError`, discarding
  /// whatever list was already loaded (`AsyncValue.copyWithPrevious`, the
  /// idiomatic way to keep it attached to an error, is `@internal` as of
  /// Riverpod 3 — not available outside the package). The mutation itself
  /// already succeeded by the time this runs, so simply leaving [state]
  /// alone on a failed refetch is both simpler and more honest than
  /// surfacing a fabricated "load failed" for a write that didn't.
  Future<void> _refetch() async {
    final repo = ref.read(leadsRepositoryProvider);
    try {
      state = AsyncValue.data(await repo.list());
    } catch (_) {
      // Keep whatever `state` already was — see doc comment above.
    }
    ref.invalidate(dashboardLeadsProvider);
  }
}

final leadsProvider = AsyncNotifierProvider<LeadsNotifier, List<Lead>>(
  LeadsNotifier.new,
);

/// The read-only coworker list backing `lead-detail`/`create-lead`'s
/// "Coworker" line — see `leads_repository.dart#coworkers`'s doc comment
/// for why this is display-only.
final leadCoworkersProvider = FutureProvider.autoDispose<List<Coworker>>((
  ref,
) {
  return ref.read(leadsRepositoryProvider).coworkers();
});

/// A single lead for `lead-detail`, keyed by id. Prefers the already-loaded
/// list (no extra request, no flash of stale data when the caller opened
/// this sheet from a row that already had the [Lead] in hand) and falls
/// back to a direct fetch for a caller with only an id — `notifications`'
/// "lead notification → lead-detail" tap target (SCREENS.md §22), which
/// never has the full list loaded.
///
/// Deliberately **watches** [leadsProvider] rather than reading it once, so
/// this sheet's fields refresh automatically the moment [LeadsNotifier]'s
/// own mutations land (e.g. Save from this very sheet re-fetches the list,
/// and this provider picks the freshly-saved lead back up from it).
final leadByIdProvider = FutureProvider.autoDispose.family<Lead, String>((
  ref,
  id,
) async {
  final listState = ref.watch(leadsProvider);
  final fromList = listState.value?.where((l) => l.id == id).firstOrNull;
  if (fromList != null) return fromList;
  return ref.read(leadsRepositoryProvider).getById(id);
});
