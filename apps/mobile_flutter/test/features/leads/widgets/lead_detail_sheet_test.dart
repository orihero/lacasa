// Widget tests for `lead-detail` (lib/features/leads/widgets/lead_detail_sheet.dart).
// `showLeadDetailSheet` needs only a Navigator, not a GoRouter — pumped
// behind a plain trigger button, same shape as `contact_sheet_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/leads.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_leads_repository.dart';
import '../support/lead_fixtures.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpSheet(
    WidgetTester tester, {
    required FakeLeadsRepository repository,
    required String leadId,
    UserRole? role = UserRole.agent,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [leadsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showLeadDetailSheet(context, leadId: leadId),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return container;
  }

  group('happy path', () {
    testWidgets('pre-fills every §32 field', (tester) async {
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
        email: 'dilnoza@example.com',
        budget: 50000,
        comment: '2-3 room apartment',
        status: LeadStatus.newLead,
        source: 'Instagram',
      );
      await pumpSheet(
        tester,
        repository: FakeLeadsRepository(leads: [lead]),
        leadId: 'lead-1',
      );

      expect(find.widgetWithText(TextField, 'Dilnoza Yusupova'), findsOneWidget);
      expect(find.widgetWithText(TextField, '+998901234501'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'dilnoza@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextField, '50000'), findsOneWidget);
      expect(find.widgetWithText(TextField, '2-3 room apartment'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Instagram'), findsOneWidget);
    });

    testWidgets('Save persists edits and shows the §32 success toast', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(leads: [lead]);
      await pumpSheet(tester, repository: repo, leadId: 'lead-1');

      await tester.enterText(
        find.widgetWithText(TextField, 'Dilnoza Yusupova'),
        'Dilnoza Y.',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('leadDetail-save')));
      await tester.tap(find.byKey(const ValueKey('leadDetail-save')));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
      expect(repo.lastUpdateInput!.fullName!.value, 'Dilnoza Y.');
      expect(find.text('Lead successfully updated!'), findsOneWidget);
      // The sheet itself closed.
      expect(find.byKey(const ValueKey('leadDetail-close')), findsNothing);
    });

    testWidgets('choosing Need To Call Back reveals the Call time field', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpSheet(
        tester,
        repository: FakeLeadsRepository(leads: [lead]),
        leadId: 'lead-1',
      );

      expect(find.byKey(const ValueKey('leadDetail-callTime')), findsNothing);

      await tester.ensureVisible(
        find.byKey(const ValueKey('leadStatus-need_to_call_back')),
      );
      await tester.tap(find.byKey(const ValueKey('leadStatus-need_to_call_back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('leadDetail-callTime')), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('an empty Full name blocks Save', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(leads: [lead]);
      await pumpSheet(tester, repository: repo, leadId: 'lead-1');

      await tester.enterText(
        find.widgetWithText(TextField, 'Dilnoza Yusupova'),
        '',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('leadDetail-save')));
      await tester.tap(find.byKey(const ValueKey('leadDetail-save')));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(repo.updateCallCount, 0);
    });

    testWidgets('an invalid phone blocks Save', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(leads: [lead]);
      await pumpSheet(tester, repository: repo, leadId: 'lead-1');

      await tester.enterText(
        find.widgetWithText(TextField, '+998901234501'),
        '12345',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('leadDetail-save')));
      await tester.tap(find.byKey(const ValueKey('leadDetail-save')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Uzbekistan phone number'), findsOneWidget);
      expect(repo.updateCallCount, 0);
    });
  });

  group('error state', () {
    testWidgets('a failed Save shows the §32 error toast and stays open', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(
        leads: [lead],
        updateError: const NetworkException('offline'),
      );
      await pumpSheet(tester, repository: repo, leadId: 'lead-1');

      await tester.ensureVisible(find.byKey(const ValueKey('leadDetail-save')));
      await tester.tap(find.byKey(const ValueKey('leadDetail-save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Error updating lead:'), findsOneWidget);
      expect(find.byKey(const ValueKey('leadDetail-close')), findsOneWidget);
    });
  });

  group('delete — AGENT only (§32, §38)', () {
    testWidgets('an agent sees Delete, confirms, and it deletes', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final repo = FakeLeadsRepository(leads: [lead]);
      await pumpSheet(tester, repository: repo, leadId: 'lead-1', role: UserRole.agent);

      expect(find.byKey(const ValueKey('leadDetail-delete')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('leadDetail-delete')));
      await tester.tap(find.byKey(const ValueKey('leadDetail-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete lead?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('deleteConfirmDelete')));
      await tester.pumpAndSettle();

      expect(repo.deleteCallCount, 1);
      expect(repo.lastDeletedId, 'lead-1');
      expect(find.text('Lead successfully deleted!'), findsOneWidget);
    });

    testWidgets('a coworker never sees Delete or the Coworker field', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpSheet(
        tester,
        repository: FakeLeadsRepository(leads: [lead]),
        leadId: 'lead-1',
        role: UserRole.coworker,
      );

      expect(find.byKey(const ValueKey('leadDetail-delete')), findsNothing);
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

        final lead = makeLead(
          id: 'lead-1',
          fullName: 'Dilnoza Yusupova with a fairly long full name',
          comment: '2-3 room apartment, Chilonzor or Yunusobod near the metro',
          status: LeadStatus.needToCallBack,
          callbackDate: DateTime(2026, 8, 10, 15),
        );
        await pumpSheet(
          tester,
          repository: FakeLeadsRepository(leads: [lead]),
          leadId: 'lead-1',
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
