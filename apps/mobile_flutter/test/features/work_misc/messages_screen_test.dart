// Widget tests for `messages` (SCREENS.md §3.23) — a deliberate static
// placeholder (see `messages_screen.dart`'s own doc comment), so there is
// no repository/fixture to fake here, just the header and the banner
// sentence. Pumped inside a real GoRouter for the same reason every other
// `work_misc` screen is: the back control branches on `context.canPop()`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/features/work_misc/work_misc.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(retry: (retryCount, error) => null);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'messages',
              builder: (context, state) => const MessagesScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    if (withBackStack) {
      router.push('${RoutePaths.work}/messages');
    } else {
      router.go('${RoutePaths.work}/messages');
    }
    await tester.pumpAndSettle();
  }

  group('header and banner (SCREENS.md §3.23)', () {
    testWidgets('shows the title', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Messages'), findsOneWidget);
    });

    testWidgets('shows the exact placeholder sentence, not invented copy', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(
        find.text(
          'Messaging is coming soon. For now, contact leads by phone.',
        ),
        findsOneWidget,
      );
    });
  });

  group('back navigation', () {
    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      await pumpScreen(tester, withBackStack: false);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label}', (tester) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpScreen(tester);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
