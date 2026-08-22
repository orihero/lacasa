/// `leads-kanban` (SCREENS.md §31) — 5 fixed-order columns (New → Could Not
/// Connect → Need To Call Back → Rejected → Accepted, never reorderable),
/// laid out one full-screen-width page per column via `PageView` so the
/// board "snaps one column per screen-width on phones" (SCREENS.md §5).
/// A slim column-select strip above the board offers a direct jump to any
/// column — the honest answer to "how do I reach column 5 without four
/// consecutive swipes", since this build has no drag-and-drop to fall back
/// on either.
///
/// The mobile drag substitute (SCREENS.md §5's "Kanban move"): long-press a
/// card to open a "Move to…" action sheet of the other 4 columns.
/// `New`/`Could Not Connect` move immediately; `Need To Call Back`/
/// `Rejected`/`Accepted` open `kanban-move-sheet` first and only move on its
/// Save. Every move goes through `kanban_move_providers.dart`'s
/// [kanbanMoveProvider], which owns the optimistic-then-confirmed-clear
/// mechanism (contract ruling 7.5) — this screen only ever reads its
/// [KanbanMoveState] and calls [KanbanMoveNotifier.move].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/kanban_move_providers.dart';
import '../state/leads_providers.dart';
import 'kanban_column.dart';
import 'kanban_move_sheet.dart';
import 'lead_detail_sheet.dart';
import 'lead_form_controls.dart';
import 'leads_list_screen.dart' show refreshLeads;
import 'leads_nav_actions.dart';

class LeadsKanbanScreen extends ConsumerStatefulWidget {
  const LeadsKanbanScreen({super.key});

  @override
  ConsumerState<LeadsKanbanScreen> createState() => _LeadsKanbanScreenState();
}

