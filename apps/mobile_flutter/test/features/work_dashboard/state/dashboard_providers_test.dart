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
  group(
    'every dashboard AsyncNotifier goes stale-aware on sign-out/sign-in '
    '(finding M5 — `dashboard` stays mounted for the whole Work-tab session '
    'and none of these six providers is `.autoDispose`, so nothing else '
    'tore them down across a session change before this fix)',
    () {
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

      test(
        'previewing a different role for the same user via setRole does not '
        'refetch — only a real change of signed-in identity should',
        () async {
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
        },
      );
    },
  );
}
