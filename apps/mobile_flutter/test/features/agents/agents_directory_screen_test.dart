// Widget tests for `agents-directory` (lib/features/agents/). Each test
// pumps AgentsDirectoryScreen inside a themed MaterialApp + ProviderScope
// with agentsRepositoryProvider overridden to a FakeAgentsRepository — no
// network, no dependency on the bundled fixtures staying unchanged.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/agents.dart';
import 'package:lacasa_mobile/features/agents/state/agents_repository_provider.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/agent_test_data.dart';
import 'support/fake_agents_repository.dart';

void main() {
  Future<ProviderContainer> pumpDirectory(
    WidgetTester tester, {
    required FakeAgentsRepository repository,
  }) async {
    final container = ProviderContainer(
      // Riverpod 3 auto-retries a thrown Exception with exponential
      // backoff; pumpAndSettle would let several of those fire and make
      // call-count assertions non-deterministic. Same override
      // home_feed_screen_test.dart uses, for the same reason.
      retry: (retryCount, error) => null,
      overrides: [agentsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AgentsDirectoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('happy path', () {
    testWidgets('renders one card per agent with name, phone, email and count', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agents: [
          agentSummary(
            id: 'agent-javlon',
            fullName: 'Javlon Rustamov',
            phoneNumber: '+998901234567',
            email: 'javlon@lacasa.uz',
            adsCount: 24,
          ),
          agentSummary(
            id: 'agent-otabek',
            fullName: 'Otabek Yusupov',
            phoneNumber: '+998935558899',
            email: 'otabek@lacasa.uz',
            adsCount: 31,
          ),
        ],
      );

      await pumpDirectory(tester, repository: repo);

      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Javlon Rustamov'), findsOneWidget);
      expect(find.text('Otabek Yusupov'), findsOneWidget);
      expect(find.text('+998901234567'), findsOneWidget);
      expect(find.text('javlon@lacasa.uz'), findsOneWidget);

      // SCREENS.md §3.9's "Ads: {adsCount}" label, quoted exactly.
      expect(find.text('Ads: 24'), findsOneWidget);
      expect(find.text('Ads: 31'), findsOneWidget);
    });

    testWidgets('a card with no phone number still renders its other fields', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agents: [
          agentSummary(
            id: 'agent-a',
            fullName: 'Nodira Alimova',
            phoneNumber: null,
            adsCount: 4,
          ),
        ],
      );

      await pumpDirectory(tester, repository: repo);

      expect(find.text('Nodira Alimova'), findsOneWidget);
      expect(find.text('agent-a@lacasa.uz'), findsOneWidget);
      expect(find.text('Ads: 4'), findsOneWidget);
    });

    testWidgets('each card is individually tappable via its keyed widget', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agents: [
          agentSummary(id: 'agent-a', fullName: 'A One', adsCount: 1),
          agentSummary(id: 'agent-b', fullName: 'B Two', adsCount: 2),
        ],
      );

      await pumpDirectory(tester, repository: repo);

      expect(find.byKey(const ValueKey('agentCard-agent-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('agentCard-agent-b')), findsOneWidget);
    });
  });

  group('empty and error states', () {
    testWidgets('empty list shows §3.9 copy verbatim', (tester) async {
      await pumpDirectory(
        tester,
        repository: FakeAgentsRepository(agents: const []),
      );

      // Quoted from the spec, full stop included — not paraphrased.
      expect(find.text('No agents found.'), findsOneWidget);
    });

    testWidgets('a failed fetch shows a retry, and Retry re-fetches', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        agentsError: const NetworkException('offline'),
      );

      await pumpDirectory(tester, repository: repo);

      expect(find.text("Couldn't load agents"), findsOneWidget);
      expect(repo.fetchAgentsCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchAgentsCallCount, 2);
    });

    testWidgets('the error state does not render the empty-state copy', (
      tester,
    ) async {
      await pumpDirectory(
        tester,
        repository: FakeAgentsRepository(
          agentsError: const NetworkException('offline'),
        ),
      );

      // A failure and "there are genuinely no agents" are different claims;
      // the screen must never make the second one on the first's behalf.
      expect(find.text('No agents found.'), findsNothing);
    });
  });

  group('loading', () {
    testWidgets('shows skeletons before the fetch resolves', (tester) async {
      // Held open so the loading branch is actually on screen to assert
      // against — see FakeAgentsRepository.hold.
      final gate = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsRepositoryProvider.overrideWithValue(
              FakeAgentsRepository(
                hold: gate,
                agents: [
                  agentSummary(id: 'agent-a', fullName: 'A One', adsCount: 1),
                ],
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const AgentsDirectoryScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(ShimmerBox), findsWidgets);
      expect(find.text('A One'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('A One'), findsOneWidget);
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

        await pumpDirectory(
          tester,
          repository: FakeAgentsRepository(
            agents: [
              // A deliberately long email and name — the two fields most
              // likely to blow a fixed-width row.
              agentSummary(
                id: 'agent-long',
                fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
                phoneNumber: '+998901234567',
                email: 'shahnoza.yoldosheva.abdurahmonova@lacasa.uz',
                adsCount: 128,
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
