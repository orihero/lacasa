// UX audit §9.3 — "nothing refreshes: no pull-to-refresh on the feed,
// search, or any CRM list", for the two views of `leadsProvider`.
//
// Leads are team-wide: a lead a coworker takes by phone, or one entered in
// the web console, is a row this agent is expected to act on. `leadsProvider`
// is a plain, non-autoDispose provider, so once it has loaded it is never
// rebuilt — tab switches keep it, backgrounding keeps it, and the only other
// `ref.invalidate(leadsProvider)` in the feature is the Retry button on the
// error state, which never renders while the list is merely stale. Until the
// process was killed, that coworker's lead did not exist.
//
// Both views are covered because they are one toggle tap apart over one
// provider, and each needs the gesture wired differently: `leads-list` pulls
// on its own `ListView`, while `leads-kanban`'s vertical scrollers sit
// *inside* a horizontal `PageView`, one `Scrollable` deeper than the default
// `RefreshIndicator` predicate accepts. The empty-state cases matter most of
// all — a board reading "No leads yet." is exactly when someone reaches for
// a refresh, and a state with nothing to scroll gives the indicator no
// notification to arm from unless it is made scrollable on purpose.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/leads.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_leads_repository.dart';
import '../support/lead_fixtures.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeLeadsRepository repository,
    required bool kanban,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [leadsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(UserRole.agent);

    final router = GoRouter(
      initialLocation: kanban
          ? RoutePaths.workLeadsKanban
          : RoutePaths.workLeads,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
        ),
        GoRoute(
          path: RoutePaths.workLeads,
          builder: (context, state) => const LeadsListScreen(),
        ),
        GoRoute(
          path: RoutePaths.workLeadsKanban,
          builder: (context, state) => const LeadsKanbanScreen(),
        ),
        GoRoute(
          path: RoutePaths.workCreateLead,
          builder: (context, state) =>
              const Scaffold(body: Text('create-lead-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

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
  }

  /// The scroll → spin → hide sequence Flutter's own `RefreshIndicator`
  /// tests use. Deliberately not `pumpAndSettle`: the leads screens mount
  /// `ShimmerBox`, whose animation repeats forever, so a settle can only be
  /// used on a frame where none is on screen.
  Future<void> pullFrom(WidgetTester tester, Finder target) async {
    await tester.fling(target, const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // scroll animation
    await tester.pump(const Duration(seconds: 1)); // indicator settle
    await tester.pump(const Duration(seconds: 1)); // indicator hide
  }

  List<Lead> manyLeads(int count) => [
    for (var i = 0; i < count; i++)
      makeLead(id: 'lead-$i', fullName: 'Lead number $i'),
  ];

  group('leads-list', () {
    testWidgets('carries a pull-to-refresh indicator', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeLeadsRepository(leads: manyLeads(2)),
        kanban: false,
      );

      expect(find.byKey(const ValueKey('leadsList-refresh')), findsOneWidget);
    });

    testWidgets('a pull re-requests the leads', (tester) async {
      final repository = FakeLeadsRepository(leads: manyLeads(2));
      await pumpScreen(tester, repository: repository, kanban: false);
      expect(repository.listCallCount, 1);

      // Two rows do not fill a phone. The list carries
      // `AlwaysScrollableScrollPhysics` precisely so a short list still
      // accepts the drag — under the default physics a viewport with no
      // scroll extent refuses one outright, and a two-lead team would have
      // had no way to refresh at all.
      await pullFrom(tester, find.byType(ListView));

      expect(repository.listCallCount, 2);
    });

    testWidgets('a pull works on the empty state too', (tester) async {
      final repository = FakeLeadsRepository();
      await pumpScreen(tester, repository: repository, kanban: false);

      expect(find.byType(RefreshableFill), findsOneWidget);
      expect(repository.listCallCount, 1);

      await pullFrom(tester, find.byType(RefreshableFill));

      // The whole point: "No leads yet." is the screen a stale team-wide
      // list looks exactly like.
      expect(repository.listCallCount, 2);
    });

    testWidgets('a pull works on the error state too', (tester) async {
      final repository = FakeLeadsRepository(
        listError: const NetworkException('offline'),
      );
      await pumpScreen(tester, repository: repository, kanban: false);
      expect(repository.listCallCount, 1);

      await pullFrom(tester, find.byType(RefreshableFill));

      expect(repository.listCallCount, 2);
    });
  });

  group('leads-kanban', () {
    testWidgets('carries a pull-to-refresh indicator', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeLeadsRepository(leads: manyLeads(2)),
        kanban: true,
      );

      expect(find.byKey(const ValueKey('leadsKanban-refresh')), findsOneWidget);
    });

    testWidgets('a pull inside a column re-requests the leads', (tester) async {
      // Enough cards for the New column to actually scroll: the per-column
      // `ListView` lives in `kanban_column.dart` and takes the default
      // physics, so a short column has no scroll extent to drag from.
      final repository = FakeLeadsRepository(leads: manyLeads(12));
      await pumpScreen(tester, repository: repository, kanban: true);
      expect(repository.listCallCount, 1);

      // Dragging a *card* — i.e. inside the column's own vertical ListView,
      // which sits one Scrollable below the horizontal PageView. This is the
      // case the widened `notificationPredicate` exists for; with the
      // default `depth == 0` predicate every notification from here is
      // discarded and the indicator never arms.
      await pullFrom(tester, find.byKey(const ValueKey('kanbanCard-lead-0')));

      expect(repository.listCallCount, 2);
    });

    testWidgets('a pull works on the empty board too', (tester) async {
      final repository = FakeLeadsRepository();
      await pumpScreen(tester, repository: repository, kanban: true);

      expect(find.byType(RefreshableFill), findsOneWidget);
      expect(repository.listCallCount, 1);

      await pullFrom(tester, find.byType(RefreshableFill));

      expect(repository.listCallCount, 2);
    });
  });
}
