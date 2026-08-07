// Widget tests for `agent-profile` (lib/features/agents/). The screen is
// pumped inside a real GoRouter, not a bare MaterialApp: its back control
// branches on `context.canPop()` and its ads grid pushes branch-relative
// listing routes, neither of which exists without a router in the tree.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/agents.dart';
import 'package:lacasa_mobile/features/agents/state/agents_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import 'support/agent_test_data.dart';
import 'support/fake_agents_repository.dart';

void main() {
  setUp(() {
    // `Clipboard.setData` goes over SystemChannels.platform, which has no
    // handler in a widget test — the call would throw MissingPluginException
    // before the copy-confirmation snackbar ever shows. Accepting and
    // discarding the call is the standard stand-in; what is under test is
    // the screen's reaction, not the platform's clipboard.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Pumps the profile at `/agents/:id`, with the directory as the route
  /// below it so `canPop()` is true — the ordinary case. A stub listing
  /// route stands in for `listing-detail` so a tap can be observed without
  /// dragging that whole screen (and its own repository) into these tests.
  Future<ProviderContainer> pumpProfile(
    WidgetTester tester, {
    required FakeAgentsRepository repository,
    String agentId = 'agent-a',
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        agentsRepositoryProvider.overrideWithValue(repository),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.agents,
      routes: [
        GoRoute(
          path: RoutePaths.agents,
          builder: (context, state) =>
              const Scaffold(body: Text('directory-root')),
          routes: [
            GoRoute(
              path: 'listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('listing-stub-${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) =>
                  AgentProfileScreen(agentId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (withBackStack) {
      router.push('${RoutePaths.agents}/$agentId');
    } else {
      router.go('${RoutePaths.agents}/$agentId');
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('identity block (SCREENS.md §3.10)', () {
    testWidgets('renders the header and the three labelled rows', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agent: agentDetail(
          id: 'agent-a',
          fullName: 'Javlon Rustamov',
          email: 'javlon@lacasa.uz',
          phoneNumber: '+998901234567',
          adsCount: 24,
          dealsClosedCount: 9,
        ),
      );

      await pumpProfile(tester, repository: repo);

      expect(find.text('Agent Information'), findsOneWidget);

      // The labels are quoted from §3.10 exactly, casing included. RichText
      // splits label and value into spans, so assert on the rendered text.
      final infoText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .toList();
      expect(infoText, contains('Full name: Javlon Rustamov'));
      expect(infoText, contains('E-mail: javlon@lacasa.uz'));
      expect(infoText, contains('Phone: +998901234567'));
    });

    testWidgets('an agent with no phone shows a dash, not a missing row', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agent: agentDetail(
          id: 'agent-a',
          fullName: 'Nodira Alimova',
          phoneNumber: null,
        ),
      );

      await pumpProfile(tester, repository: repo);

      final infoText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .toList();
      expect(infoText, contains('Phone: —'));
    });

    testWidgets('Call copies the number when there is one', (tester) async {
      await pumpProfile(
        tester,
        repository: FakeAgentsRepository(
          agent: agentDetail(
            id: 'agent-a',
            fullName: 'Javlon Rustamov',
            phoneNumber: '+998901234567',
          ),
        ),
      );

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      // The documented stand-in for a `tel:` intent — see
      // `agent_info_block.dart`'s doc comment on why it copies rather than
      // dials.
      expect(
        find.text('Phone number copied: +998901234567'),
        findsOneWidget,
      );
    });

    testWidgets('Call does nothing when the agent has no number', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        repository: FakeAgentsRepository(
          agent: agentDetail(
            id: 'agent-a',
            fullName: 'Nodira Alimova',
            phoneNumber: null,
          ),
        ),
      );

      // Both buttons stay on screen — the row's shape is the same for every
      // agent — but the disabled one has nothing to act on.
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);

      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phone number copied'), findsNothing);
    });
  });

  group('Ads List section', () {
    testWidgets('renders the agent listings with an on-screen count', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agent: agentDetail(
          id: 'agent-a',
          fullName: 'Javlon Rustamov',
          // Deliberately far higher than the two ads below: `adsCount` is an
          // all-time AD_CREATED tally, and the heading must count what is
          // actually on screen rather than repeat it.
          adsCount: 24,
        ),
        ads: [
          agentAd(id: 'ad-1', title: 'Bright two-room near the metro'),
          agentAd(id: 'ad-2', title: 'Quiet corner flat with a balcony'),
        ],
      );

      await pumpProfile(tester, repository: repo);

      expect(find.text('Ads List (2)'), findsOneWidget);
      expect(find.text('Ads List (24)'), findsNothing);
      expect(find.text('Bright two-room near the metro'), findsOneWidget);
      expect(find.text('Quiet corner flat with a balcony'), findsOneWidget);
    });

    testWidgets('no listings shows §3.10 copy verbatim', (tester) async {
      await pumpProfile(
        tester,
        repository: FakeAgentsRepository(
          agent: agentDetail(id: 'agent-a', fullName: 'Javlon Rustamov'),
          ads: const [],
        ),
      );

      expect(find.text('No listings found.'), findsOneWidget);
    });

    testWidgets('tapping a listing pushes it into this branch', (tester) async {
      await pumpProfile(
        tester,
        repository: FakeAgentsRepository(
          agent: agentDetail(id: 'agent-a', fullName: 'Javlon Rustamov'),
          ads: [agentAd(id: 'ad-1', title: 'Bright two-room near the metro')],
        ),
      );

      await tester.tap(find.byKey(const ValueKey('exploreCard-ad-1')));
      await tester.pumpAndSettle();

      // Resolved from branchPrefix — `/agents/listing/ad-1`, not a
      // top-level or Home-branch route.
      expect(find.text('listing-stub-ad-1'), findsOneWidget);
    });
  });

  group('failure isolation — the whole reason for two fetches', () {
    testWidgets('a failed ads fetch leaves the identity block standing', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agent: agentDetail(
          id: 'agent-a',
          fullName: 'Javlon Rustamov',
          email: 'javlon@lacasa.uz',
          phoneNumber: '+998901234567',
        ),
        adsError: const NetworkException('offline'),
      );

      await pumpProfile(tester, repository: repo);

      // The section degrades...
      expect(
        find.text("Couldn't load this agent's listings"),
        findsOneWidget,
      );
      // ...and the contact details the user came for are still there.
      final infoText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((w) => w.text.toPlainText())
          .toList();
      expect(infoText, contains('Phone: +998901234567'));
      expect(find.text('Agent Information'), findsOneWidget);
    });

    testWidgets('Retry on the ads section re-fetches only the ads', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agent: agentDetail(id: 'agent-a', fullName: 'Javlon Rustamov'),
        adsError: const NetworkException('offline'),
      );

      await pumpProfile(tester, repository: repo);

      expect(repo.fetchAgentCallCount, 1);
      expect(repo.fetchAgentAdsCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchAgentAdsCallCount, 2);
      expect(repo.fetchAgentCallCount, 1);
    });
  });

  group('agent fetch failure', () {
    testWidgets('a 404 is a terminal state with no Retry', (tester) async {
      final repo = FakeAgentsRepository(
        agentError: ApiErrorException(
          statusCode: 404,
          body: const ApiErrorBody(
            code: ApiErrorCode.notFound,
            message: 'Agent not found',
          ),
        ),
      );

      await pumpProfile(tester, repository: repo);

      expect(find.text('This agent is no longer available.'), findsOneWidget);
      expect(find.text('Go back'), findsOneWidget);
      // Retrying a 404 asks a question that will never answer differently.
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a transport failure offers Retry and re-fetches', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agentError: const NetworkException('offline'),
      );

      await pumpProfile(tester, repository: repo);

      expect(find.text("Couldn't load this agent"), findsOneWidget);
      expect(repo.fetchAgentCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchAgentCallCount, 2);
    });

    testWidgets('Go back pops to the route below', (tester) async {
      final repo = FakeAgentsRepository(
        agentError: ApiErrorException(
          statusCode: 404,
          body: const ApiErrorBody(
            code: ApiErrorCode.notFound,
            message: 'Agent not found',
          ),
        ),
      );

      await pumpProfile(tester, repository: repo);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();

      expect(find.text('directory-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agent: agentDetail(id: 'agent-a', fullName: 'Javlon Rustamov'),
      );

      // `go` rather than `push`: no back stack, the deep-link case.
      await pumpProfile(tester, repository: repo, withBackStack: false);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      // Falls back to the directory rather than throwing on an empty stack.
      expect(find.text('directory-root'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('shows a skeleton, and the header is up immediately', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakeAgentsRepository(
        hold: gate,
        agent: agentDetail(id: 'agent-a', fullName: 'Javlon Rustamov'),
      );

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          agentsRepositoryProvider.overrideWithValue(repo),
          favouriteAdIdsRepositoryProvider.overrideWithValue(
            FakeFavouriteAdIdsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AgentProfileScreen(agentId: 'agent-a'),
          ),
        ),
      );
      await tester.pump();

      // The title is outside the AsyncValue branch on purpose — a user
      // should know what screen they are on before its content lands.
      expect(find.text('Agent Information'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
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

        await pumpProfile(
          tester,
          repository: FakeAgentsRepository(
            agent: agentDetail(
              id: 'agent-a',
              fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
              email: 'shahnoza.yoldosheva.abdurahmonova@lacasa.uz',
              phoneNumber: '+998901234567',
            ),
            ads: [
              agentAd(id: 'ad-1', title: 'Bright two-room near the metro'),
              agentAd(id: 'ad-2', title: 'Quiet corner flat with a balcony'),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
