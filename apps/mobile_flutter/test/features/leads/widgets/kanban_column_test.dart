// Widget tests for `KanbanColumn` (lib/features/leads/widgets/kanban_column.dart)
// in isolation — no `PageView`, no screen orchestration. This is the direct,
// deterministic way to prove SCREENS.md §5's "spinner overlays only the
// moving card" claim: pumping the full `leads-kanban` screen makes this hard
// to test reliably (`PageView`'s page virtualization means a second,
// non-moving card isn't guaranteed to stay built once the board jumps to a
// different page — see that screen's own spinner-overlay test for why it
// only covers the single-card case).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/widgets/kanban_card.dart';
import 'package:lacasa_mobile/features/leads/widgets/kanban_column.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/lead_fixtures.dart';

void main() {
  // `KanbanCard`'s own `ValueKey('kanbanCard-$id')` sits only on its inner
  // `GestureDetector` — a *sibling* of the conditional spinner inside the
  // same `Stack`, not an ancestor of it. Scoping a descendant search to
  // that key would therefore never find the spinner regardless of
  // `pending`. Scope to the `KanbanCard` widget itself instead, which
  // really is the ancestor of both branches.
  Finder cardFinder(String leadId) => find.byWidgetPredicate(
    (widget) => widget is KanbanCard && widget.lead.id == leadId,
  );

  Future<void> pumpColumn(
    WidgetTester tester, {
    required List<Lead> leads,
    Set<String> pendingLeadIds = const {},
    Set<String> failedLeadIds = const {},
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: KanbanColumn(
            status: LeadStatus.newLead,
            leads: leads,
            pendingLeadIds: pendingLeadIds,
            failedLeadIds: failedLeadIds,
            onCardTap: (_) {},
            onCardLongPress: (_) {},
          ),
        ),
      ),
    );
  }

  group('spinner overlay (SCREENS.md §5 — overlays only the moving card)', () {
    testWidgets('a card in pendingLeadIds shows a spinner', (tester) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpColumn(tester, leads: [lead], pendingLeadIds: {'lead-1'});

      expect(
        find.descendant(of: cardFinder('lead-1'), matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
    });

    testWidgets(
      'a card NOT in pendingLeadIds never shows a spinner, even while a '
      'sibling card in the same column is pending',
      (tester) async {
        final movingLead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
        final otherLead = makeLead(id: 'lead-2', fullName: 'Aziz Karimov');
        await pumpColumn(
          tester,
          leads: [movingLead, otherLead],
          pendingLeadIds: {'lead-1'},
        );

        // Confirms the exclusion check below isn't vacuous — both cards are
        // actually built.
        expect(find.byKey(const ValueKey('kanbanCard-lead-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('kanbanCard-lead-2')), findsOneWidget);

        expect(
          find.descendant(of: cardFinder('lead-1'), matching: find.byType(CircularProgressIndicator)),
          findsOneWidget,
          reason: 'lead-1 is the one in pendingLeadIds',
        );
        expect(
          find.descendant(of: cardFinder('lead-2'), matching: find.byType(CircularProgressIndicator)),
          findsNothing,
          reason:
              'lead-2 is not pending — the spinner must not leak onto a '
              'sibling card in the same column',
        );
      },
    );

    testWidgets('no card shows a spinner when pendingLeadIds is empty', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpColumn(tester, leads: [lead]);

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
