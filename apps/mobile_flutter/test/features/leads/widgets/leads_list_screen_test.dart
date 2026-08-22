// Widget tests for `leads-list` (lib/features/leads/widgets/leads_list_screen.dart).
// Pumped inside a real GoRouter — the header's back control, "+ Add new
// lead" and the view-toggle icon all navigate, same reasoning as
// `saved_listings_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/leads.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/platform/link_launcher.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../../shared/support/fake_link_launcher.dart';
import '../support/fake_leads_repository.dart';
import '../support/lead_fixtures.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeLeadsRepository repository,
    UserRole? role = UserRole.agent,
    // Only the test that actually taps the phone needs one: the real
    // `LinkLauncher` would hit `url_launcher`'s missing plugin under the test
    // binding — same arrangement as `agent_profile_screen_test.dart`.
    LinkLauncher? linkLauncher,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        leadsRepositoryProvider.overrideWithValue(repository),
        if (linkLauncher != null)
          linkLauncherProvider.overrideWithValue(linkLauncher),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    final router = GoRouter(
      initialLocation: RoutePaths.workLeads,
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
          builder: (context, state) => const Scaffold(body: Text('kanban-stub')),
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
    testWidgets('shows the §30 title', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());
      expect(find.text('Leads'), findsOneWidget);
    });

    testWidgets('back with nothing to pop goes to the Work root', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });

    testWidgets('"+ Add new lead" pushes create-lead', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.tap(find.byKey(const ValueKey('leadsList-addLead')));
      await tester.pumpAndSettle();

      expect(find.text('create-lead-stub'), findsOneWidget);
    });

    testWidgets('the view-toggle icon pushes leads-kanban', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.tap(find.byKey(const ValueKey('leadsList-toggleView')));
      await tester.pumpAndSettle();

      expect(find.text('kanban-stub'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('renders every §30 field on a row', (tester) async {
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
        comment: '2-3 room apartment',
        source: 'Instagram',
        status: LeadStatus.needToCallBack,
      );
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: [lead]));

      // §30's row anatomy leads with `#{id}` — Formatters.adIdBadge('lead-1')
      // truncates to its first 5 characters, same rule my-listings' own id
      // badge uses.
      expect(find.text('#lead-'), findsOneWidget);
      expect(find.text('Dilnoza Yusupova'), findsOneWidget);
      expect(find.text('+998901234501'), findsOneWidget);
      expect(find.text('2-3 room apartment'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Need To Call Back'), findsOneWidget);
    });

    testWidgets('tapping a row opens the lead-detail sheet', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: [lead]));

      await tester.tap(find.byKey(const ValueKey('leadRow-lead-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leadDetail-close')), findsOneWidget);
    });

    testWidgets('tapping the phone dials it instead of opening the sheet', (
      tester,
    ) async {
      final launcher = FakeLinkLauncher();
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
      );
      await pumpScreen(
        tester,
        repository: FakeLeadsRepository(leads: [lead]),
        linkLauncher: launcher,
      );

      await tester.tap(find.byKey(const ValueKey('leadRowCall-lead-1')));
      await tester.pumpAndSettle();

      expect(launcher.dialed, ['+998901234501']);
      // The deepest hit-tested recognizer wins, so the row's own tap target
      // never fires for a tap on the phone.
      expect(find.byKey(const ValueKey('leadDetail-close')), findsNothing);
    });

    testWidgets('the phone target announces itself as "Call {phone}"', (
      tester,
    ) async {
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
      );
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: [lead]));

      final target = tester.widget<TapTarget>(
        find.byKey(const ValueKey('leadRowCall-lead-1')),
      );
      expect(target.semanticsLabel, 'Call +998901234501');
    });

    testWidgets('a lead with no phone has no call target at all', (
      tester,
    ) async {
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: null,
      );
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: [lead]));

      expect(find.byKey(const ValueKey('leadRowCall-lead-1')), findsNothing);
      // The row itself still opens the sheet.
      await tester.tap(find.byKey(const ValueKey('leadRow-lead-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('leadDetail-close')), findsOneWidget);
    });

    testWidgets('empty state is §30 copy verbatim', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository(leads: const []));
      expect(find.text('No leads yet.'), findsOneWidget);
    });

    testWidgets('a load failure shows Retry and re-fetches', (tester) async {
      final repo = FakeLeadsRepository(listError: const NetworkException('offline'));
      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your leads."), findsOneWidget);
      expect(repo.listCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.listCallCount, 2);
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
          repository: FakeLeadsRepository(
            leads: [
              makeLead(
                id: 'lead-1',
                fullName: 'Dilnoza Yusupova with a fairly long name',
                comment:
                    '2-3 room apartment, Chilonzor or Yunusobod, near the metro station',
                source: 'Instagram DM referral from a previous client',
                status: LeadStatus.rejected,
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
