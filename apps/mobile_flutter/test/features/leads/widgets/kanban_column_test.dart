// Widget tests for `KanbanColumn` (lib/features/leads/widgets/kanban_column.dart)
// in isolation — no `PageView`, no screen orchestration. This is the direct,
// deterministic way to prove SCREENS.md §5's "spinner overlays only the
// moving card" claim: pumping the full `leads-kanban` screen makes this hard
// to test reliably (`PageView`'s page virtualization means a second,
// non-moving card isn't guaranteed to stay built once the board jumps to a
// different page — see that screen's own spinner-overlay test for why it
// only covers the single-card case).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/state/coworkers_repository_provider.dart';
import 'package:lacasa_mobile/features/leads/widgets/kanban_card.dart';
import 'package:lacasa_mobile/features/leads/widgets/kanban_column.dart';
import 'package:lacasa_mobile/shared/platform/link_launcher.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../coworkers/support/coworker_test_data.dart';
import '../../coworkers/support/fake_coworkers_repository.dart';
import '../../../shared/support/fake_link_launcher.dart';
import '../support/lead_fixtures.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

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

  // `KanbanCard` is a `ConsumerWidget` now (it watches `coworkersListProvider`
  // for its footer's coworker half — WORK_TAB_CONTRACT.md ruling 7.8), so
  // every pump needs a `ProviderScope` even for cases that never touch a
  // coworker. `coworkers` defaults to empty and `coworkersError`/`coworkersHold`
  // default to unset, matching the fake's own "only what a test actually
  // reaches for" defaults.
  Future<void> pumpColumn(
    WidgetTester tester, {
    required List<Lead> leads,
    LeadStatus status = LeadStatus.newLead,
    Set<String> pendingLeadIds = const {},
    Map<String, LeadStatus> failedDestinations = const {},
    Locale locale = const Locale('en'),
    List<Coworker> coworkers = const [],
    Object? coworkersError,
    Completer<void>? coworkersHold,
    LinkLauncher? linkLauncher,
    List<({Lead lead, LeadStatus destination})>? retries,
  }) {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        coworkersRepositoryProvider.overrideWithValue(
          FakeCoworkersRepository(
            coworkers: coworkers,
            listError: coworkersError,
            hold: coworkersHold,
          ),
        ),
        // `KanbanCard`'s phone line dials through `dialOrCopyPhone`, which
        // reads `linkLauncherProvider`. Left at the real implementation for
        // every test that never taps it — see `agent_profile_screen_test.dart`
        // for the same arrangement.
        if (linkLauncher != null)
          linkLauncherProvider.overrideWithValue(linkLauncher),
      ],
    );
    addTearDown(container.dispose);

    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          theme: AppTheme.light(),
          home: Scaffold(
            body: KanbanColumn(
              status: status,
              leads: leads,
              pendingLeadIds: pendingLeadIds,
              failedDestinations: failedDestinations,
              onCardTap: (_) {},
              onCardLongPress: (_) {},
              onCardRetry: (lead, destination) =>
                  retries?.add((lead: lead, destination: destination)),
            ),
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
        find.descendant(
          of: cardFinder('lead-1'),
          matching: find.byType(CircularProgressIndicator),
        ),
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
          find.descendant(
            of: cardFinder('lead-1'),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
          reason: 'lead-1 is the one in pendingLeadIds',
        );
        expect(
          find.descendant(
            of: cardFinder('lead-2'),
            matching: find.byType(CircularProgressIndicator),
          ),
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

  group('call the lead (SCREENS.md §31 — the phone line is a tap target)', () {
    testWidgets('tapping the phone dials it', (tester) async {
      final launcher = FakeLinkLauncher();
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
      );
      await pumpColumn(tester, leads: [lead], linkLauncher: launcher);

      await tester.tap(find.byKey(const ValueKey('kanbanCardCall-lead-1')));
      await tester.pumpAndSettle();

      expect(launcher.dialed, ['+998901234501']);
    });

    testWidgets('the phone target announces itself as "Call {phone}"', (
      tester,
    ) async {
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
      );
      await pumpColumn(tester, leads: [lead]);

      final target = tester.widget<TapTarget>(
        find.byKey(const ValueKey('kanbanCardCall-lead-1')),
      );
      expect(target.semanticsLabel, 'Call +998901234501');
    });

    testWidgets('an idle card exposes the phone as a labelled button node', (
      tester,
    ) async {
      // Disposed inline rather than via addTearDown — see
      // `tap_target_test.dart` for why `_endOfTestVerifications` forces that.
      final handle = tester.ensureSemantics();
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
      );
      await pumpColumn(tester, leads: [lead]);

      expect(
        tester.getSemantics(
          find.byKey(const ValueKey('kanbanCardCall-lead-1')),
        ),
        isSemantics(
          label: 'Call +998901234501',
          isButton: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets(
      'a pending card still announces the number but stops claiming to be a '
      'button',
      (tester) async {
        final handle = tester.ensureSemantics();
        final lead = makeLead(
          id: 'lead-1',
          fullName: 'Dilnoza Yusupova',
          phone: '+998901234501',
        );
        // Deliberately not settling: the in-flight overlay's
        // `CircularProgressIndicator` never stops animating.
        await pumpColumn(tester, leads: [lead], pendingLeadIds: {'lead-1'});

        // A move in flight mutes the card behind a 55%-alpha overlay and the
        // tap is a no-op — so a screen reader must not still be offered a
        // "Call …" button that does nothing.
        expect(find.semantics.byLabel('Call +998901234501'), findsNothing);
        expect(
          tester.getSemantics(
            find.byKey(const ValueKey('kanbanCardCall-lead-1')),
          ),
          isSemantics(
            label: '+998901234501',
            isButton: false,
            hasTapAction: false,
          ),
          reason:
              'the number is real content and stays readable; only the '
              'button/action claim goes away while the move is in flight',
        );

        handle.dispose();
      },
    );

    testWidgets('a lead with no phone has no call target at all', (
      tester,
    ) async {
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        phone: null,
      );
      await pumpColumn(tester, leads: [lead]);

      expect(find.byKey(const ValueKey('kanbanCardCall-lead-1')), findsNothing);
    });

    testWidgets('a card tap still opens the detail sheet — the phone target '
        'claims only its own line', (tester) async {
      final tapped = <String>[];
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          coworkersRepositoryProvider.overrideWithValue(
            FakeCoworkersRepository(coworkers: const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: Scaffold(
              body: KanbanColumn(
                status: LeadStatus.newLead,
                leads: [lead],
                pendingLeadIds: const {},
                failedDestinations: const {},
                onCardTap: (l) => tapped.add(l.id),
                onCardLongPress: (_) {},
                onCardRetry: (_, _) {},
              ),
            ),
          ),
        ),
      );

      // The card's own title — well clear of the phone's tap box.
      await tester.tap(find.text('Dilnoza Yusupova'));
      await tester.pumpAndSettle();

      expect(tapped, ['lead-1']);
    });
  });

  group('failed move — the Retry row (kanban_move_providers.dart)', () {
    testWidgets('a failed destination renders the tappable Retry row', (
      tester,
    ) async {
      final retries = <({Lead lead, LeadStatus destination})>[];
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpColumn(
        tester,
        leads: [lead],
        failedDestinations: const {'lead-1': LeadStatus.accepted},
        retries: retries,
      );

      expect(find.text("Couldn't move"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('kanbanCardRetry-lead-1')));
      await tester.pumpAndSettle();

      expect(retries.length, 1);
      expect(retries.single.lead.id, 'lead-1');
      expect(
        retries.single.destination,
        LeadStatus.accepted,
        reason:
            'Retry must re-attempt the column the failed move was aiming for, '
            'not the column the card is sitting in',
      );
    });

    testWidgets('the Retry row names its destination for a screen reader', (
      tester,
    ) async {
      final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      await pumpColumn(
        tester,
        leads: [lead],
        failedDestinations: const {'lead-1': LeadStatus.needToCallBack},
      );

      // The ValueKey sits on the private `_MoveFailedRow`; the TapTarget it
      // builds is one level down, so this reads through the keyed row rather
      // than casting it.
      final target = tester.widget<TapTarget>(
        find.descendant(
          of: find.byKey(const ValueKey('kanbanCardRetry-lead-1')),
          matching: find.byType(TapTarget),
        ),
      );
      expect(target.semanticsLabel, 'Retry moving to Need To Call Back');
    });

    testWidgets('a card with no failed entry shows no failure row', (
      tester,
    ) async {
      final failed = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
      final fine = makeLead(id: 'lead-2', fullName: 'Aziz Karimov');
      await pumpColumn(
        tester,
        leads: [failed, fine],
        failedDestinations: const {'lead-1': LeadStatus.rejected},
      );

      expect(
        find.byKey(const ValueKey('kanbanCardRetry-lead-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kanbanCardRetry-lead-2')),
        findsNothing,
        reason: 'the failure row must not leak onto a sibling card',
      );
    });
  });

  group('timezone (SCREENS.md §31 — the call-back pill is a wall clock)', () {
    // `Lead.callbackDate` is decoded by `DateTime.tryParse`, so a `Z`-suffixed
    // wire value carries the UTC flag and `Formatters.date` would read UTC
    // calendar/clock fields straight off it. The expectation is derived rather
    // than hardcoded because a test process's local zone is whatever the
    // machine running it is set to (Dart fixes it at process start; there is
    // no override) — under UTC this assertion is a tautology, but under every
    // other zone, including this app's own UTC+5 market, it fails the moment
    // the `.toLocal()` conversion is dropped.
    testWidgets('the call-back pill renders the instant in local time', (
      tester,
    ) async {
      final due = DateTime.utc(2026, 8, 10, 4);
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        status: LeadStatus.needToCallBack,
        callbackDate: due,
      );
      await pumpColumn(
        tester,
        leads: [lead],
        status: LeadStatus.needToCallBack,
      );

      expect(
        find.text('Call back ${Formatters.date(due.toLocal())}'),
        findsOneWidget,
        reason: 'the raw UTC clock fields must not reach the pill',
      );
    });

    testWidgets('the created-at footer renders the instant in local time', (
      tester,
    ) async {
      const seconds = 1754784000;
      final lead = makeLead(
        id: 'lead-1',
        fullName: 'Dilnoza Yusupova',
        createdAtSeconds: seconds,
      );
      await pumpColumn(tester, leads: [lead]);

      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );
      expect(find.text(Formatters.date(createdAt.toLocal())), findsOneWidget);
    });
  });

  group('coworker footer (WORK_TAB_CONTRACT.md ruling 7.8 — closed)', () {
    testWidgets(
      'a resolved coworkerId renders that coworker\'s name in the footer',
      (tester) async {
        final lead = makeLead(
          id: 'lead-1',
          fullName: 'Dilnoza Yusupova',
          coworkerId: 'coworker-1',
        );
        await pumpColumn(
          tester,
          leads: [lead],
          coworkers: [
            coworker(id: 'coworker-1', fullName: 'Sardor Abdullayev'),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.text('Sardor Abdullayev'), findsOneWidget);
      },
    );

    testWidgets(
      'an empty coworkerId omits the footer slot entirely, even with a '
      'resolved, non-empty roster',
      (tester) async {
        final lead = makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova');
        await pumpColumn(
          tester,
          leads: [lead],
          coworkers: [
            coworker(id: 'coworker-1', fullName: 'Sardor Abdullayev'),
          ],
        );
        await tester.pumpAndSettle();

        // A solo agent's leads always carry an empty `coworkerId` — the
        // roster fetch must never leak a name onto a card that has no real
        // owner to show.
        expect(find.text('Sardor Abdullayev'), findsNothing);
      },
    );

    testWidgets(
      'a loading roster degrades to just the created-at half — no spinner, '
      'no placeholder name',
      (tester) async {
        final hold = Completer<void>();
        final lead = makeLead(
          id: 'lead-1',
          fullName: 'Dilnoza Yusupova',
          coworkerId: 'coworker-1',
        );
        await pumpColumn(
          tester,
          leads: [lead],
          coworkers: [
            coworker(id: 'coworker-1', fullName: 'Sardor Abdullayev'),
          ],
          coworkersHold: hold,
        );
        // Deliberately not `pumpAndSettle` — `hold` never completes here,
        // so settling would hang. One frame is enough to observe the
        // provider's `AsyncLoading` state.
        await tester.pump();

        expect(find.text('Sardor Abdullayev'), findsNothing);
        // The move-in-flight spinner is a distinct, deliberate affordance
        // (SCREENS.md §5) — a still-loading roster must not borrow it.
        expect(find.byType(CircularProgressIndicator), findsNothing);

        hold.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'a failed roster fetch degrades to just the created-at half — no '
      'spinner, no placeholder name, no uncaught exception',
      (tester) async {
        final lead = makeLead(
          id: 'lead-1',
          fullName: 'Dilnoza Yusupova',
          coworkerId: 'coworker-1',
        );
        await pumpColumn(
          tester,
          leads: [lead],
          coworkers: [
            coworker(id: 'coworker-1', fullName: 'Sardor Abdullayev'),
          ],
          coworkersError: const NetworkException('offline'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sardor Abdullayev'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // Promoted from the ad hoc `test/_probe_overflow_test.dart` scratch file:
  // `KanbanColumn`'s header `Row([LeadStatusPill, SizedBox(8), Text(count)])`
  // carries no `Expanded`/`Flexible`, and the ru/uz status labels run
  // genuinely longer than their English originals (e.g. "Need To Call Back"
  // vs. uz "Qayta qo'ng'iroq qilish kerak") — real overflow risk this
  // codebase's other 9 `layout holds…` suites already guard against
  // elsewhere, but leads/kanban never did. The probe itself only `print()`d
  // on exception and never called `expect`, so it could never actually fail
  // CI; the single load-bearing change here is asserting on
  // `tester.takeException()` instead. Each card also carries a lead with a
  // resolved, fairly-long-named coworker in its footer (Part 1 of this same
  // change) — the new content most likely to squeeze this layout at 360px.
  group('layout holds at real phone widths under ru/uz', () {
    for (final locale in const [Locale('ru'), Locale('uz')]) {
      for (final width in const [360.0, 390.0, 430.0]) {
        for (final status in LeadStatus.values.where(
          (s) => s != LeadStatus.unknown,
        )) {
          testWidgets(
            'no overflow for $status at ${width}w (${locale.languageCode})',
            (tester) async {
              tester.view.physicalSize = Size(width, 800);
              tester.view.devicePixelRatio = 1.0;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);

              await pumpColumn(
                tester,
                leads: [
                  makeLead(
                    id: 'lead-1',
                    fullName: 'Test Lead',
                    status: status,
                    coworkerId: 'coworker-1',
                  ),
                ],
                status: status,
                locale: locale,
                coworkers: [
                  coworker(
                    id: 'coworker-1',
                    fullName: 'Coworker With A Fairly Long Full Name',
                  ),
                ],
              );
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  });
}
