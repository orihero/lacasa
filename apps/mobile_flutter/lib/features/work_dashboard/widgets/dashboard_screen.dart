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
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'ads_statistics_panel.dart';
import 'coworker_statistics_section.dart';
import 'dashboard_stat_tiles.dart';
import 'dashboard_time_range_selector.dart';
import 'dashboard_workspace_links.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

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
                      const SizedBox(height: AppSpacing.base),
                      const DashboardStatTiles(),
                      const SizedBox(height: AppSpacing.section),
                      const AdsStatisticsPanel(),
                      const SizedBox(height: AppSpacing.section),
                      SectionHeader(
                        title: AppLocalizations.of(context).dashboardCoworkerStatisticsSectionTitle,
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      const CoworkerStatisticsSection(),
                      const SizedBox(height: AppSpacing.section),
                      ListRowGroupLabel(AppLocalizations.of(context).dashboardWorkspaceGroupLabel),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

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
            label: AppLocalizations.of(context).dashboardNotificationsSemanticsLabel,
            child: GestureDetector(
              key: const ValueKey('dashboardNotificationsButton'),
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(RoutePaths.workNotifications),
              child: GlassSurface(
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
            ),
          ),
        ],
      ),
    );
  }
}

