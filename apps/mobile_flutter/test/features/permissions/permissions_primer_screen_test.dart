// Widget tests for `permissions-primer` (SCREENS.md §3.2).
//
// The gateway is overridden per test rather than left on its
// UnavailablePermissionGateway default, because the three outcomes are the
// whole point of the row's state machine and only one of them is reachable
// with the default installed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/features/permissions/permissions.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_permission_gateway.dart';

void main() {
  /// Pumps the primer on top of a stub caller, so "Continue" and "Not now"
  /// have something real to pop back to — §3.2's "returns to the screen
  /// that triggered it" is only observable with a screen underneath.
  Future<void> pumpPrimer(
    WidgetTester tester, {
    PermissionGateway? gateway,
    bool withCaller = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: withCaller
          ? RoutePaths.home
          : RoutePaths.permissionsPrimer,
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('caller')),
        ),
        GoRoute(
          path: RoutePaths.permissionsPrimer,
          builder: (context, state) => const PermissionsPrimerScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (gateway != null)
            permissionGatewayProvider.overrideWithValue(gateway),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (withCaller) {
      router.push(RoutePaths.permissionsPrimer);
      await tester.pumpAndSettle();
    }
  }

  group('copy (§3.2, quoted)', () {
    testWidgets('renders the header, both rows and all three buttons', (
      tester,
    ) async {
      await pumpPrimer(tester);

      expect(find.text('Allow La Casa to…'), findsOneWidget);

      expect(find.text('Camera & Photos'), findsOneWidget);
      expect(
        find.text('To add photos to your listings and profile avatar'),
        findsOneWidget,
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(
        find.text('To alert you about new leads and publish status.'),
        findsOneWidget,
      );

      // One "Allow" per row, plus the two footer buttons.
      expect(find.text('Allow'), findsNWidgets(2));
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('grant outcomes', () {
    testWidgets('a granted permission replaces its button with "Allowed"', (
      tester,
    ) async {
      await pumpPrimer(
        tester,
        gateway: FakePermissionGateway(PermissionOutcome.granted),
      );

      await tester.tap(find.text('Allow').first);
      await tester.pumpAndSettle();

      expect(find.text('Allowed'), findsOneWidget);
      // The other row is untouched — each asks independently.
      expect(find.text('Allow'), findsOneWidget);
    });

    testWidgets('a denied permission says so, and points at settings', (
      tester,
    ) async {
      await pumpPrimer(
        tester,
        gateway: FakePermissionGateway(PermissionOutcome.denied),
      );

      await tester.tap(find.text('Allow').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Not allowed — you can change this in system settings'),
        findsOneWidget,
      );
    });

    testWidgets(
      'with no permission backend the row says so rather than implying a prompt',
      (tester) async {
        // The shipped default — see permission_gateway.dart on why no
        // manifest declarations were added ahead of a feature using them.
        await pumpPrimer(tester);

        await tester.tap(find.text('Allow').first);
        await tester.pumpAndSettle();

        expect(find.text('Not available in this build yet'), findsOneWidget);
        // "We never asked" must never render as "you said no".
        expect(
          find.text('Not allowed — you can change this in system settings'),
          findsNothing,
        );
      },
    );

    testWidgets('each row requests only its own permission', (tester) async {
      final gateway = FakePermissionGateway(PermissionOutcome.granted);
      await pumpPrimer(tester, gateway: gateway);

      await tester.tap(find.text('Allow').first);
      await tester.pumpAndSettle();

      expect(gateway.requested, [AppPermission.cameraAndPhotos]);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();

      expect(gateway.requested, [
        AppPermission.cameraAndPhotos,
        AppPermission.notifications,
      ]);
    });
  });

  group('exits', () {
    testWidgets('Continue returns to the screen that triggered it', (
      tester,
    ) async {
      await pumpPrimer(tester);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('caller'), findsOneWidget);
      expect(find.byType(PermissionsPrimerScreen), findsNothing);
    });

    testWidgets('Not now dismisses without requesting anything', (
      tester,
    ) async {
      final gateway = FakePermissionGateway(PermissionOutcome.granted);
      await pumpPrimer(tester, gateway: gateway);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('caller'), findsOneWidget);
      expect(gateway.requested, isEmpty);
    });

    testWidgets('a deep link with nothing to pop still leaves', (tester) async {
      await pumpPrimer(tester, withCaller: false);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Falls back to Home rather than throwing on an empty stack.
      expect(find.text('caller'), findsOneWidget);
    });
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label}', (tester) async {
        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) {
            overflows.add(text.split('\n').first);
          } else {
            previous?.call(details);
          }
        };
        addTearDown(() => FlutterError.onError = previous);

        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpPrimer(tester);
        await tester.tap(find.text('Allow').first);
        await tester.pumpAndSettle();

        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });
}
