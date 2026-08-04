/// Root widget of the La Casa mobile app: wires up [MaterialApp.router]
/// with the design-token theme (lib/theme/) and the go_router navigation
/// shell (lib/navigation/).
///
/// System-driven theme by default with a manual override, per
/// `AppTheme`'s own contract doc: `themeMode: ThemeMode.system` here: a
/// later agent wiring an actual theme-toggle setting overrides this from
/// app state rather than changing the default.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation/app_router.dart';
import 'theme/theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'La Casa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
