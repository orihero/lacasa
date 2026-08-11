// Widget tests for `create-lead` (lib/features/leads/widgets/create_lead_screen.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/leads.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_leads_repository.dart';
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
      initialLocation: RoutePaths.workCreateLead,
      routes: [
        GoRoute(
          path: RoutePaths.workLeads,
          builder: (context, state) => const Scaffold(body: Text('leads-list-stub')),
        ),
        GoRoute(
          path: RoutePaths.workCreateLead,
          builder: (context, state) => const CreateLeadScreen(),
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
    testWidgets('shows the §33 title', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());
      expect(find.text('Create Lead'), findsOneWidget);
    });
  });

  group('validation (§33 exact copy)', () {
    testWidgets('empty required fields block Save', (tester) async {
      final repo = FakeLeadsRepository();
      await pumpScreen(tester, repository: repo);

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(repo.createCallCount, 0);
    });

    testWidgets('an invalid phone shape is rejected', (tester) async {
      final repo = FakeLeadsRepository();
      await pumpScreen(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'Dilnoza');
      await tester.enterText(find.byType(TextField).at(1), '12345');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Uzbekistan phone number'), findsOneWidget);
      expect(repo.createCallCount, 0);
    });
  });

  group('happy path', () {
    testWidgets('a valid submit creates the lead and returns to leads-list', (
      tester,
    ) async {
      final repo = FakeLeadsRepository();
      await pumpScreen(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'Dilnoza Yusupova');
      await tester.enterText(find.byType(TextField).at(1), '+998901234501');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.createCallCount, 1);
      expect(repo.lastCreateInput!.fullName!.value, 'Dilnoza Yusupova');
      expect(repo.lastCreateInput!.phone!.value, '+998901234501');
      expect(repo.lastCreateInput!.status!.value, LeadStatus.newLead);
      expect(find.text('leads-list-stub'), findsOneWidget);
      expect(find.text('Lead successfully created!'), findsOneWidget);
    });

    testWidgets('a failed submit shows the §33 error toast and stays open', (
      tester,
    ) async {
      final repo = FakeLeadsRepository(
        createError: const NetworkException('offline'),
      );
      await pumpScreen(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'Dilnoza Yusupova');
      await tester.enterText(find.byType(TextField).at(1), '+998901234501');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error creating lead:'), findsOneWidget);
      expect(find.text('Create Lead'), findsOneWidget);
    });
  });

  group('discard confirmation (SCREENS.md §5)', () {
    testWidgets('Cancel with no changes leaves immediately, no dialog', (
      tester,
    ) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('leads-list-stub'), findsOneWidget);
    });

    testWidgets('Cancel with unsaved text asks to discard first', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository());

      await tester.enterText(find.byType(TextField).at(0), 'Dilnoza');
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('discardChangesCancel')));
      await tester.pumpAndSettle();
      // Stayed on the form.
      expect(find.text('Create Lead'), findsOneWidget);

      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('discardChangesDiscard')));
      await tester.pumpAndSettle();

      expect(find.text('leads-list-stub'), findsOneWidget);
    });
  });

  group('coworker field — agent only (§33)', () {
    testWidgets('shown for an agent session', (tester) async {
      await pumpScreen(tester, repository: FakeLeadsRepository(), role: UserRole.agent);
      expect(find.text('COWORKER'), findsOneWidget);
    });

    testWidgets('hidden for a coworker session', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeLeadsRepository(),
        role: UserRole.coworker,
      );
      expect(find.text('COWORKER'), findsNothing);
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

        await pumpScreen(tester, repository: FakeLeadsRepository());

        expect(tester.takeException(), isNull);
      });
    }
  });
}
