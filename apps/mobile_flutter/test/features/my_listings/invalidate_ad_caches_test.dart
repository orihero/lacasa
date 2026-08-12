// Tests for `invalidateAdCaches`
// (lib/features/my_listings/state/my_listings_providers.dart) — finding
// M4's fix. `create_listing_screen.dart`/`edit_listing_screen.dart` (out of
// this test directory's ownership) are the real call sites, so this drives
// the exact same shape they do: a `ConsumerState`'s `ref`, captured from a
// widget button's `onPressed`, calling `invalidateAdCaches(ref)` — not a
// bare `ProviderContainer.invalidate(...)`, since the whole point of this
// fix is the *function*, not that Riverpod's own invalidate works.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/my_listings/state/my_listings_providers.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_providers.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';

import '../work_dashboard/support/fake_dashboard_repository.dart';
import 'support/fake_my_listings_repository.dart';

/// One button, one `ref`, exactly the shape
/// `create_listing_screen.dart`'s `_submit`/`edit_listing_screen.dart`'s
/// `_save`/`_delete` use — a `ConsumerState`'s own `ref` handed to
/// [invalidateAdCaches] from an event handler, not `build()` itself.
class _InvalidateHarness extends ConsumerStatefulWidget {
  const _InvalidateHarness();

  @override
  ConsumerState<_InvalidateHarness> createState() => _InvalidateHarnessState();
}

class _InvalidateHarnessState extends ConsumerState<_InvalidateHarness> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => invalidateAdCaches(ref),
      child: const Text('invalidate'),
    );
  }
}

void main() {
  testWidgets(
    'invalidateAdCaches refetches my-listings and every dashboard ad cache '
    'at once (finding M4 — before this fix, only one of these four caches '
    'was ever invalidated, and it was the one the visible stat tile does '
    'not even read)',
    (tester) async {
      final myListingsRepo = FakeMyListingsRepository();
      final dashboardRepo = FakeDashboardRepository();

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          myListingsRepositoryProvider.overrideWithValue(myListingsRepo),
          dashboardRepositoryProvider.overrideWithValue(dashboardRepo),
        ],
      );
      addTearDown(container.dispose);

      // Prime every cache once — the state each provider is already in by
      // the time a real create/edit/delete mutation happens, since
      // `my-listings` and `dashboard` are both already-visited screens in
      // the scenario this bug describes.
      await container.read(myListingsResultsProvider.future);
      await container.read(dashboardAdsProvider.future);
      await container.read(adsStatisticsProvider.future);
      await container.read(adsSeriesProvider.future);

      expect(myListingsRepo.fetchMyAdsCallCount, 1);
      expect(dashboardRepo.adsCallCount, 1);
      expect(dashboardRepo.adsStatisticsCallCount, 1);
      expect(dashboardRepo.adsSeriesCallCount, 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: _InvalidateHarness()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Every one of the four caches must have refetched — not just the
      // one `dashboardAdsProvider` call site that used to be the only one
      // invalidated.
      await container.read(myListingsResultsProvider.future);
      await container.read(dashboardAdsProvider.future);
      await container.read(adsStatisticsProvider.future);
      await container.read(adsSeriesProvider.future);

      expect(
        myListingsRepo.fetchMyAdsCallCount,
        2,
        reason: 'my-listings itself was never invalidated before this fix',
      );
      expect(dashboardRepo.adsCallCount, 2);
      expect(
        dashboardRepo.adsStatisticsCallCount,
        2,
        reason:
            'this backs the dashboard\'s visible "Ads created"/"Ads sold" '
            'stat tiles — the one the original bug report actually saw '
            'holding a stale value',
      );
      expect(dashboardRepo.adsSeriesCallCount, 2);
    },
  );
}
