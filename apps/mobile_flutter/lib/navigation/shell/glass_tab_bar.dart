/// The `.gl`-glass equivalent of the mockup's `<nav class="tabbar">`
/// (build spec, "Exact tab set" table): a floating, blurred pill bar whose
/// visible item set depends on role, and which drives
/// [StatefulNavigationShell.goBranch] directly rather than any
/// `NavigationBar`/`BottomNavigationBar`.
///
/// **Icon note**: the mockup specifies Phosphor filled glyphs
/// (`house`/`magnifying-glass`/`briefcase`/`users-three`/`user`). No
/// Phosphor package is in `pubspec.yaml` (this build owns `lib/navigation/`
/// only and may not add one), so this uses the closest Material rounded
/// icons instead — a deliberate, documented divergence, not an oversight.
///
/// **Role-gating mechanism (build spec, "Why the Work branch always
/// exists", point 1)**: this widget is a [ConsumerWidget] watching
/// [authSessionProvider] directly. Watching means it rebuilds the instant
/// sign-in/sign-out/role-change fires, with no dependency on go_router's
/// own rebuild cycle and no restart — the Work item simply is or isn't in
/// the [items] list computed on every build.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../auth_session.dart';
import 'tab_item.dart';

// These were `const List<TabItem>` literals before localization — a
// localized label needs a BuildContext/AppLocalizations, which a `const`
// initializer can't provide, so each becomes a small function taking
// [l10n] instead. [tabItemsFor]'s only caller (`GlassTabBar.build`) already
// has a context to read AppLocalizations from.
List<TabItem> _alwaysOn(AppLocalizations l10n) => [
  TabItem(branchIndex: 0, label: l10n.navTabHomeLabel, icon: Icons.home_rounded),
  TabItem(branchIndex: 1, label: l10n.navTabSearchLabel, icon: Icons.search_rounded),
];

TabItem _work(AppLocalizations l10n) =>
    TabItem(branchIndex: 2, label: l10n.navTabWorkLabel, icon: Icons.work_rounded);

List<TabItem> _tail(AppLocalizations l10n) => [
  TabItem(branchIndex: 3, label: l10n.navTabAgentsLabel, icon: Icons.groups_rounded),
  TabItem(branchIndex: 4, label: l10n.navTabProfileLabel, icon: Icons.person_rounded),
];

/// Signed-out/buyer -> 4 tabs (no Work); agent/coworker -> 5 tabs. Exactly
/// SCREENS.md §1.
List<TabItem> tabItemsFor(UserRole? role, AppLocalizations l10n) {
  final canWork = role == UserRole.agent || role == UserRole.coworker;
  return [..._alwaysOn(l10n), if (canWork) _work(l10n), ..._tail(l10n)];
}

class GlassTabBar extends ConsumerWidget {
  const GlassTabBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;
    final items = tabItemsFor(role, AppLocalizations.of(context));
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
    final foreground = selected ? colors.pillInk : colors.muted;

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
              Icon(item.icon, size: 20, color: foreground),
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
