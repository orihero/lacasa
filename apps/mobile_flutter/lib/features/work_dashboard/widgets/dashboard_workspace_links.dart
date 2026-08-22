/// `mockup-e-liquid-glass.html`'s `.grouplab`"Workspace" + `.stack` of three
/// `.lrow gl` quick-nav rows (My Ads / Leads / Coworkers) at the foot of the
/// dashboard — not named in SCREENS.md §3.24's own terse prose, but present
/// verbatim in the shipped mockup DOM, the same "mockup DOM over an earlier
/// prose draft" precedent `home_feed_screen.dart` already established for
/// this app. Each row reuses [ListRow] (the exact `.lrow gl` shape) and its
/// subtitle is real, already-fetched data — no new fetch of its own.
///
/// **The Leads row's `{n} active` figure is [countActiveLeads], not
/// `leads.length`.** It used to be the raw `GET /leads` table size, the same
/// inflated number the "Active leads" stat tile showed — two places printing
/// the word "active" over a count that included archived and closed leads.
/// Both now call the one shared helper in `state/dashboard_providers.dart`
/// specifically so they can no longer drift apart; that helper's doc comment
/// records which statuses it excludes and why.
///
/// The `{dueToday}` half of the very same ARB string is
/// [countCallbacksDueToday], which folds that identical active-lead
/// predicate before counting — otherwise one closed lead with a stale
/// `callbackDate` would make this single sentence contradict itself
/// ("0 active · 1 need a call back"). Both halves of one string must be
/// counted over one population.
///
/// **The Coworkers row is dropped for a session with no team to manage**
/// ([canManageCoworkersProvider]) — the same gate the "Coworker statistics"
/// section and the "Coworkers" stat tile take, so a solo realtor sees no
/// coworker surface anywhere on this screen rather than a shortcut into a
/// roster `POST /coworkers` forbids them to add to. See
/// `dashboard_screen.dart`'s doc comment.
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
    final canManageCoworkers = ref.watch(canManageCoworkersProvider);
    // Deliberately not fetched at all when the row is hidden: nothing else
    // on a solo realtor's dashboard reads the roster (the tile and the
    // statistics section take the same gate), so watching it would spend a
    // request whose only possible answer is the empty list.
    final coworkersAsync = canManageCoworkers
        ? ref.watch(dashboardCoworkersProvider)
        : const AsyncValue<List<Coworker>>.data(<Coworker>[]);
    final l10n = AppLocalizations.of(context);

    final adsSubtitle = adsAsync.whenOrNull(
      data: (ads) {
        final drafts = ads.where((a) => a.stage == AdStage.draft).length;
        return l10n.dashboardWorkspaceMyAdsSubtitle(ads.length, drafts);
      },
    );
    final leadsSubtitle = leadsAsync.whenOrNull(
      data: (leads) => l10n.dashboardWorkspaceLeadsSubtitle(
        countActiveLeads(leads),
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
        if (canManageCoworkers) ...[
          const SizedBox(height: 12),
          ListRow(
            key: const ValueKey('workspaceLink-coworkers'),
            icon: Icons.groups_outlined,
            title: l10n.dashboardWorkspaceCoworkersRowTitle,
            subtitle: coworkersSubtitle,
            onTap: () => context.push(RoutePaths.workCoworkers),
          ),
        ],
      ],
    );
  }
}
