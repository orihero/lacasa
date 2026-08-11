// Widget tests for `Tour3dViewScreen` — the render-boundary scheme check,
// the same-origin navigation policy, and the route itself resolving
// through `app_router.dart`.
//
// `WebViewPlatform.instance` is set once per test to a fresh
// `FakeWebViewPlatform` — see its doc comment for why `flutter test` needs
// one at all before `WebViewController()` can be constructed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
// `NavigationRequest`/`NavigationDecision`/`WebResourceError`/
// `WebViewPlatform` are all re-exported by `webview_flutter` (a direct
// dependency) — only `fake_webview_platform.dart`'s subclasses need the
// deeper platform-interface types that aren't, see that file's own note.
import 'package:webview_flutter/webview_flutter.dart';

import 'package:lacasa_mobile/features/listing_detail/listing_detail.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_webview_platform.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<FakeWebViewPlatform> pumpScreen(
    WidgetTester tester,
    String url,
  ) async {
    final platform = FakeWebViewPlatform();
    WebViewPlatform.instance = platform;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Tour3dViewScreen(args: Tour3dViewArgs(url: url)),
      ),
    );
    await tester.pump();
    return platform;
  }

  group('scheme validation (render boundary, independent of the server)', () {
    testWidgets('a valid https URL is loaded', (tester) async {
      final platform = await pumpScreen(
        tester,
        'https://tours.lacasa.uz/ad-1001',
      );

      expect(platform.loadedUris, [
        Uri.parse('https://tours.lacasa.uz/ad-1001'),
      ]);
      expect(
        find.text("This listing's 3D tour link isn't valid."),
        findsNothing,
      );
    });

    testWidgets('a javascript: URI is refused outright, no controller made', (
      tester,
    ) async {
      final platform = await pumpScreen(tester, 'javascript:alert(1)');

      expect(platform.loadedUris, isEmpty);
      expect(
        find.text("This listing's 3D tour link isn't valid."),
        findsOneWidget,
      );
      // Nothing to retry — retrying a scheme that will never be valid
      // is not an honest offer.
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a file: URI is refused outright', (tester) async {
      final platform = await pumpScreen(tester, 'file:///etc/passwd');

      expect(platform.loadedUris, isEmpty);
      expect(
        find.text("This listing's 3D tour link isn't valid."),
        findsOneWidget,
      );
    });

    testWidgets('a scheme-less string is refused outright', (tester) async {
      final platform = await pumpScreen(tester, 'not a url at all');

      expect(platform.loadedUris, isEmpty);
      expect(
        find.text("This listing's 3D tour link isn't valid."),
        findsOneWidget,
      );
    });
  });

  group('navigation policy — pinned to the opened origin', () {
    testWidgets('a same-origin navigation (different path) is allowed', (
      tester,
    ) async {
      final platform = await pumpScreen(
        tester,
        'https://tours.lacasa.uz/ad-1001',
      );

      final decision = await platform.delegate!.onNavigationRequest!(
        const NavigationRequest(
          url: 'https://tours.lacasa.uz/ad-1001/scene/2',
          isMainFrame: true,
        ),
      );

      expect(decision, NavigationDecision.navigate);
    });

    testWidgets('a different host is blocked', (tester) async {
      final platform = await pumpScreen(
        tester,
        'https://tours.lacasa.uz/ad-1001',
      );

      final decision = await platform.delegate!.onNavigationRequest!(
        const NavigationRequest(
          url: 'https://evil.example.test/phish',
          isMainFrame: true,
        ),
      );

      expect(decision, NavigationDecision.prevent);
    });

    testWidgets('a same-host but different scheme is blocked', (tester) async {
      final platform = await pumpScreen(
        tester,
        'https://tours.lacasa.uz/ad-1001',
      );

      final decision = await platform.delegate!.onNavigationRequest!(
        const NavigationRequest(
          url: 'http://tours.lacasa.uz/ad-1001',
          isMainFrame: true,
        ),
      );

      expect(decision, NavigationDecision.prevent);
    });
  });

  group('page-load failure (distinct from an invalid link)', () {
    testWidgets('a main-frame load error shows Retry, which reloads', (
      tester,
    ) async {
      final platform = await pumpScreen(
        tester,
        'https://tours.lacasa.uz/ad-1001',
      );

      platform.delegate!.onWebResourceError!(
        const WebResourceError(
          errorCode: -2,
          description: 'net::ERR_NAME_NOT_RESOLVED',
          isForMainFrame: true,
        ),
      );
      await tester.pump();

      expect(find.text("Couldn't load the 3D tour."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(platform.loadedUris.length, 2);
      expect(find.text("Couldn't load the 3D tour."), findsNothing);
    });
  });

  group('route resolving', () {
    testWidgets(
      'RoutePaths.tour3dView pushes Tour3dViewScreen with a typed extra',
      (tester) async {
        WebViewPlatform.instance = FakeWebViewPlatform();

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const SizedBox()),
            GoRoute(
              path: RoutePaths.tour3dView,
              builder: (context, state) {
                final args = state.extra;
                if (args is! Tour3dViewArgs) return const Text('placeholder');
                return Tour3dViewScreen(args: args);
              },
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            routerConfig: router,
          ),
        );

        router.push(
          RoutePaths.tour3dView,
          extra: const Tour3dViewArgs(url: 'https://tours.lacasa.uz/ad-1001'),
        );
        // Two pumps, not `pumpAndSettle`: the pushed screen shows an
        // indeterminate `CircularProgressIndicator` while the (fake) load is
        // in flight, which never "settles" — the same reason
        // `listing_detail_screen_test.dart`'s loading-state test doesn't
        // settle either. One pump processes the push, the second finishes
        // `MaterialPage`'s transition.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(Tour3dViewScreen), findsOneWidget);
        expect(find.text('placeholder'), findsNothing);
      },
    );

    testWidgets('a missing/wrong-typed extra does not crash the route', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SizedBox()),
          GoRoute(
            path: RoutePaths.tour3dView,
            builder: (context, state) {
              final args = state.extra;
              if (args is! Tour3dViewArgs) return const Text('placeholder');
              return Tour3dViewScreen(args: args);
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      );

      router.push(RoutePaths.tour3dView);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('placeholder'), findsOneWidget);
    });
  });
}
