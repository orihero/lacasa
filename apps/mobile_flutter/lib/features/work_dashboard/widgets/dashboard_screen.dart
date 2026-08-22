/// `dashboard` (SCREENS.md §24) — "Statistics". The Work tab's own root for
/// an agent session (`app_router.dart`'s `_redirect`: agent → `workDashboard`,
/// coworker → `workMyListings` — coworker sessions never reach this screen
/// at all, matching §24's own "coworker sessions skip this screen" note and
/// §5's "role: 'coworker' opens Work directly on my-listings"). Rendered as
/// a tab-root screen (no back arrow), the same header pattern
/// `home_feed_screen.dart`/`profile_agent_screen.dart` use for their own
/// branch roots.
///
/// Body, top to bottom (`mockup-e-liquid-glass.html`'s own DOM order):
/// time-range selector → 2×2 stat tiles → "Ads statistics" panel →
/// "Coworker statistics" (bar chart + list) → "Workspace" quick-nav rows.
/// Every data-backed section reads its own independent provider (see
/// `state/dashboard_providers.dart`'s doc comment) so one failing fetch
/// degrades only its own section.
///
/// **The "Coworker statistics" section is dropped entirely for a session
/// that has no team to manage** — [canManageCoworkersProvider], the same
/// `RealtorKind.solo` test `coworkers_list_screen.dart` hides its
/// "+ Add new coworker" action on. A solo realtor is the default choice on
/// `register`, and `POST /coworkers` 403s for one, so this whole third of
/// the screen could only ever render a permanently empty state for them.
/// `dashboard_stat_tiles.dart` and `dashboard_workspace_links.dart` gate
/// their own coworker surfaces on the identical provider, so the three
/// disappear together rather than leaving a stray tile pointing at a
/// section that is no longer there.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../work_misc/state/notifications_providers.dart';
import '../state/dashboard_providers.dart';
import 'ads_statistics_panel.dart';
import 'coworker_statistics_section.dart';
import 'dashboard_stat_tiles.dart';
import 'dashboard_time_range_selector.dart';
import 'dashboard_workspace_links.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final canManageCoworkers = ref.watch(canManageCoworkersProvider);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DashboardHeader(),
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    AppSpacing.base,
                    AppSpacing.screenGutter,
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DashboardTimeRangeSelector(),
                      // Both the tile grid and the "Ads statistics" panel
                      // carry `margin-top:16px` in the mockup, not the
                      // 20px `.sec` rhythm the coworker section below uses.
                      const SizedBox(height: AppSpacing.lg),
                      const DashboardStatTiles(),
                      const SizedBox(height: AppSpacing.lg),
                      const AdsStatisticsPanel(),
                      // See this file's doc comment: the whole section goes
                      // away for a solo realtor, its own heading and the
                      // rhythm around it included — a bare heading over
                      // nothing would be a worse artefact than the empty
                      // panel it replaced.
                      if (canManageCoworkers) ...[
                        const SizedBox(height: AppSpacing.section),
                        SectionHeader(
                          title: AppLocalizations.of(
                            context,
                          ).dashboardCoworkerStatisticsSectionTitle,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: AppSpacing.base),
                        const CoworkerStatisticsSection(),
                      ],
                      const SizedBox(height: AppSpacing.section),
                      ListRowGroupLabel(
                        AppLocalizations.of(
                          context,
                        ).dashboardWorkspaceGroupLabel,
                      ),
                      const DashboardWorkspaceLinks(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    // `.nav .badge-dot` — shown only once the notifications fetch has
    // actually reported an unread row; a loading/failed fetch shows no dot
    // rather than guessing (same "never claim what the data didn't say"
    // rule every other section on this screen follows).
    final hasUnread = ref
        .watch(notificationsProvider)
        .maybeWhen(
          data: (rows) => rows.any((row) => row.unread),
          orElse: () => false,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context).dashboardScreenHeaderTitle,
              style: type.navTitle.copyWith(color: colors.ink),
            ),
          ),
          Semantics(
            button: true,
            label: AppLocalizations.of(
              context,
            ).dashboardNotificationsSemanticsLabel,
            child: GestureDetector(
              key: const ValueKey('dashboardNotificationsButton'),
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(RoutePaths.workNotifications),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GlassSurface(
                    variant: GlassVariant.onSurface,
                    borderRadius: AppRadii.pill,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.notifications_rounded,
                      size: 19,
                      color: colors.ink,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: 7,
                      right: 8,
                      child: Container(
                        key: const ValueKey('dashboardNotificationsBadgeDot'),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppAccent.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.screen, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
