// Tests for `MyListingsResultsNotifier`/`MyListingsCoworkersNotifier`'s
// session-awareness (lib/features/my_listings/state/my_listings_providers.dart)
// — finding M5's provider half. Pure `ProviderContainer` tests, same shape
// as `test/features/leads/state/leads_providers_test.dart`'s own
// `dashboardLeadsProvider`-invalidation group: no widget pump needed since
// nothing here is UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_providers.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';

import '../../auth/support/fake_auth_repository.dart';
import '../support/fake_my_listings_repository.dart';
import '../support/my_listings_test_data.dart';

void main() {
  group(
    'session-scoped caches go stale-aware on sign-out/sign-in (finding M5 — '
    'my-listings is a coworker session\'s Work-tab landing screen and its '
    'own results provider is not `.autoDispose`, so nothing else tore it '
    'down across a session change before this fix)',
    () {
      test(
        'signing in as a different account refetches both the ad list and '
        'the coworker roster',
        () async {
          final repo = FakeMyListingsRepository();
          final container = ProviderContainer(
            retry: (retryCount, error) => null,
            overrides: [myListingsRepositoryProvider.overrideWithValue(repo)],
          );
          addTearDown(container.dispose);

          container
              .read(authSessionProvider.notifier)
              .signIn(myListingsAuthUser(id: 'agent-a', fullName: 'Agent A'));
          await container.read(myListingsResultsProvider.future);
          await container.read(myListingsCoworkersProvider.future);
          expect(repo.fetchMyAdsCallCount, 1);
          expect(repo.fetchCoworkersCallCount, 1);

          // A second account, sharing the exact same role — the case the
          // router's own redirect guard can't distinguish by role alone,
          // per this file's own doc comment.
          container
              .read(authSessionProvider.notifier)
              .signIn(myListingsAuthUser(id: 'agent-b', fullName: 'Agent B'));
          await container.read(myListingsResultsProvider.future);
          await container.read(myListingsCoworkersProvider.future);

          expect(
            repo.fetchMyAdsCallCount,
            2,
            reason: 'agent-b must never render agent-a\'s cached ad list',
          );
          expect(repo.fetchCoworkersCallCount, 2);
        },
      );

      test('signing out then back in also refetches', () async {
        final repo = FakeMyListingsRepository();
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            myListingsRepositoryProvider.overrideWithValue(repo),
            // signOut() calls AuthSessionNotifier's real
            // authRepositoryProvider.signOut(); the live repository touches
            // flutter_secure_storage's platform channel, which has no
            // binding in a plain `test()` (no `testWidgets` pump). Same
            // `FakeAuthRepository` this file's own doc comment points to
            // (`auth_session_test.dart`'s convention) avoids that call
            // entirely.
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ],
        );
        addTearDown(container.dispose);

        container
            .read(authSessionProvider.notifier)
            .signIn(myListingsAuthUser(id: 'agent-a', fullName: 'Agent A'));
        await container.read(myListingsResultsProvider.future);
        expect(repo.fetchMyAdsCallCount, 1);

        await container.read(authSessionProvider.notifier).signOut();
        await container.read(myListingsResultsProvider.future);
        expect(repo.fetchMyAdsCallCount, 2);

        container
            .read(authSessionProvider.notifier)
            .signIn(myListingsAuthUser(id: 'agent-a', fullName: 'Agent A'));
        await container.read(myListingsResultsProvider.future);

        expect(repo.fetchMyAdsCallCount, 3);
      });

      test(
        'previewing a different role for the same user via setRole does not '
        'refetch — only a real change of signed-in identity should',
        () async {
          final repo = FakeMyListingsRepository();
          final container = ProviderContainer(
            retry: (retryCount, error) => null,
            overrides: [myListingsRepositoryProvider.overrideWithValue(repo)],
          );
          addTearDown(container.dispose);

          container
              .read(authSessionProvider.notifier)
              .signIn(myListingsAuthUser(id: 'agent-a', fullName: 'Agent A'));
          await container.read(myListingsResultsProvider.future);
          expect(repo.fetchMyAdsCallCount, 1);

          // `setRole` (auth_session.dart's own doc comment: "escape hatch
          // ... to preview a role without a full AuthUser") leaves `user`
          // untouched, so `user?.id` — this provider's selector — never
          // changes even though `AuthSessionState.role` does.
          container.read(authSessionProvider.notifier).setRole(UserRole.coworker);
          await container.read(myListingsResultsProvider.future);

          expect(
            repo.fetchMyAdsCallCount,
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
