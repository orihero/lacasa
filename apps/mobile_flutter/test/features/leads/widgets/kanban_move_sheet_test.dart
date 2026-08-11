// Widget tests for `kanban-move-sheet`
// (lib/features/leads/widgets/kanban_move_sheet.dart). No Riverpod state at
// all — `showKanbanMoveSheet` only needs a Navigator, same shape as
// `filter_sheet_test.dart`'s `showFilterSheet` coverage.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/widgets/kanban_move_sheet.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  Future<void> pumpTrigger(WidgetTester tester, {required LeadStatus destination}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showKanbanMoveSheet(context, destination: destination),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('need_to_call_back — the callback-time gate (§34)', () {
    testWidgets('Save is disabled until a call time is picked', (tester) async {
      await pumpTrigger(tester, destination: LeadStatus.needToCallBack);

      expect(find.text('Enter the next call-back time'), findsOneWidget);

      final saveButton = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('kanbanMoveSheet-save')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(saveButton.onTap, isNull);
    });

    testWidgets('Cancel resolves to null and never calls a mutation', (tester) async {
      LeadWriteInput? result = const LeadWriteInput();
      var resolved = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showKanbanMoveSheet(
                      context,
                      destination: LeadStatus.needToCallBack,
                    );
                    resolved = true;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('kanbanMoveSheet-cancel')));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(result, isNull);
    });

    testWidgets('picking a call time and saving resolves the exact §3.3 contract', (
      tester,
    ) async {
      LeadWriteInput? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showKanbanMoveSheet(
                      context,
                      destination: LeadStatus.needToCallBack,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('kanbanMoveSheet-callTime')));
      await tester.pumpAndSettle();
      // Accept the date picker's default date.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      // Accept the time picker's default time.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('kanbanMoveSheet-save')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.status!.value, LeadStatus.needToCallBack);
      expect(result!.callbackDate, isNotNull);
      // Nothing else per contract §3.3.
      expect(result!.conversationComment, isNull);
      expect(result!.comment, isNull);
    });
  });

  group('rejected/accepted — the ≥10-char note gate (§34)', () {
    testWidgets('a note under 10 characters keeps Save disabled and shows the hint', (
      tester,
    ) async {
      await pumpTrigger(tester, destination: LeadStatus.rejected);

      expect(find.text('Write briefly about the conversation'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('kanbanMoveSheet-note')),
        'too short',
      );
      await tester.pumpAndSettle();

      expect(find.text('At least 10 characters.'), findsOneWidget);
      final saveButton = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(const ValueKey('kanbanMoveSheet-save')),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(saveButton.onTap, isNull);
    });

    testWidgets('a valid note resolves the exact §3.3 contract for Accepted', (
      tester,
    ) async {
      LeadWriteInput? result;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showKanbanMoveSheet(
                      context,
                      destination: LeadStatus.accepted,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('kanbanMoveSheet-note')),
        'Agreed on price, signing next week.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('kanbanMoveSheet-save')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.status!.value, LeadStatus.accepted);
      expect(
        result!.conversationComment!.value,
        'Agreed on price, signing next week.',
      );
      expect(result!.callbackDate, isNull);
    });
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label} — call-time gate', (tester) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpTrigger(tester, destination: LeadStatus.needToCallBack);

        expect(tester.takeException(), isNull);
      });

      testWidgets('no overflow at ${size.label} — note gate', (tester) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpTrigger(tester, destination: LeadStatus.rejected);
        // The under-length hint line adds a row of content only once the
        // note's been touched — cover that taller state too.
        await tester.enterText(
          find.byKey(const ValueKey('kanbanMoveSheet-note')),
          'too short',
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
