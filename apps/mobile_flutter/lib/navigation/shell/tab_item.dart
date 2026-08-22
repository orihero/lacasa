import 'package:flutter/widgets.dart';

/// One entry in the bottom tab bar. [branchIndex] is the index into the
/// enclosing [StatefulShellRoute]'s branch list — and *which* shell that is
/// depends on the session, because the app declares two (see
/// `app_router.dart`):
///
/// - the **buyer shell**: 0=Home, 1=Search, 2=Agents, 3=Profile
/// - the **agent shell**: 0=Dashboard, 1=My Ads, 2=Leads, 3=Team, 4=Profile
///
/// Only one is ever mounted, so an index is unambiguous at any moment; it is
/// not a stable identifier *across* a mode switch. Unlike the previous
/// single-shell design, the drawn row and the branch list now match
/// one-for-one — no item is conditionally omitted, so `branchIndex` is also
/// always the item's position in the row.
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
