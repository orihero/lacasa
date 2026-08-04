/// The `StatefulShellRoute.indexedStack` builder's return widget — the one
/// [Scaffold] shared by every tab.
///
/// `extendBody: true` (build spec, "Screen scaffold"): the floating glass
/// tab bar sits *over* the last ~30px of scrollable content rather than
/// pushing it up, so each branch's scroll view must be able to draw
/// underneath the bar. [navigationShell] itself is the body — it is an
/// [IndexedStack] under the hood, which is what keeps every branch's
/// [Navigator] (back stack) and scroll state alive across tab switches
/// (build spec, "Per-branch back stack & scroll position").
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import 'glass_tab_bar.dart';

class TabShellScaffold extends StatelessWidget {
  const TabShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.screen,
      body: navigationShell,
      bottomNavigationBar: GlassTabBar(navigationShell: navigationShell),
    );
  }
}
