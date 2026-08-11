// Widget tests for `leads-kanban` (lib/features/leads/widgets/leads_kanban_screen.dart).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/leads.dart';
import 'package:lacasa_mobile/features/leads/state/kanban_move_providers.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_leads_repository.dart';
import '../support/lead_fixtures.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeLeadsRepository repository,
    UserRole? role = UserRole.agent,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [leadsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    final router = GoRouter(
      initialLocation: RoutePaths.workLeadsKanban,
      routes: [
        GoRoute(
          path: RoutePaths.workLeads,
          builder: (context, state) => const Scaffold(body: Text('leads-list-stub')),
        ),
        GoRoute(
          path: RoutePaths.workLeadsKanban,
          builder: (context, state) => const LeadsKanbanScreen(),
        ),
        GoRoute(
          path: RoutePaths.workCreateLead,
          builder: (context, state) => const Scaffold(body: Text('create-lead-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('header', () {
    testWidgets('shows the §31 title', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());
      expect(find.text('Kanban'), findsOneWidget);
    });

    testWidgets('the view-toggle icon returns to leads-list', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.tap(find.byKey(const ValueKey('leadsKanban-toggleView')));
      await tester.pumpAndSettle();

      expect(find.text('leads-list-stub'), findsOneWidget);
    });

    testWidgets('"+ Add new lead" pushes create-lead', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.tap(find.byKey(const ValueKey('leadsKanban-addLead')));
      await tester.pumpAndSettle();

      expect(find.text('create-lead-stub'), findsOneWidget);
    });
  });

  group('columns', () {
    testWidgets('the New column shows its card by default', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: [lead]));

      expect(find.byKey(const ValueKey('kanbanCard-lead-1')), findsOneWidget);
      expect(find.text('Dilnoza Yusupova'), findsOneWidget);
    });

    testWidgets('empty board shows the §30 empty copy', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: const []));
      expect(find.text('No leads yet.'), findsOneWidget);
    });

    testWidgets('tapping a card opens the lead-detail sheet', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: [lead]));

      await tester.tap(find.byKey(const ValueKey('kanbanCard-lead-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leadDetail-close')), findsOneWidget);
    });
  });

  group('move — immediate columns (SCREENS.md §31/§5)', () {
    testWidgets(
      'long-press → "Move to…" → Could Not Connect moves without a gate sheet',
      (tester) async {
        final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
        final repo = FakeLeadsRepository(leads: [lead]);
        await pumpScreen(tester, repository: repo);

        await tester.longPress(find.byKey(const ValueKey('kanbanCard-lead-1')));
        await tester.pumpAndSettle();

        expect(find.text('Move to…'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('moveToSheet-could_not_connect')));
        await tester.pumpAndSettle();

        expect(repo.updateCallCount, 1);
        expect(
          repo.lastUpdateInput!.status!.value,
          LeadStatus.couldNotConnect,
        );
        // No gate sheet ever appeared for this destination.
        expect(find.byKey(const ValueKey('kanbanMoveSheet-save')), findsNothing);
      },
    );
  });

  group('move — gated columns (SCREENS.md §31/§34)', () {
    testWidgets('moving into Need To Call Back opens kanban-move-sheet first', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(leads: [lead]);
      await pumpScreen(tester, repository: repo);

      await tester.longPress(find.byKey(const ValueKey('kanbanCard-lead-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('moveToSheet-need_to_call_back')));
      await tester.pumpAndSettle();

      expect(find.text('Enter the next call-back time'), findsOneWidget);
      // Cancelling the gate sheet must not move the card.
      await tester.tap(find.byKey(const ValueKey('kanbanMoveSheet-cancel')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 0);
    });

    testWidgets('a failed move clears the override and leaves the failed-card note', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(
        leads: [lead],
        updateError: const NetworkException('offline'),
      );
      final container = await pumpScreen(tester, repository: repo);

      await tester.longPress(find.byKey(const ValueKey('kanbanCard-lead-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('moveToSheet-could_not_connect')));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't move — try again."), findsOneWidget);
      expect(repo.updateCallCount, 1);

      // The DOM-only assertion above can't distinguish "the card is stuck
      // in the destination column" from "it correctly bounced back to New"
      // — `PageView`'s cache extent keeps the adjacent column's subtree
      // built (and therefore findable by `find.text`) regardless of which
      // page is actually in view. Assert directly on `KanbanMoveState`
      // instead: a regression that stopped clearing the override on
      // failure (contract ruling 7.5) would leave `overrides` non-empty
      // here even though this DOM check alone would still pass.
      final moveState = container.read(kanbanMoveProvider);
      expect(
        moveState.overrides,
        isEmpty,
        reason: 'a failed move must clear its optimistic override',
      );
      expect(moveState.failed, contains('lead-1'));
      expect(moveState.displayStatus(lead), LeadStatus.newLead);
    });
  });

  group('spinner overlay (SCREENS.md §5 — overlays only the moving card)', () {
    testWidgets('shows a spinner on the card while the move is in flight', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final gate = Completer<void>();
      final repo = FakeLeadsRepository(leads: [lead], updateHold: gate);
      await pumpScreen(tester, repository: repo);

      await tester.longPress(find.byKey(const ValueKey('kanbanCard-lead-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('moveToSheet-could_not_connect')));
      // Deliberately not `pumpAndSettle`: the spinner is a continuously
      // animating `CircularProgressIndicator`, so settling while `gate` is
      // still open would hang — same reasoning as
      // `saved_listings_screen_test.dart`'s shimmer-loading test. The first,
      // untimed pump lets the "Move to…" sheet's pop-future resolve and lets
      // `_attemptMove` start the screen's own jump to the destination
      // column — a *second* `AnimationController`, created mid-frame off
      // that resolved future, which only starts ticking on the *next*
      // `handleBeginFrame`. The second, timed pump is what actually drives
      // that jump's animation (260ms — see `_jumpToColumn`) to completion,
      // landing the moved (and now-pending) card on screen.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
    });

    // The exclusivity this group's title claims ("overlays only the moving
    // card") is genuinely untestable through the full screen above: with
    // only one card in that fixture, `findsWidgets` passes identically
    // whether the spinner is correctly scoped to the moving card or a
    // regression made every card in the column show it, and `PageView`'s
    // page virtualization makes a second, reliably-findable card hard to
    // guarantee through the real long-press → jump → pending flow. See
    // `kanban_column_test.dart` for the direct, deterministic version of
    // this exclusivity check, pumping `KanbanColumn` in isolation instead.
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
          repository: FakeLeadsRepository(
            leads: [
              makeLead(
                id: 'lead-1',
                fullName: 'Dilnoza Yusupova with a fairly long name',
                comment: '2-3 room apartment, Chilonzor or Yunusobod',
                status: LeadStatus.needToCallBack,
                callbackDate: DateTime(2026, 8, 10, 15),
              ),
              makeLead(id: 'lead-2', fullName: 'Aziz Karimov'),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
