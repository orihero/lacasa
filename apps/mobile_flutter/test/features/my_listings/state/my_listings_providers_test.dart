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

      test('the stage-count strip is session-scoped too', () async {
        // Same reasoning as the ad list: nothing tears this provider down
        // across a sign-out/sign-in, so an agent who switches accounts
        // would keep reading the previous account's draft count above the
        // new account's ads.
        final repo = FakeMyListingsRepository();
        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [myListingsRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        container
            .read(authSessionProvider.notifier)
            .signIn(myListingsAuthUser(id: 'agent-a', fullName: 'Agent A'));
        await container.read(myListingsStageCountsProvider.future);
        expect(repo.fetchStageCountsCallCount, 1);

        container
            .read(authSessionProvider.notifier)
            .signIn(myListingsAuthUser(id: 'agent-b', fullName: 'Agent B'));
        await container.read(myListingsStageCountsProvider.future);

        expect(repo.fetchStageCountsCallCount, 2);
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

  group('the publish-status batch key (UX audit §9.2)', () {
    test('refires when the visible ad set grows, and only then', () async {
      final repo = FakeMyListingsRepository(
        ads: [
          for (var i = 0; i < myListingsPageSize * 3; i++)
            myListingAd(id: 'ad-$i'),
        ],
      );
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [myListingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(myListingsResultsProvider.future);
      await container.read(myListingsPublishStatusesProvider.future);
      expect(repo.fetchPublishStatusesCallCount, 1);
      expect(repo.lastPublishStatusAdIds, hasLength(myListingsPageSize));

      final notifier = container.read(myListingsResultsProvider.notifier);
      await notifier.loadMore();
      await container.read(myListingsPublishStatusesProvider.future);
      expect(repo.fetchPublishStatusesCallCount, 2);
      expect(repo.lastPublishStatusAdIds, hasLength(myListingsPageSize * 2));

      // A *failed* load-more rebuilds `MyListingsPageState` twice
      // (`isLoadingMore`, then `loadMoreFailed`) while leaving the set of
      // visible ads exactly as it was. This is what
      // `myListingsLoadedAdIdsProvider` being a joined `String` buys: `List`
      // has identity equality in Dart, so a `Provider<List<String>>` would
      // report a change on each of those rebuilds and fire a redundant
      // batch request for an unchanged page. A third call here is that
      // regression.
      repo.adsError = const NetworkException('offline');
      await notifier.loadMore();
      await container.read(myListingsPublishStatusesProvider.future);

      expect(repo.fetchPublishStatusesCallCount, 2);
      expect(repo.lastPublishStatusAdIds, hasLength(myListingsPageSize * 2));
    });

    test('caps the id list at the route\'s documented 200-id ceiling', () async {
      // `GET /publish/status` slices at 200 server-side; sending more would
      // silently drop the tail anyway. Capping here keeps the request legal
      // instead of letting an agent who has scrolled twenty pages get a
      // request the server truncates.
      const total = 250;
      final repo = FakeMyListingsRepository(
        ads: [for (var i = 0; i < total; i++) myListingAd(id: 'ad-$i')],
      );
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [myListingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(myListingsResultsProvider.future);
      final notifier = container.read(myListingsResultsProvider.notifier);
      // Bounded rather than `while (…)`: a `loadMore` that silently stopped
      // making progress would hang the whole suite instead of failing.
      for (var page = 0; page < total ~/ myListingsPageSize; page++) {
        await notifier.loadMore();
      }
      expect(
        container.read(myListingsResultsProvider).value?.ads,
        hasLength(total),
      );
      await container.read(myListingsPublishStatusesProvider.future);

      expect(repo.lastPublishStatusAdIds, hasLength(publishStatusBatchLimit));
      // The cap takes the head — the rows an agent scrolled past — rather
      // than the tail, so the ids requested are always a prefix of what is
      // loaded.
      expect(repo.lastPublishStatusAdIds!.first, 'ad-0');
    });
  });
}
