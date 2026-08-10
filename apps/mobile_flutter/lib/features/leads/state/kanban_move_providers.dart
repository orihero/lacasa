/// Kanban's move state — replicates `apps/console`'s `KanbanScreen.tsx`
/// optimistic-then-confirmed-clear mechanism exactly, per
/// `WORK_TAB_CONTRACT.md` ruling 7.5 (read that ruling before touching this
/// file).
///
/// Three pieces of per-lead state, all keyed by lead id:
/// - [KanbanMoveState.overrides] — a local `LeadStatus` that wins over
///   whatever [leadsProvider]'s own list says, applied the instant a move is
///   confirmed (before the `PATCH` resolves). [displayStatus] is how a
///   caller reads "which column does this card actually sit in right now".
/// - [KanbanMoveState.pending] — lead ids with a move request currently in
///   flight; drives the "spinner overlays that one card" rule (SCREENS.md
///   §5's Kanban-move bullet) and clears the instant the request settles,
///   success or failure, independent of whether the override above is still
///   showing.
/// - [KanbanMoveState.failed] — lead ids whose most recent move attempt
///   failed, driving the "Couldn't move — try again." note on that one card
///   (console's own copy, replicated verbatim per the ruling above).
///
/// **Why the override isn't cleared synchronously on success.** A
/// successful `PATCH` doesn't mean [leadsProvider]'s cached list has caught
/// up yet — [LeadsNotifier.updateLead] re-fetches after the mutation
/// resolves, but that re-fetch is a separate awaited step. Clearing the
/// override the moment the mutation call returns (before that re-fetch's
/// result lands in [leadsProvider]'s state) would flash the card back to
/// its old column for exactly the beat the ruling warns about. Instead,
/// [build] subscribes to [leadsProvider] and prunes any override once the
/// list's own status for that lead independently agrees with it — the same
/// self-healing `useEffect` console runs on its own `leads` query data.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'leads_providers.dart';

@immutable
class KanbanMoveState {
  const KanbanMoveState({
    this.overrides = const {},
    this.pending = const {},
    this.failed = const {},
  });

  final Map<String, LeadStatus> overrides;
  final Set<String> pending;
  final Set<String> failed;

  /// The column a card should render in right now — the local override if
  /// one is in flight/not yet confirmed by the list, otherwise the lead's
  /// own real status.
  LeadStatus displayStatus(Lead lead) => overrides[lead.id] ?? lead.status;

  bool isPending(String leadId) => pending.contains(leadId);

  bool hasFailed(String leadId) => failed.contains(leadId);

  KanbanMoveState copyWith({
    Map<String, LeadStatus>? overrides,
    Set<String>? pending,
    Set<String>? failed,
  }) {
    return KanbanMoveState(
      overrides: overrides ?? this.overrides,
      pending: pending ?? this.pending,
      failed: failed ?? this.failed,
    );
  }
}

class KanbanMoveNotifier extends Notifier<KanbanMoveState> {
  @override
  KanbanMoveState build() {
    // Self-heals the override map against `leadsProvider`'s own data once a
    // re-fetch (triggered by `move` below, via `LeadsNotifier.updateLead`)
    // actually lands — see this file's doc comment on why a successful move
    // can't just clear its override synchronously.
    ref.listen<AsyncValue<List<Lead>>>(leadsProvider, (previous, next) {
      final leads = next.value;
      if (leads == null || state.overrides.isEmpty) return;
      final statusById = {for (final lead in leads) lead.id: lead.status};
      final pruned = {...state.overrides}
        ..removeWhere((id, status) => statusById[id] == status);
      if (pruned.length != state.overrides.length) {
        state = state.copyWith(overrides: pruned);
      }
    });
    return const KanbanMoveState();
  }

  /// Applies [destination] optimistically, fires the `PATCH` via
  /// [LeadsNotifier.updateLead] with [input], and reconciles [state] per
  /// this file's doc comment. Rethrows on failure so a caller can decide
  /// whether to also surface a toast — the failed-card note is shown either
  /// way, driven by [KanbanMoveState.failed].
  Future<void> move({
    required Lead lead,
    required LeadWriteInput input,
    required LeadStatus destination,
  }) async {
    state = state.copyWith(
      overrides: {...state.overrides, lead.id: destination},
      pending: {...state.pending, lead.id},
      failed: {...state.failed}..remove(lead.id),
    );
    try {
      await ref.read(leadsProvider.notifier).updateLead(lead.id, input);
      state = state.copyWith(pending: {...state.pending}..remove(lead.id));
    } catch (_) {
      state = state.copyWith(
        overrides: {...state.overrides}..remove(lead.id),
        pending: {...state.pending}..remove(lead.id),
        failed: {...state.failed, lead.id},
      );
      rethrow;
    }
  }
}

final kanbanMoveProvider = NotifierProvider<KanbanMoveNotifier, KanbanMoveState>(
  KanbanMoveNotifier.new,
);
