// Widget tests for `connected-accounts` (SCREENS.md §3.21). Pumped inside a
// real GoRouter — its back control branches on `context.canPop()` and the
// Telegram section reads `authSessionProvider` directly — neither of which
// exists without a router/session in the tree. Same shape as
// `test/features/settings/settings_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_misc/state/connected_accounts_repository_provider.dart';
import 'package:lacasa_mobile/features/work_misc/work_misc.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_connected_accounts_repository.dart';
import 'support/work_misc_test_data.dart';

ConnectedInstagramAccount instagramAccount({
  String igUserId = 'ig-1',
  String? username = 'lacasa.javlon',
  int? mediaCount = 40,
  int? followersCount = 900,
  int? followsCount = 120,
}) {
  return ConnectedInstagramAccount.fromJson({
    'igUserId': igUserId,
    'username': username,
    'expiresAt': null,
    'profile_picture_url': null,
    'media_count': mediaCount,
    'followers_count': followersCount,
    'follows_count': followsCount,
  });
}

void main() {
  setUp(() {
    // Connect Instagram / the Disconnect button never exercise a real
    // platform channel in a widget test — Clipboard.setData does, though,
    // so this stands in for it exactly like
    // `test/features/agents/agent_profile_screen_test.dart`'s identical
    // setUp.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Pumps `ConnectedAccountsScreen` at `/work/connected-accounts`, with the
  /// Work root as the route below it (`canPop()` is true — the ordinary
  /// case).
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeConnectedAccountsRepository repository,
    List<int> tgChatIds = const [],
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        connectedAccountsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).signIn(
      authUser(
        id: 'agent-1',
        fullName: 'Javlon Rustamov',
        email: 'agent@lacasa.uz',
        role: 'agent',
        tgChatIds: tgChatIds,
      ),
    );

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'connected-accounts',
              builder: (context, state) => const ConnectedAccountsScreen(),
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
      router.push('${RoutePaths.work}/connected-accounts');
    } else {
      router.go('${RoutePaths.work}/connected-accounts');
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §3.21 title', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeConnectedAccountsRepository(),
      );
      expect(find.text('Connected Accounts'), findsOneWidget);
    });

    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeConnectedAccountsRepository(),
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeConnectedAccountsRepository(),
        withBackStack: false,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });
  });

  group('Instagram section', () {
    testWidgets('shows a shimmer skeleton while loading, then settles', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakeConnectedAccountsRepository(hold: gate);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [connectedAccountsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider.notifier).signIn(
        authUser(
          id: 'agent-1',
          fullName: 'Javlon Rustamov',
          email: 'agent@lacasa.uz',
          role: 'agent',
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const ConnectedAccountsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Connected Accounts'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
    });

    testWidgets('a load failure shows Retry and re-fetches', (tester) async {
      final repo = FakeConnectedAccountsRepository(
        fetchError: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(
        find.text("Couldn't load your Instagram accounts."),
        findsOneWidget,
      );
      expect(repo.fetchCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, 2);
    });

    testWidgets(
      'no connected accounts: toggle is off and no cards render',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeConnectedAccountsRepository(accounts: const []),
        );

        expect(
          find.bySemanticsLabel('Not connected'),
          findsAtLeastNWidgets(1),
        );
        expect(find.textContaining('Posts '), findsNothing);
      },
    );

    testWidgets(
      'ruling 7.9: renders the real Posts/Followers/Following fields',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeConnectedAccountsRepository(
            accounts: [instagramAccount()],
          ),
        );

        expect(find.text('lacasa.javlon'), findsOneWidget);
        expect(find.text('Posts 40'), findsOneWidget);
        expect(find.text('Followers 900'), findsOneWidget);
        expect(find.text('Following 120'), findsOneWidget);
      },
    );

    testWidgets(
      'a field the Graph API omitted is not fabricated as zero',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeConnectedAccountsRepository(
            accounts: [
              instagramAccount(mediaCount: null, followersCount: null),
            ],
          ),
        );

        expect(find.textContaining('Posts'), findsNothing);
        expect(find.textContaining('Followers'), findsNothing);
        expect(find.text('Following 120'), findsOneWidget);
      },
    );

    testWidgets('Disconnect removes the card and shows a success toast', (
      tester,
    ) async {
      final repo = FakeConnectedAccountsRepository(
        accounts: [instagramAccount()],
      );
      await pumpScreen(tester, repository: repo);

      expect(find.text('lacasa.javlon'), findsOneWidget);

      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();

      expect(repo.disconnectedIds, ['ig-1']);
      expect(find.text('lacasa.javlon'), findsNothing);
      expect(find.text('Instagram account disconnected.'), findsOneWidget);
    });

    testWidgets(
      'Connect Instagram copies the sign-in link and says so honestly',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeConnectedAccountsRepository(),
        );

        await tester.tap(find.text('Connect Instagram'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Instagram sign-in link copied'),
          findsOneWidget,
        );
        // Never the OAuth-return copy §21 specifies — this build has no way
        // to detect the callback completing (see the screen's own doc
        // comment).
        expect(find.text('Instagram account connected!'), findsNothing);
      },
    );

    testWidgets(
      'a failed connect-url fetch shows the §21 failure copy verbatim',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeConnectedAccountsRepository(
            connectUrlError: const NetworkException('offline'),
          ),
        );

        await tester.tap(find.text('Connect Instagram'));
        await tester.pumpAndSettle();

        expect(
          find.text('Instagram connection failed — please try again.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Telegram section (ruling 7.10 — count-only, no per-channel cards)', () {
    testWidgets('no connected channels: toggle off, honest empty copy', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeConnectedAccountsRepository(),
      );

      expect(find.text('No Telegram channels connected'), findsOneWidget);
    });

    testWidgets('connected channels: toggle on, real count rendered', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeConnectedAccountsRepository(),
        tgChatIds: const [111, 222, 333],
      );

      expect(find.text('3 channels connected'), findsOneWidget);
    });
  });

  group('YouTube section (ruling 7.10 — no backing data at all)', () {
    testWidgets('is always shown as disconnected, with disabled controls', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeConnectedAccountsRepository(),
      );

      expect(find.text('Beta — not available in this build.'), findsOneWidget);
      // Visible text is enough proof these render; neither has an `onTap`
      // at all (see `youtube_section.dart`'s `_DisabledButton` — there is
      // nothing to tap-test since the control is decorative, not merely
      // gated), so there is no interaction to exercise here.
      expect(find.text('Add account'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
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

        await pumpScreen(
          tester,
          repository: FakeConnectedAccountsRepository(
            accounts: [instagramAccount()],
          ),
          tgChatIds: const [111, 222],
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
