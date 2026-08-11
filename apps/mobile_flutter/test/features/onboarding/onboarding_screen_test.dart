// Widget tests for `onboarding` (SCREENS.md §3.1) — the screen itself and
// the router gate that decides whether anyone ever sees it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/onboarding/onboarding.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../home/support/fake_home_feed_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'support/fake_onboarding_repository.dart';

void main() {
  /// Pumps the real router with the seen-flag seeded, which is the only way
  /// to exercise the gate — `_redirect` reads the provider, not an argument.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    required bool hasSeenOnboarding,
    FakeOnboardingRepository? repository,
    String? initialLocation,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(
          repository ?? FakeOnboardingRepository(),
        ),
        onboardingSeenProvider.overrideWith(
          () => SeededOnboardingSeenNotifier(hasSeenOnboarding),
        ),
        homeFeedRepositoryProvider.overrideWithValue(
          FakeHomeFeedRepository(),
        ),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (initialLocation != null) {
      router.go(initialLocation);
      await tester.pumpAndSettle();
    }
    return container;
  }

  group('the gate', () {
    testWidgets('a first launch lands on onboarding, not Home', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: false);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.byType(HomeFeedScreen), findsNothing);
    });

    testWidgets('a returning launch goes straight to Home', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: true);

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('a deep link on a first launch is still gated', (tester) async {
      // There is no destination in the app worth reaching ahead of the
      // introduction — a stale link included.
      await pumpApp(
        tester,
        hasSeenOnboarding: false,
        initialLocation: RoutePaths.search,
      );

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('after it is seen, /onboarding is not somewhere to go back to', (
      tester,
    ) async {
      await pumpApp(
        tester,
        hasSeenOnboarding: true,
        initialLocation: RoutePaths.onboarding,
      );

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(HomeFeedScreen), findsOneWidget);
    });
  });

  group('slides (§3.1 copy, quoted)', () {
    testWidgets('opens on slide 1 with its exact copy', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: false);

      expect(find.text('Manage every listing in one place'), findsOneWidget);
      expect(
        find.text(
          'Keep all your listings organized and easy to access, all in one app.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('advances through all three, ending on Get Started', (
      tester,
    ) async {
      await pumpApp(tester, hasSeenOnboarding: false);

      // §3.1 names a button only on the final slide; the earlier ones carry
      // "Next" so a user who never tries a swipe is not stranded.
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Get Started'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Share to every channel at once'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text('Track leads from first contact to close'),
        findsOneWidget,
      );

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('Skip is on every slide', (tester) async {
      await pumpApp(tester, hasSeenOnboarding: false);

      for (var i = 0; i < 3; i++) {
        expect(find.text('Skip'), findsOneWidget, reason: 'slide ${i + 1}');
        if (i < 2) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
    });
  });

  group('exits', () {
    testWidgets('Get Started marks it seen and lands on Home', (tester) async {
      final repo = FakeOnboardingRepository();
      final container = await pumpApp(
        tester,
        hasSeenOnboarding: false,
        repository: repo,
      );

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(container.read(onboardingSeenProvider), isTrue);
      expect(repo.markSeenCallCount, 1);
    });

    testWidgets('Skip is a decision, not a deferral — it persists too', (
      tester,
    ) async {
      final repo = FakeOnboardingRepository();
      final container = await pumpApp(
        tester,
        hasSeenOnboarding: false,
        repository: repo,
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      // Re-showing next launch would ignore what the user just said.
      expect(container.read(onboardingSeenProvider), isTrue);
      expect(repo.markSeenCallCount, 1);
    });

    testWidgets('skipping from a middle slide works the same', (tester) async {
      final repo = FakeOnboardingRepository();
      await pumpApp(tester, hasSeenOnboarding: false, repository: repo);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(repo.markSeenCallCount, 1);
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

        await pumpApp(tester, hasSeenOnboarding: false);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });
}
