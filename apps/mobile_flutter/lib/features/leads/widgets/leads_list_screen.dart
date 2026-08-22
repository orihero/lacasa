/// `leads-list` (SCREENS.md §30) — header "Leads", "+ Add new lead" →
/// `create-lead`, a view-toggle icon → `leads-kanban`. Rows tap into
/// `lead-detail` via [showLeadDetailSheet].
///
/// Also the home of [refreshLeads], the pull-to-refresh action both this
/// screen and `leads-kanban` run — see that function's doc comment.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/leads_providers.dart';
import 'lead_detail_sheet.dart';
import 'lead_list_row.dart';
import 'leads_nav_actions.dart';

/// Re-fetches [leadsProvider] and completes only once the new list has
/// landed, so a [RefreshIndicator] holds its spinner for the round trip
/// instead of snapping shut on the synchronous `invalidate`.
///
/// **Why the leads CRM needs this more than any other list.** Leads are
/// team-wide, not per-user: a coworker's call, or an entry made in the web
/// console, is a row this agent is expected to act on. [leadsProvider] is a
/// plain (non-`autoDispose`) provider, so once it has loaded it is never
/// rebuilt — switching tabs keeps it, backgrounding the app keeps it, and
/// the only other `ref.invalidate(leadsProvider)` in the feature is the
/// Retry button on the error state, which never renders while the list is
/// merely stale. A lead added at 10am was invisible until the process was
/// killed.
///
/// Shared by `leads-list` and `leads-kanban` rather than written twice
/// because they are two views of exactly this one provider, one toggle tap
/// apart; two copies would be two chances for the gesture to mean something
/// different on each. Errors are swallowed: the screen's own `hasError`
/// branch renders the failure with a Retry, and rejecting here would raise
/// an unhandled zone error on top of it.
Future<void> refreshLeads(WidgetRef ref) async {
  ref.invalidate(leadsProvider);
  try {
    await ref.read(leadsProvider.future);
  } catch (_) {
    // Rendered by the caller's own error branch.
  }
}

class LeadsListScreen extends ConsumerWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
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
              title: l10n.leadsListScreenTitle,
              onBack: () => _pop(context),
              trailing: [
                LeadsNavActions(
                  toggleIcon: Icons.view_kanban_outlined,
                  toggleLabel: l10n.leadsToggleViewKanbanLabel,
                  toggleKey: const ValueKey('leadsList-toggleView'),
                  onToggleView: () => context.push(RoutePaths.workLeadsKanban),
                  addKey: const ValueKey('leadsList-addLead'),
                  onAddLead: () => context.push(RoutePaths.workCreateLead),
                ),
              ],
            ),
            const Expanded(child: _LeadsListBody()),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }
}

class _LeadsListBody extends ConsumerWidget {
  const _LeadsListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    // The indicator wraps *every* state, not just the populated list. The
    // empty state is the one this matters most on — "No leads yet." on a
    // board a coworker added a lead to twenty minutes ago is precisely the
    // stale read [refreshLeads] exists to clear — and a state with nothing
    // to scroll gives a [RefreshIndicator] no notification to arm from, so
    // those branches go through [RefreshableFill].
    return RefreshIndicator(
      key: const ValueKey('leadsList-refresh'),
      onRefresh: () => refreshLeads(ref),
      color: AppAccent.color,
      backgroundColor: colors.card,
      child: _body(context, ref),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadsProvider);
    final l10n = AppLocalizations.of(context);

    // `hasValue` first, not `.when()`: a post-mutation refetch failure keeps
    // the previous list attached (`LeadsNotifier._refetch`'s
    // `copyWithPrevious`), so an `AsyncError` that still carries a value
    // should render that cached list, not the fatal error screen below —
    // see `leads_providers.dart`'s doc comment.
    if (leadsAsync.hasValue) {
      final leads = leadsAsync.value!;
      if (leads.isEmpty) {
        return RefreshableFill(
          child: FullWidthState(
            icon: Icons.groups_outlined,
            message: l10n.leadsEmptyMessage,
          ),
        );
      }
      return ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
        child: ListView.builder(
          // A team of two with three leads does not fill a phone, and a
          // short list under the default physics accepts no drag at all.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.sm,
            AppSpacing.screenGutter,
            MediaQuery.of(context).padding.bottom + 100,
          ),
          itemCount: leads.length,
          itemBuilder: (context, index) {
            final lead = leads[index];
            return LeadListRow(
              lead: lead,
              onTap: () => showLeadDetailSheet(context, leadId: lead.id),
            );
          },
        ),
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

    return const _LoadingList();
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenGutter,
        vertical: AppSpacing.sm,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        child: ShimmerBox(
          height: 68,
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
    );
  }
}
