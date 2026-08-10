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

    final adsSubtitle = adsAsync.whenOrNull(
      data: (ads) {
        final drafts = ads.where((a) => a.stage == AdStage.draft).length;
        return '${ads.length} listings · $drafts drafts';
      },
    );
    final leadsSubtitle = leadsAsync.whenOrNull(
      data: (leads) =>
          '${leads.length} active · ${countCallbacksDueToday(leads)} need a call back',
    );
    final coworkersSubtitle = coworkersAsync.whenOrNull(
      data: (list) => '${list.length} ${list.length == 1 ? 'person' : 'people'}',
    );

    return Column(
      children: [
        ListRow(
          key: const ValueKey('workspaceLink-myAds'),
          icon: Icons.image_outlined,
          title: 'My Ads',
          subtitle: adsSubtitle,
          onTap: () => context.push(RoutePaths.workMyListings),
        ),
        const SizedBox(height: 12),
        ListRow(
          key: const ValueKey('workspaceLink-leads'),
          icon: Icons.filter_alt_outlined,
          title: 'Leads',
          subtitle: leadsSubtitle,
          onTap: () => context.push(RoutePaths.workLeads),
        ),
        const SizedBox(height: 12),
        ListRow(
          key: const ValueKey('workspaceLink-coworkers'),
          icon: Icons.groups_outlined,
          title: 'Coworkers',
          subtitle: coworkersSubtitle,
          onTap: () => context.push(RoutePaths.workCoworkers),
        ),
      ],
    );
  }
}
