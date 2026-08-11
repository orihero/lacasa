/// `mockup-e-liquid-glass.html`'s `.grouplab`"Workspace" + `.stack` of three
/// `.lrow gl` quick-nav rows (My Ads / Leads / Coworkers) at the foot of the
/// dashboard — not named in SCREENS.md §3.24's own terse prose, but present
/// verbatim in the shipped mockup DOM, the same "mockup DOM over an earlier
/// prose draft" precedent `home_feed_screen.dart` already established for
/// this app. Each row reuses [ListRow] (the exact `.lrow gl` shape) and its
/// subtitle is real, already-fetched data — no new fetch of its own.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../state/dashboard_providers.dart';

class DashboardWorkspaceLinks extends ConsumerWidget {
  const DashboardWorkspaceLinks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(dashboardAdsProvider);
    final leadsAsync = ref.watch(dashboardLeadsProvider);
    final coworkersAsync = ref.watch(dashboardCoworkersProvider);
    final l10n = AppLocalizations.of(context);

    final adsSubtitle = adsAsync.whenOrNull(
      data: (ads) {
        final drafts = ads.where((a) => a.stage == AdStage.draft).length;
        return l10n.dashboardWorkspaceMyAdsSubtitle(ads.length, drafts);
      },
    );
    final leadsSubtitle = leadsAsync.whenOrNull(
      data: (leads) => l10n.dashboardWorkspaceLeadsSubtitle(
        leads.length,
        countCallbacksDueToday(leads),
      ),
    );
    final coworkersSubtitle = coworkersAsync.whenOrNull(
      data: (list) => l10n.dashboardWorkspaceCoworkersSubtitle(list.length),
    );

    return Column(
      children: [
        ListRow(
          key: const ValueKey('workspaceLink-myAds'),
          icon: Icons.image_outlined,
          title: l10n.dashboardWorkspaceMyAdsRowTitle,
          subtitle: adsSubtitle,
          onTap: () => context.push(RoutePaths.workMyListings),
        ),
        const SizedBox(height: 12),
        ListRow(
          key: const ValueKey('workspaceLink-leads'),
          icon: Icons.filter_alt_outlined,
          title: l10n.dashboardWorkspaceLeadsRowTitle,
          subtitle: leadsSubtitle,
          onTap: () => context.push(RoutePaths.workLeads),
        ),
        const SizedBox(height: 12),
        ListRow(
          key: const ValueKey('workspaceLink-coworkers'),
          icon: Icons.groups_outlined,
          title: l10n.dashboardWorkspaceCoworkersRowTitle,
          subtitle: coworkersSubtitle,
          onTap: () => context.push(RoutePaths.workCoworkers),
        ),
      ],
    );
  }
}
