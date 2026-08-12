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
    final destination = await _showMoveToSheet(context, current: lead.status);
    if (destination == null || !mounted) return;
    await _attemptMove(lead, destination);
  }

  Future<void> _attemptMove(Lead lead, LeadStatus destination) async {
    final immediate =
        destination == LeadStatus.newLead || destination == LeadStatus.couldNotConnect;

    LeadWriteInput input;
    if (immediate) {
      input = LeadWriteInput(status: OptionalField(destination));
    } else {
      final result = await showKanbanMoveSheet(context, destination: destination);
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
      // The card's own "Couldn't move — try again." note (driven by
      // `KanbanMoveState.failed`) already carries this — nothing further
      // to do here, matching `apps/console`'s identical choice not to also
      // pop a toast for the same failure. A failed move clears the
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
        return Center(
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

      return Column(
        children: [
          _ColumnStrip(
            selectedIndex: _page,
            counts: [
              for (final status in LeadStatus.kanbanOrder) columns[status]!.length,
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
                  failedLeadIds: moveState.failed,
                  onCardTap: (lead) => showLeadDetailSheet(context, leadId: lead.id),
                  onCardLongPress: _handleLongPress,
                );
              },
            ),
          ),
        ],
      );
    }

    if (leadsAsync.hasError) {
      return Center(
        child: FullWidthState(
          icon: Icons.error_outline_rounded,
          message: l10n.leadsLoadErrorMessage,
          actionLabel: l10n.sharedRetryLabel,
          onAction: () => ref.invalidate(leadsProvider),
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
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
            Expanded(child: _buildBody(context, leadsAsync, moveState)),
          ],
        ),
      ),
    );
  }
}

/// SCREENS.md §31/§5's "Move to…" action sheet — lists the 4 columns other
/// than [current]. Returns the chosen [LeadStatus], or `null` if the sheet
/// was dismissed.
Future<LeadStatus?> _showMoveToSheet(
  BuildContext context, {
  required LeadStatus current,
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
      final options = LeadStatus.kanbanOrder.where((s) => s != current).toList();

      return Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
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
                decoration: BoxDecoration(color: colors.line, borderRadius: AppRadii.pill),
              ),
            ),
            Text(
              AppLocalizations.of(context).leadsMoveToSheetTitle,
              style: type.sheetTitle.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.base),
            for (final status in options)
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  key: ValueKey('moveToSheet-${status.wire}'),
                  contentPadding: EdgeInsets.zero,
                  title: LeadStatusPill(status: status),
                  onTap: () => Navigator.of(context).pop(status),
                ),
              ),
          ],
        ),
      );
    },
  );
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
          itemCount: statuses.length,
          separatorBuilder: (context, _) => const SizedBox(width: AppSpacing.sm),
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
