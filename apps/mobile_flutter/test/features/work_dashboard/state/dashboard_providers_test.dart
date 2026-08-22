// Tests for the dashboard's six `AsyncNotifierProvider`s' session-awareness
// (lib/features/work_dashboard/state/dashboard_providers.dart) — finding
// M5's provider half. Pure `ProviderContainer` tests, same shape as
// `test/features/leads/state/leads_providers_test.dart`'s own
// `dashboardLeadsProvider`-invalidation group: no widget pump needed since
// nothing here is UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_providers.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';

import '../support/dashboard_test_data.dart';
import '../support/fake_dashboard_repository.dart';

AuthUser _agent(String id) => AuthUser.fromJson({
  'id': id,
  'fullName': 'Agent $id',
  'email': '$id@lacasa.uz',
  'role': 'agent',
  'phoneNumber': null,
  'avatar': null,
  'agentId': null,
  'tgChatIds': <int>[],
  'igAccounts': <Map<String, dynamic>>[],
  'igAssistConsentAt': null,
  'realtor': null,
});

void main() {
  group('countActiveLeads (SCREENS.md §24 "Active leads")', () {
    test(
      'counts every non-terminal status, excludes rejected and accepted',
      () {
        final leads = [
          testLead(id: 'l-1'), // new
          testLead(id: 'l-2', status: 'could_not_connect'),
          testLead(id: 'l-3', status: 'need_to_call_back'),
          testLead(id: 'l-4', status: 'rejected'),
          testLead(id: 'l-5', status: 'accepted'),
        ];

        expect(
          countActiveLeads(leads),
          3,
          reason:
              'rejected and accepted are the two closed-conversation Kanban '
              'outcomes — a won deal is no more an open lead than a lost one',
        );
      },
    );

    test('excludes archived leads even when their status is still open', () {
      final leads = [
        testLead(id: 'l-1'),
        testLead(id: 'l-2', active: false),
        testLead(id: 'l-3', status: 'need_to_call_back', active: false),
      ];

      expect(countActiveLeads(leads), 1);
    });

    test('an unrecognized server status still counts — hiding a live lead is '
        'the worse failure than showing one this build cannot label', () {
      expect(
        countActiveLeads([testLead(id: 'l-1', status: 'some_future_status')]),
        1,
      );
    });

    test('a table of nothing but dead leads counts zero, not its length', () {
      final leads = [
        testLead(id: 'l-1', status: 'rejected'),
        testLead(id: 'l-2', status: 'rejected'),
        testLead(id: 'l-3', status: 'accepted'),
        testLead(id: 'l-4', active: false),
      ];

      expect(countActiveLeads(leads), 0);
      expect(
        leads.length,
        4,
        reason: 'the raw table size is what used to show',
      );
    });
  });

  group('countCallbacksDueToday is a subset of countActiveLeads — the tile and '
      'its own subtitle can never contradict each other', () {
    // The overdue-by-decades date every case below uses: `callbackDate` is
    // a plain ISO string on the wire (see `Lead`'s own doc comment), and
    // anything not after end-of-today counts as due.
    const overdue = '2000-01-01T00:00:00.000Z';

    const statuses = [
      'new',
      'could_not_connect',
      'need_to_call_back',
      'rejected',
      'accepted',
      'some_future_status',
    ];

    test('the subtitle never claims more callbacks than the value above it, '
        'for every status × archived × callback-date combination', () {
      var combinations = 0;
      for (final status in statuses) {
        for (final active in const [true, false]) {
          for (final callbackIso in const [overdue, null]) {
            final leads = [
              testLead(
                id: 'l-1',
                status: status,
                active: active,
                callbackIso: callbackIso,
              ),
            ];
            combinations++;

            expect(
              countCallbacksDueToday(leads),
              lessThanOrEqualTo(countActiveLeads(leads)),
              reason:
                  'status=$status active=$active callback=$callbackIso '
                  'renders as "${countActiveLeads(leads)}" over the '
                  'subtitle "${countCallbacksDueToday(leads)} need a '
                  'call back" — a subtitle larger than its own value is '
                  'the tile contradicting itself on screen',
            );
          }
        }
      }

      expect(
        combinations,
        statuses.length * 4,
        reason: 'every combination must actually have been exercised',
      );
    });

    test('one closed lead nobody cleared the callback date off renders as '
        '0 over 0, not 0 over 1', () {
      // The exact production shape the shared predicate exists to make
      // unrepresentable: `kanban-move-sheet` never blanks `callbackDate`
      // when a lead moves to `rejected`, so a stale date on a closed
      // lead is the normal end state, not a corrupt row.
      final leads = [
        testLead(id: 'l-1', status: 'rejected', callbackIso: overdue),
        testLead(id: 'l-2', active: false, callbackIso: overdue),
      ];

      expect(countActiveLeads(leads), 0);
      expect(
        countCallbacksDueToday(leads),
        0,
        reason:
            'a callback on an archived or closed lead is not a call '
            'anyone has to make',
      );
    });

    test('callbacks on leads that are still open still count — the gate '
        'narrows the population, it does not zero the number', () {
      final leads = [
        testLead(id: 'l-1', status: 'need_to_call_back', callbackIso: overdue),
        testLead(id: 'l-2'), // open, no callback date
        testLead(id: 'l-3', status: 'accepted', callbackIso: overdue),
      ];

      expect(countActiveLeads(leads), 2);
      expect(countCallbacksDueToday(leads), 1);
    });
  });

  group('isWithinTimeRange reads the local calendar day, not the UTC one the '
      'wire decode hands back', () {
    // `dateTimeFromWireTimestamp` builds every `Lead.createdAt` with
    // `isUtc: true`, so reading `.year`/`.month`/`.day` off it straight
    // compares UTC fields against a local "now" — an off-by-one-day for
    // every user outside UTC, and this app's market (UTC+5) is one of
    // them. Asserting both ends of the local day makes the test
    // zone-independent: east of UTC the 00:30 case crosses back over the
    // date line once encoded, west of it the 23:30 case crosses forward.
    for (final at in const [(hour: 0, minute: 30), (hour: 23, minute: 30)]) {
      test('a lead created at ${at.hour}:${at.minute} local today is inside '
          'Today and This month', () {
        final lead = testLead(
          id: 'l-1',
          createdAt: todayAtLocal(at.hour, at.minute),
        );

        expect(
          lead.createdAt.isUtc,
          isTrue,
          reason:
              'the whole point of this test is that the decoded value '
              'is UTC — if that ever stops being true, re-derive the '
              'predicate rather than deleting this case',
        );
        expect(
          isWithinTimeRange(lead.createdAt, StatisticsFilter.today),
          isTrue,
        );
        expect(
          isWithinTimeRange(lead.createdAt, StatisticsFilter.thisMonth),
          isTrue,
        );
      });
    }

    test(
      'the Leads column counts an early-morning-local lead under "Today"',
      () async {
        const coworker = Coworker(
          id: 'cw-1',
          fullName: 'Sardor Abdullayev',
          email: 'sardor@lacasa.uz',
          phoneNumber: null,
          avatar: null,
          agentId: 'agent-1',
        );
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            dashboardRepositoryProvider.overrideWithValue(
              FakeDashboardRepository(
                coworkers: const [coworker],
                leads: [
                  testLead(
                    id: 'l-early',
                    coworkerId: 'cw-1',
                    createdAt: todayAtLocal(0, 30),
                  ),
                  testLead(
                    id: 'l-late',
                    coworkerId: 'cw-1',
                    createdAt: todayAtLocal(23, 30),
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(dashboardCoworkersProvider.future);
        await container.read(dashboardLeadsProvider.future);

        container
            .read(dashboardTimeRangeProvider.notifier)
            .select(StatisticsFilter.today);

        expect(
          container.read(coworkerStatRowsProvider).value!.single.leadCount,
          2,
          reason:
              'a lead taken at 03:00 in Tashkent is work done today, not '
              'work done last month because 22:00Z says so',
        );
      },
    );
  });

  group('coworkerStatRowsProvider lead column', () {
    test('leadCount honours the selected time range, exactly like adsCount '
        'and saleCount beside it', () async {
      const coworker = Coworker(
        id: 'cw-1',
        fullName: 'Sardor Abdullayev',
        email: 'sardor@lacasa.uz',
        phoneNumber: null,
        avatar: null,
        agentId: 'agent-1',
      );
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(
            FakeDashboardRepository(
              coworkers: const [coworker],
              leads: [
                // Two leads dated today (the `testLead` default, a plain
                // local `DateTime.now()` — see its doc comment for why the
                // old zone-hedged constant was removed) fall
                // inside every range; three dated years back fall inside
                // "All" alone. Anchoring on today-vs-long-ago rather than
                // on adjacent days keeps the expected numbers the same at
                // every wall-clock instant the suite might run at.
                testLead(id: 'l-1', coworkerId: 'cw-1'),
                testLead(id: 'l-2', coworkerId: 'cw-1'),
                testLead(
                  id: 'l-3',
                  coworkerId: 'cw-1',
                  createdAt: DateTime(2020, 5, 4),
                ),
                testLead(
                  id: 'l-4',
                  coworkerId: 'cw-1',
                  createdAt: DateTime(2020, 5, 5),
                ),
                testLead(
                  id: 'l-5',
                  coworkerId: 'cw-1',
                  createdAt: DateTime(2020, 5, 6),
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardCoworkersProvider.future);
      await container.read(dashboardLeadsProvider.future);

      expect(
        container.read(coworkerStatRowsProvider).value!.single.leadCount,
        2,
        reason: 'the default "This month" range must exclude the 2020 leads',
      );

      container
          .read(dashboardTimeRangeProvider.notifier)
          .select(StatisticsFilter.all);

      expect(
        container.read(coworkerStatRowsProvider).value!.single.leadCount,
        5,
      );

      container
          .read(dashboardTimeRangeProvider.notifier)
          .select(StatisticsFilter.today);

      expect(
        container.read(coworkerStatRowsProvider).value!.single.leadCount,
        2,
      );
    });
  });

  group('every dashboard AsyncNotifier goes stale-aware on sign-out/sign-in '
      '(finding M5 — `dashboard` stays mounted for the whole Work-tab session '
      'and none of these six providers is `.autoDispose`, so nothing else '
      'tore them down across a session change before this fix)', () {
    test(
      'signing in as a different account (same role) refetches all six',
      () async {
        final repo = FakeDashboardRepository();
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        container.read(authSessionProvider.notifier).signIn(_agent('agent-a'));
        await container.read(adsStatisticsProvider.future);
        await container.read(adsSeriesProvider.future);
        await container.read(dashboardLeadsProvider.future);
        await container.read(dashboardCoworkersProvider.future);
        await container.read(dashboardAdsProvider.future);
        await container.read(dashboardCoworkerActivityProvider.future);

        expect(repo.adsStatisticsCallCount, 1);
        expect(repo.adsSeriesCallCount, 1);
        expect(repo.leadsCallCount, 1);
        expect(repo.coworkersCallCount, 1);
        expect(repo.adsCallCount, 1);

        // A second account sharing the exact same role — the case the
        // router's own redirect guard can't distinguish by role alone,
        // per this file's own doc comment.
        container.read(authSessionProvider.notifier).signIn(_agent('agent-b'));
        await container.read(adsStatisticsProvider.future);
        await container.read(adsSeriesProvider.future);
        await container.read(dashboardLeadsProvider.future);
        await container.read(dashboardCoworkersProvider.future);
        await container.read(dashboardAdsProvider.future);
        await container.read(dashboardCoworkerActivityProvider.future);

        expect(
          repo.adsStatisticsCallCount,
          2,
          reason: 'agent-b must never render agent-a\'s cached stat tiles',
        );
        expect(repo.adsSeriesCallCount, 2);
        expect(repo.leadsCallCount, 2);
        expect(repo.coworkersCallCount, 2);
        expect(repo.adsCallCount, 2);
      },
    );

    test('previewing a different role for the same user via setRole does not '
        'refetch — only a real change of signed-in identity should', () async {
      final repo = FakeDashboardRepository();
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [dashboardRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container.read(authSessionProvider.notifier).signIn(_agent('agent-a'));
      await container.read(dashboardAdsProvider.future);
      expect(repo.adsCallCount, 1);

      // `setRole` (auth_session.dart's own doc comment: "escape hatch
      // ... to preview a role without a full AuthUser") leaves `user`
      // untouched, so `user?.id` — every dashboard provider's
      // selector — never changes even though `AuthSessionState.role`
      // does.
      container.read(authSessionProvider.notifier).setRole(UserRole.coworker);
      await container.read(dashboardAdsProvider.future);

      expect(
        repo.adsCallCount,
        1,
        reason:
            'a role-only preview must not be mistaken for a session '
            'change',
      );
    });
  });
}