class _LeadsKanbanScreenState extends ConsumerState<LeadsKanbanScreen> {
  late final PageController _pageController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLeadsList(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.workLeads);
    }
  }

  Future<void> _handleLongPress(Lead lead) async {
    final destination = await _showMoveToSheet(context, lead: lead);
    if (destination == null || !mounted) return;
    await _attemptMove(lead, destination);
  }

  Future<void> _attemptMove(Lead lead, LeadStatus destination) async {
    final immediate =
        destination == LeadStatus.newLead ||
        destination == LeadStatus.couldNotConnect;

    LeadWriteInput input;
    if (immediate) {
      input = LeadWriteInput(status: OptionalField(destination));
    } else {
      final result = await showKanbanMoveSheet(
        context,
        destination: destination,
      );
      if (result == null || !mounted) return;
      input = result;
    }

    // The optimistic override (below, via `KanbanMoveNotifier.move`) relocates
    // this card to `destination`'s column immediately — but each column is
    // its own full-screen `PageView` page here (unlike console's side-by-side
    // grid), so without this jump the card (and SCREENS.md §5's "spinner
    // overlays that one card" feedback) would land on a page nobody is
    // looking at. Snap there so the user actually sees it.
    _jumpToColumn(destination);

    try {
      await ref
          .read(kanbanMoveProvider.notifier)
          .move(lead: lead, input: input, destination: destination);
    } catch (_) {
      // The card's own "Couldn't move · Retry" row (driven by
      // `KanbanMoveState.failed`, rendered by `kanban_card.dart`'s
      // `_MoveFailedRow`) already carries this *and* offers the way back
      // into the same move — nothing further to do here, matching
      // `apps/console`'s identical choice not to also pop a toast for the
      // same failure. A failed move clears the
      // optimistic override (`KanbanMoveNotifier.move`'s catch clause), so
      // the card — and that note — actually reappear back in [lead]'s own
      // original column; follow it back there too.
      if (mounted) _jumpToColumn(lead.status);
    }
  }

  /// Snaps the board to whichever page shows [status]'s column. Always
  /// (re)issues `animateToPage` rather than first checking whether that's
  /// already the page in view: `_page` only updates once `onPageChanged`
  /// fires on a *completed* animate, so on an immediately-rejecting `PATCH`
  /// the failure's jump-back can run before the destination jump's own
  /// animation has ticked a single frame — comparing against `_page` at
  /// that point would still read the pre-move page and wrongly no-op,
  /// leaving the board stuck on the (about to be empty) destination column.
  /// A second `animateToPage` call while the first is still in flight simply
  /// retargets it, so this is safe to call unconditionally.
  void _jumpToColumn(LeadStatus status) {
    if (!_pageController.hasClients) return;
    final index = LeadStatus.kanbanOrder.indexOf(status);
    unawaited(
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      ),
    );
  }

  /// `hasValue` first, not `.when()`: a post-mutation refetch failure keeps
  /// the previous list attached (`LeadsNotifier._refetch`'s
  /// `copyWithPrevious`), so an `AsyncError` that still carries a value
  /// should render the (mostly correct) cached board, not the fatal error
  /// screen below — see `leads_providers.dart`'s doc comment.
  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<Lead>> leadsAsync,
    KanbanMoveState moveState,
  ) {
    final l10n = AppLocalizations.of(context);
    if (leadsAsync.hasValue) {
      final leads = leadsAsync.value!;
      if (leads.isEmpty) {
        // Scrollable so the pull gesture still reaches the indicator — see
        // [_LeadsKanbanScreenState.build]. An empty board is the state a
        // manual refresh is most often reached for.
        return RefreshableFill(
          child: FullWidthState(
            icon: Icons.groups_outlined,
            message: l10n.leadsEmptyMessage,
          ),
        );
      }

      final columns = <LeadStatus, List<Lead>>{
        for (final status in LeadStatus.kanbanOrder) status: <Lead>[],
      };
      for (final lead in leads) {
        final displayStatus = moveState.displayStatus(lead);
        (columns[displayStatus] ??= <Lead>[]).add(lead);
      }

      return Stack(
        children: [
          Column(
            children: [
              _ColumnStrip(
                selectedIndex: _page,
                counts: [
                  for (final status in LeadStatus.kanbanOrder)
                    columns[status]!.length,
                ],
                onSelect: (index) => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: LeadStatus.kanbanOrder.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) {
                    final status = LeadStatus.kanbanOrder[index];
                    return KanbanColumn(
                      status: status,
                      leads: columns[status]!,
                      pendingLeadIds: moveState.pending,
                      failedDestinations: moveState.failedDestinations,
                      onCardTap: (lead) =>
                          showLeadDetailSheet(context, leadId: lead.id),
                      onCardLongPress: _handleLongPress,
                      // Retry replays the whole move, gate sheet included:
                      // for `need_to_call_back`/`rejected`/`accepted` the
                      // failed attempt's call time / conversation note lives
                      // in a `LeadWriteInput` this screen never kept (the
                      // sheet builds it and hands it straight to
                      // `KanbanMoveNotifier.move`), and re-asking is the
                      // honest way to get it back — silently re-sending a
                      // remembered note would also be re-sending it under a
                      // timestamp the agent never saw.
                      onCardRetry: _attemptMove,
                    );
                  },
                ),
              ),
            ],
          ),
          // `.kbhint gl` — the floating hint pill. The gesture that moves a
          // card between columns (long-press) is invisible otherwise; this
          // is the only place the app names it.
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 68,
            child: Center(
              child: GlassSurface(
                variant: GlassVariant.onSurface,
                borderRadius: AppRadii.pill,
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Align(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  child: Text(
                    l10n.leadsKanbanLongPressHint,
                    style: Theme.of(context)
                        .extension<LaCasaTypography>()!
                        .bodySmall
                        .copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(
                            context,
                          ).extension<LaCasaColors>()!.ink2,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (leadsAsync.hasError) {
      return RefreshableFill(
        child: FullWidthState(
          icon: Icons.error_outline_rounded,
          message: l10n.leadsLoadErrorMessage,
          actionLabel: l10n.sharedRetryLabel,
          onAction: () => ref.invalidate(leadsProvider),
        ),
      );
    }

    return const _LoadingBoard();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final leadsAsync = ref.watch(leadsProvider);
    final moveState = ref.watch(kanbanMoveProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: l10n.leadsKanbanScreenTitle,
              onBack: () => _goToLeadsList(context),
              trailing: [
                LeadsNavActions(
                  toggleIcon: Icons.view_list_outlined,
                  toggleLabel: l10n.leadsToggleViewListLabel,
                  toggleKey: const ValueKey('leadsKanban-toggleView'),
                  onToggleView: () => _goToLeadsList(context),
                  addKey: const ValueKey('leadsKanban-addLead'),
                  onAddLead: () => context.push(RoutePaths.workCreateLead),
                ),
              ],
            ),
            Expanded(
              // Pull-to-refresh, on the same [refreshLeads] the list view
              // runs — the two are one toggle tap apart over one provider
              // and must not disagree about what the gesture does.
              //
              // **`notificationPredicate` is load-bearing here, unlike on
              // `leads-list`.** The board's vertical scrollers are the
              // per-column `ListView`s inside [KanbanColumn], and each one
              // sits under the horizontal `PageView` that pages between
              // columns. Every `Scrollable` a notification passes through
              // increments its `depth`, so those `ListView`s report at
              // depth 1 and the default predicate (`depth == 0`) would
              // discard every one of them — the indicator would exist and
              // never arm. Accepting depth 1 picks them up. The `PageView`'s
              // own depth-0 notifications are horizontal, and
              // [RefreshIndicator] already refuses to start on a horizontal
              // axis, so widening the predicate cannot make a sideways swipe
              // trigger a refetch.
              child: RefreshIndicator(
                key: const ValueKey('leadsKanban-refresh'),
                onRefresh: () => refreshLeads(ref),
                notificationPredicate: (notification) =>
                    notification.depth <= 1,
                color: AppAccent.color,
                backgroundColor: colors.card,
                child: _buildBody(context, leadsAsync, moveState),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SCREENS.md §31/§5's "Move to…" action sheet — a context line naming the
/// lead and the column it is in now, then the 4 columns other than that
/// one. Returns the chosen [LeadStatus], or `null` if the sheet was
/// dismissed.
Future<LeadStatus?> _showMoveToSheet(
  BuildContext context, {
  required Lead lead,
}) {
  return showModalBottomSheet<LeadStatus>(
    context: context,
    backgroundColor: Colors.transparent,
    // Mounts above the floating tab bar — see tab_shell_scaffold.dart's doc
    // comment for why this is required, not optional, for every sheet
    // opened from inside a shell branch.
    useRootNavigator: true,
    builder: (context) {
      final colors = Theme.of(context).extension<LaCasaColors>()!;
      final type = Theme.of(context).extension<LaCasaTypography>()!;
      final current = lead.status;
      final options = LeadStatus.kanbanOrder
          .where((s) => s != current)
          .toList();

      return Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.base,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: AppRadii.pill,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).leadsMoveToSheetTitle,
                    style: type.sheetTitle.copyWith(color: colors.ink),
                  ),
                ),
                LeadSheetCloseButton(
                  semanticsLabel: AppLocalizations.of(
                    context,
                  ).sharedNavRowCloseLabel,
                  // Pops with no value — the caller reads that as "cancelled",
                  // same as a drag-dismiss.
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            // `.sh__p` — which lead is moving, and where it sits now, so
            // the four destination pills are not four unlabelled choices.
            const SizedBox(height: 7),
            Text(
              AppLocalizations.of(context).leadsMoveToContextLine(
                lead.fullName,
                leadStatusLabel(AppLocalizations.of(context), current),
              ),
              style: type.bodySmall.copyWith(color: colors.muted, height: 1.62),
            ),
            const SizedBox(height: 14),
            // `.opts{display:flex;flex-wrap:wrap;gap:7px}` — the destination
            // columns are option pills wrapping two per line, not a stack of
            // full-width rows.
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final status in options)
                  LeadOptionChip(
                    key: ValueKey('moveToSheet-${status.wire}'),
                    label: leadStatusLabel(
                      AppLocalizations.of(context),
                      status,
                    ),
                    isOn: false,
                    onTap: () => Navigator.of(context).pop(status),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// The board's first-load skeleton — a strip of shimmer pills over three
/// shimmer cards, in the same gutter and at the same rhythm the real board
/// uses, so nothing jumps when the data lands.
///
/// This screen used to fall through to a bare [CircularProgressIndicator]
/// while `leads-list` — the *same* [leadsProvider], one toggle tap away —
/// showed six shimmer rows, as do coworkers, my-listings, search,
/// notifications and publish-status. A spinner and a skeleton say different
/// things ("something is happening" vs. "this shape of thing is about to
/// appear"), and having the two views of one list disagree about which is
/// the answer was the whole defect.
///
/// The pill widths are deliberately uneven: the real strip's pills are
/// `"{n}/5 · {count}"`, whose width varies with the count, and a row of
/// identical boxes reads as a progress bar rather than as content.
class _LoadingBoard extends StatelessWidget {
  const _LoadingBoard();

  /// One per real column, so the strip doesn't change length when the data
  /// arrives.
  static const List<double> _pillWidths = [58, 74, 66, 62, 70];

  /// Three cards, not a screenful: the board shows one column per
  /// screen-width, and three `.kcard`-height boxes is about what sits above
  /// the floating long-press hint on the shortest phone this app targets —
  /// enough to say "cards go here", not so many that the skeleton claims a
  /// column length it cannot know yet.
  static const int _cardCount = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('leadsKanban-loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              overscroll: false,
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              itemCount: _pillWidths.length,
              separatorBuilder: (context, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => ShimmerBox(
                width: _pillWidths[index],
                height: 34,
                borderRadius: AppRadii.pill,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          child: Column(
            // Stretch so each `ShimmerBox` — which carries a height but no
            // width — fills the column instead of collapsing to zero.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < _cardCount; index++)
                Padding(
                  // `.kb__cards{gap:9px}` — the real card list's own gap.
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ShimmerBox(
                    height: 96,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColumnStrip extends StatelessWidget {
  const _ColumnStrip({
    required this.selectedIndex,
    required this.counts,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<int> counts;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final statuses = LeadStatus.kanbanOrder;

    return SizedBox(
      height: 34,
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          itemCount: statuses.length,
          separatorBuilder: (context, _) =>
              const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final isSelected = index == selectedIndex;
            return GestureDetector(
              key: ValueKey('kanbanStrip-${statuses[index].wire}'),
              onTap: () => onSelect(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.pill : colors.sunk,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  '${index + 1}/${statuses.length} · ${counts[index]}',
                  style: type.label.copyWith(
                    color: isSelected ? colors.pillInk : colors.muted,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
