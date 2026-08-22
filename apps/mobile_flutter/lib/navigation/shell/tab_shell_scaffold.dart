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
///
/// **Every `showModalBottomSheet`/`showDialog` opened from inside a branch
/// MUST pass `useRootNavigator: true`.** [GlassTabBar] is this [Scaffold]'s
/// `bottomNavigationBar`, a sibling of [body] — Flutter's own internal
/// `_ScaffoldLayout` stack paints `bottomNavigationBar` *after* `body` and
/// therefore hit-tests it *first*. A sheet opened with the default
/// `useRootNavigator: false` mounts on the nearest [Navigator], which for
/// any widget inside [navigationShell] is the *branch's* Navigator — itself
/// hosted inside this [body] slot, i.e. underneath the bar in both paint and
/// hit-test order. The bar's own [GlassSurface] blur then samples the
/// sheet's content straight through it (the M2 "pink glow" symptom), and a
/// tap aimed at the sheet's bottom edge lands on whatever tab button is
/// there instead. Reordering the children of this [Scaffold] cannot fix
/// this — `body`/`bottomNavigationBar` ordering is owned by the framework,
/// not by this widget — so the only correct fix is at the call site:
/// `showModalBottomSheet(context: context, useRootNavigator: true, ...)`
/// mounts on `app_router.dart`'s `rootNavigatorKey` Navigator instead, the
/// same one `login`/`register`'s full-screen modals already push onto, which
/// sits above this entire shell (bar included). `showDialog` does not need
/// the same reminder — its default `useRootNavigator` is already `true`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/theme.dart';
import 'glass_tab_bar.dart';
import 'tab_item.dart';

class TabShellScaffold extends StatelessWidget {
  const TabShellScaffold({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;

  /// Which tab row this shell draws — `buyerTabItems` or `agentTabItems`.
  /// Passed down rather than derived here because the app declares two
  /// shells and each one already knows which it is; see `tab_item.dart`.
  final List<TabItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Scaffold(
      extendBody: true,
      backgroundColor: colors.screen,
      body: navigationShell,
      bottomNavigationBar: GlassTabBar(
        navigationShell: navigationShell,
        items: items,
      ),
    );
  }
}
