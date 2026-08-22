/// Stand-in body for every screen this build doesn't implement yet. Later
/// agents replace individual routes' `builder:` in `app_router.dart` with
/// the real screen widget — this file (and every route wired to it) is
/// meant to shrink over time, not to be built on top of.
library;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Renders [name] centered in a themed [Scaffold], with a back button when
/// there's somewhere to go back to (i.e. this instance was pushed, not a
/// tab root).
///
/// The central [Text] is wrapped in a [KeyedSubtree] keyed off [name]
/// (`screen-<name>`) specifically so widget tests can assert *which*
/// placeholder is on screen without depending on font/style details — see
/// `test/navigation/tab_shell_test.dart`.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: colors.screen,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: colors.ink,
              title: Text(
                name,
                style: type.navTitle.copyWith(color: colors.ink),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: KeyedSubtree(
            key: ValueKey('screen-$name'),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: type.sectionHeading.copyWith(color: colors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
