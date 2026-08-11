/// `leads-list` (SCREENS.md §30) — header "Leads", "+ Add new lead" →
/// `create-lead`, a view-toggle icon → `leads-kanban`. Rows tap into
/// `lead-detail` via [showLeadDetailSheet].
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
        return Center(
          child: FullWidthState(
            icon: Icons.groups_outlined,
            message: l10n.leadsEmptyMessage,
          ),
        );
      }
      return ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
        child: ListView.builder(
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
      return Center(
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

