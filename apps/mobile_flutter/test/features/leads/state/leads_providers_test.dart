// Tests for `LeadsNotifier` (lib/features/leads/state/leads_providers.dart) —
// specifically its post-mutation refetch, which is not exercised by any
// screen-level widget test.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/leads/state/leads_providers.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_providers.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';

import '../../work_dashboard/support/fake_dashboard_repository.dart';
import '../support/fake_leads_repository.dart';
import '../support/lead_fixtures.dart';

void main() {
  group(
    'post-mutation refetch failure keeps the previous list '
    '(correctness — a transient refetch hiccup must not discard an '
    "already-successful mutation's data)",
    () {
      test(
        'a failed refetch after a successful update keeps the previous '
        'list attached, instead of a bare AsyncError',
        () async {
          final repo = FakeLeadsRepository(
            leads: [makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova')],
          );
          final container = ProviderContainer(
            retry: (retryCount, error) => null,
            overrides: [leadsRepositoryProvider.overrideWithValue(repo)],
          );
          addTearDown(container.dispose);

          final initial = await container.read(leadsProvider.future);
          expect(initial, hasLength(1));

          // The mutation (PATCH) itself succeeds; only the follow-up
          // refetch (GET) fails — the exact scenario `LeadsNotifier`'s
          // `_refetch` guards against.
          repo.listError = const NetworkException('offline');

          await container
              .read(leadsProvider.notifier)
              .updateLead(
                'lead-1',
                LeadWriteInput(status: OptionalField(LeadStatus.accepted)),
              );

          final state = container.read(leadsProvider);
          expect(
            state.hasError,
            isFalse,
            reason:
                'a hiccup on the *refetch* must not misrepresent the '
                "already-successful mutation as a fatal load failure",
          );
          expect(
            state.hasValue,
            isTrue,
            reason:
                'the previously-loaded list must not be discarded — '
                'consumers key off `hasValue` to keep showing it',
          );
          expect(state.value, hasLength(1));
        },
      );

      test(
        'a refetch that succeeds after a prior failure picks up the fresh '
        'data on the very next mutation',
        () async {
          final repo = FakeLeadsRepository(
            leads: [makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova')],
          );
          final container = ProviderContainer(
            retry: (retryCount, error) => null,
            overrides: [leadsRepositoryProvider.overrideWithValue(repo)],
          );
          addTearDown(container.dispose);

          await container.read(leadsProvider.future);
          repo.listError = const NetworkException('offline');

          await container
              .read(leadsProvider.notifier)
              .updateLead(
                'lead-1',
                LeadWriteInput(status: OptionalField(LeadStatus.accepted)),
              );
          expect(container.read(leadsProvider).value, hasLength(1));

          repo.listError = null;
          await container.read(leadsProvider.notifier).deleteLead('lead-1');

          final state = container.read(leadsProvider);
          expect(state.hasError, isFalse);
          expect(state.value, isEmpty);
        },
      );
    },
  );

  group(
    "dashboardLeadsProvider goes stale-aware on every mutation "
    '(correctness — Dashboard stays mounted for the whole Work-tab '
    "session and owns its own copy of this list)",
    () {
      test('createLead invalidates dashboardLeadsProvider', () async {
        final leadsRepo = FakeLeadsRepository();
        final dashboardRepo = FakeDashboardRepository();
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            leadsRepositoryProvider.overrideWithValue(leadsRepo),
            dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(dashboardLeadsProvider.future);
        expect(dashboardRepo.leadsCallCount, 1);

        await container
            .read(leadsProvider.notifier)
            .createLead(
              LeadWriteInput(
                fullName: OptionalField('New Lead'),
                phone: OptionalField('+998901234567'),
              ),
            );

        await container.read(dashboardLeadsProvider.future);
        expect(
          dashboardRepo.leadsCallCount,
          2,
          reason: 'a stale dashboardLeadsProvider must refetch once invalidated',
        );
      });

      test('updateLead and deleteLead also invalidate dashboardLeadsProvider', () async {
        final leadsRepo = FakeLeadsRepository(
          leads: [makeLead(id: 'lead-1', fullName: 'Dilnoza Yusupova')],
        );
        final dashboardRepo = FakeDashboardRepository();
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            leadsRepositoryProvider.overrideWithValue(leadsRepo),
            dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
          ],
        );
        addTearDown(container.dispose);

        await container.read(dashboardLeadsProvider.future);
        expect(dashboardRepo.leadsCallCount, 1);

        await container
            .read(leadsProvider.notifier)
            .updateLead(
              'lead-1',
              LeadWriteInput(status: OptionalField(LeadStatus.accepted)),
            );
        await container.read(dashboardLeadsProvider.future);
        expect(dashboardRepo.leadsCallCount, 2);

        await container.read(leadsProvider.notifier).deleteLead('lead-1');
        await container.read(dashboardLeadsProvider.future);
        expect(dashboardRepo.leadsCallCount, 3);
      });
    },
  );
}
