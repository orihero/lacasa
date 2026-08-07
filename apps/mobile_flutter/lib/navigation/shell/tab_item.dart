import 'package:flutter/widgets.dart';

/// One entry in the bottom tab bar. [branchIndex] is the *fixed* index into
/// [StatefulShellRoute]'s branch list (always 0=Home, 1=Search, 2=Work,
/// 3=Agents, 4=Profile — branches themselves never change), which is not
/// the same as this item's position in the row the tab bar actually draws:
/// the Work item is simply omitted from that row for a buyer/signed-out
/// session (see `glass_tab_bar.dart`), so the row can have 4 or 5 entries
/// while branch indices stay stable.
@immutable
class TabItem {
  const TabItem({
    required this.branchIndex,
    required this.label,
    required this.icon,
  });

  final int branchIndex;
  final String label;
  final IconData icon;
}
