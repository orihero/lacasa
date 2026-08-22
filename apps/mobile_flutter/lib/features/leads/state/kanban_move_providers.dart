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
/// - [KanbanMoveState.failed] — lead id → the [FailedMove] that lead's most
///   recent attempt recorded (the column it was trying to reach, plus the
///   column the lead was actually in at the time), driving the "Couldn't
///   move · Retry" row on that one card.
///
/// **`failed` carries the attempted destination and the lead's status when
/// the attempt failed, and is pruned, as a deliberate extension of
/// console's mechanism — flagged for human confirmation against ruling
/// 7.5.** Console stores only a set of ids and clears an entry solely when
/// a *new* move of the same lead starts, which on mobile meant three things
/// ruling 7.5 never intended: the note offered nothing to tap (the
/// long-press → "Move to…" → destination sequence is the only way back to
/// it, and nothing on the card says so), it survived leaving the board
/// entirely ([kanbanMoveProvider] is not `autoDispose`, matching console's
/// page-level React state living as long as its route), and it survived
/// *fixing* the status from `lead-detail` — leaving a card sitting in the
/// correct column under a permanent red failure label. Recording the
/// destination is what makes both fixes possible: the card can name the
/// column it will retry into, and [build]'s [leadsProvider] listener can
/// drop the entry as soon as the server's own status for that lead moves
/// off the one the failure was recorded against.
///
/// **The prune is keyed on "the status changed at all", not on "the status
/// reached the failed destination".** A red "Couldn't move to Accepted"
/// row is a claim about where the card is *now*: that it never left the
/// column it is sitting in. The moment the server says that lead is
/// somewhere other than where the failure was recorded, the claim is false
/// however the change happened — a `lead-detail` Save into a *third*
/// column (say Rejected, when the failed move wanted Accepted) is the
/// common case, and matching only the destination let exactly that card
/// keep a permanent red lie: the narrowed version of the very defect this
/// prune exists to remove. [FailedMove.origin] is what makes the wider
/// test possible.
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

/// One recorded move failure: the column the attempt was aiming for, and
/// the lead's own (server-side) status at the moment it was recorded.
///
/// [origin] exists purely so [KanbanMoveNotifier.build]'s listener can ask
/// "has this lead moved *at all* since the failure?" — see this file's doc
/// comment on why the narrower "has it reached [destination]?" test left a
/// permanent red row on cards fixed into some other column.
typedef FailedMove = ({LeadStatus destination, LeadStatus origin});

@immutable
class KanbanMoveState {
  const KanbanMoveState({
    this.overrides = const {},
    this.pending = const {},
    this.failed = const {},
  });

  final Map<String, LeadStatus> overrides;
  final Set<String> pending;

  /// lead id → that lead's last recorded [FailedMove]. A [Map], not a [Set],
  /// so the card's failure row can both name the column it will retry into
  /// and re-run the very same move on Retry, and so the listener in [build]
  /// can retire the row once the lead has moved off [FailedMove.origin] —
  /// see this file's doc comment.
  final Map<String, FailedMove> failed;

  /// The column a card should render in right now — the local override if
  /// one is in flight/not yet confirmed by the list, otherwise the lead's
  /// own real status.
  LeadStatus displayStatus(Lead lead) => overrides[lead.id] ?? lead.status;

  bool isPending(String leadId) => pending.contains(leadId);

  bool hasFailed(String leadId) => failed.containsKey(leadId);

  /// The column [leadId]'s failed attempt wanted, or `null` when its last
  /// move didn't fail (or has since been reconciled away by [build]'s
  /// listener).
  LeadStatus? failedDestination(String leadId) => failed[leadId]?.destination;

  /// The board's view of [failed] — lead id → the column to name (and retry
  /// into) on that card's failure row. [FailedMove.origin] is bookkeeping for
  /// the prune in [KanbanMoveNotifier.build] and nothing a widget renders,
  /// so it is dropped here rather than pushed through the widget tree.
  Map<String, LeadStatus> get failedDestinations => {
    for (final entry in failed.entries) entry.key: entry.value.destination,
  };

  KanbanMoveState copyWith({
    Map<String, LeadStatus>? overrides,
    Set<String>? pending,
    Map<String, FailedMove>? failed,
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
    //
    // The same listener retires a failure note: `leadsProvider` is re-fetched
    // after *every* lead mutation (`LeadsNotifier._refetch`), so this fires
    // for a status fixed from `lead-detail` just as it does for a retried
    // move. Once the server's own status for that lead differs *at all* from
    // the one the failure was recorded against, the card is no longer where
    // the red row says it is stuck and that row has nothing left to report —
    // whether the lead landed in the column the attempt wanted or in some
    // third one the agent picked instead. Matching only the destination is
    // what left a "Couldn't move" row on a card fixed into a different
    // column; see this file's doc comment. A lead that has left the list
    // entirely (deleted) can't have a card to carry a row either.
    ref.listen<AsyncValue<List<Lead>>>(leadsProvider, (previous, next) {
      final leads = next.value;
      if (leads == null) return;
      if (state.overrides.isEmpty && state.failed.isEmpty) return;
      final statusById = {for (final lead in leads) lead.id: lead.status};
      final prunedOverrides = {...state.overrides}
        ..removeWhere((id, status) => statusById[id] == status);
      final prunedFailed = {...state.failed}
        ..removeWhere(
          (id, attempt) =>
              !statusById.containsKey(id) || statusById[id] != attempt.origin,
        );
      if (prunedOverrides.length != state.overrides.length ||
          prunedFailed.length != state.failed.length) {
        state = state.copyWith(
          overrides: prunedOverrides,
          failed: prunedFailed,
        );
      }
    });
    return const KanbanMoveState();
  }

  /// Applies [destination] optimistically, fires the `PATCH` via
  /// [LeadsNotifier.updateLead] with [input], and reconciles [state] per
  /// this file's doc comment. Rethrows on failure so a caller can decide
  /// whether to also surface a toast — the failed-card row is shown either
  /// way, driven by [KanbanMoveState.failed], which records [destination] so
  /// that row can offer a Retry of this exact move, alongside [lead]'s own
  /// status at the time so the row can be retired the moment the lead moves
  /// off it by any route.
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
        // `lead.status` is the server's own status for this lead (the board
        // builds its cards straight off `leadsProvider`'s list), so it is
        // the value a later re-fetch has to disagree with for the row to be
        // retired.
        failed: {
          ...state.failed,
          lead.id: (destination: destination, origin: lead.status),
        },
      );
      rethrow;
    }
  }
}

final kanbanMoveProvider =
    NotifierProvider<KanbanMoveNotifier, KanbanMoveState>(
      KanbanMoveNotifier.new,
    );
