/// The `.gl`-glass equivalent of the mockup's `<nav class="tabbar">`
/// (build spec, "Exact tab set" table): a floating, blurred pill bar that
/// drives [StatefulNavigationShell.goBranch] directly rather than any
/// `NavigationBar`/`BottomNavigationBar`.
///
/// **Icon note**: the mockup specifies Phosphor filled glyphs
/// (`house`/`magnifying-glass`/`briefcase`/`users-three`/`user`). No
/// Phosphor package is in `pubspec.yaml` (this build owns `lib/navigation/`
/// only and may not add one), so this uses the closest Material rounded
/// icons instead — a deliberate, documented divergence, not an oversight.
///
/// **This widget no longer decides anything about role.** It used to watch
/// [authSessionProvider] and add/drop a single "Work" item from an otherwise
/// fixed row — the shape that made an agent "the buyer app plus a tab". The
/// app now declares two separate shells (see `app_router.dart`), so which
/// tab set is on screen follows from which shell is mounted, and each shell
/// hands this widget the matching [items] list. Role reactivity moved up to
/// the router's redirect, which swaps the whole shell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import 'tab_item.dart';

// These were `const List<TabItem>` literals before localization — a
// localized label needs a BuildContext/AppLocalizations, which a `const`
// initializer can't provide, so each becomes a small function taking
// [l10n] instead. Both callers (`app_router.dart`'s two shell builders)
// already have a context to read AppLocalizations from.

/// The buyer shell's four tabs — what a signed-out session, a buyer, and an
/// agent in [WorkspaceMode.browse] all see. Indices match that shell's
/// branch list exactly.
List<TabItem> buyerTabItems(AppLocalizations l10n) => [
  TabItem(branchIndex: 0, label: l10n.navTabHomeLabel, icon: Icons.home_rounded),
  TabItem(
    branchIndex: 1,
    label: l10n.navTabSearchLabel,
    icon: Icons.search_rounded,
  ),
  TabItem(
    branchIndex: 2,
    label: l10n.navTabAgentsLabel,
    icon: Icons.groups_rounded,
  ),
  TabItem(
    branchIndex: 3,
    label: l10n.navTabProfileLabel,
    icon: Icons.person_rounded,
  ),
];

/// The agent shell's five tabs — the CRM (SCREENS.md §21–§38) promoted from
/// one crowded "Work" tab to the whole tab bar. Indices match that shell's
/// branch list exactly.
List<TabItem> agentTabItems(AppLocalizations l10n) => [
  TabItem(
    branchIndex: 0,
    label: l10n.navTabDashboardLabel,
    icon: Icons.dashboard_rounded,
  ),
  TabItem(
    branchIndex: 1,
    label: l10n.navTabMyAdsLabel,
    icon: Icons.home_work_rounded,
  ),
  TabItem(
    branchIndex: 2,
    label: l10n.navTabLeadsLabel,
    icon: Icons.people_alt_rounded,
  ),
  TabItem(
    branchIndex: 3,
    label: l10n.navTabCoworkersLabel,
    icon: Icons.groups_2_rounded,
  ),
  TabItem(
    branchIndex: 4,
    label: l10n.navTabProfileLabel,
    icon: Icons.person_rounded,
  ),
];

class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;

  /// The row this bar draws, supplied by whichever shell mounted it —
  /// [buyerTabItems] or [agentTabItems].
  final List<TabItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(AppRadii.pillButton),
          // The one piece of glass that genuinely floats above scrolling
          // content, so it can carry a wider band than the small-first
          // `.gl` default — this is where the refraction is most visible.
          distortionWidth: 16,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final item in items)
                _TabButton(
                  item: item,
                  selected: item.branchIndex == navigationShell.currentIndex,
                  colors: colors,
                  type: type,
                  onTap: () => navigationShell.goBranch(
                    item.branchIndex,
                    initialLocation:
                        item.branchIndex == navigationShell.currentIndex,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.colors,
    required this.type,
    required this.onTap,
  });

  final TabItem item;
  final bool selected;
  final LaCasaColors colors;
  final LaCasaTypography type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `.tab{color:var(--ink-2)}` — an unselected tab is icon-only
    // (`.tab span{display:none}`), so it stays at the *secondary* ink tier
    // rather than the tertiary [LaCasaColors.muted] that quiet body copy uses.
    // `muted` reads at 5.0:1 on this bar's glass over the app surface and all
    // but disappears (~1.2:1) where the bar floats over a dark listing photo;
    // `ink2` is 10.4:1 / 9.6:1 on the surface and stays legible over photos,
    // without reaching `ink`, which would match the selected pill's own weight
    // and flatten the distinction the pill is there to make.
    final foreground = selected ? colors.pillInk : colors.ink2;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        key: ValueKey('navTab-${item.branchIndex}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.pill : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // `.tab .i{font-size:21px}` / `.tab.on .i{font-size:17px}` — the
              // unselected glyph is the *larger* of the two, the other half of
              // the mockup's compensation for carrying the whole affordance
              // with no label and no pill behind it.
              Icon(item.icon, size: selected ? 17 : 21, color: foreground),
              if (selected) ...[
                const SizedBox(width: 6),
                Text(item.label, style: type.label.copyWith(color: foreground)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
