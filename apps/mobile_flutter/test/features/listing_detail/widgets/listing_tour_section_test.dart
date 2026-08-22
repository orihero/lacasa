// Widget tests for `ListingTourSection` (SCREENS.md §7's 3D Tour entry) —
// the honest-gap show/hide rule, and that tapping it actually resolves the
// `tour3dView` route rather than just looking tappable.
//
// `WebViewPlatform.instance` is set to `FakeWebViewPlatform` before the
// navigation test: `Tour3dViewScreen.initState` constructs a real
// `WebViewController` synchronously the moment the route is pushed, and
// that construction asserts a platform implementation is registered — see
// `fake_webview_platform.dart`'s doc comment.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `WebViewPlatform` itself is re-exported by `webview_flutter` (a direct
// dependency) — only `fake_webview_platform.dart`'s subclasses need the
// deeper platform-interface types that aren't, see that file's own note.
import 'package:webview_flutter/webview_flutter.dart';

import 'package:lacasa_mobile/features/listing_detail/listing_detail.dart';
import 'package:lacasa_mobile/features/listing_detail/widgets/listing_tour_section.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../../../support/ambient_repository_overrides.dart';
import '../support/fake_listing_detail_repository.dart';
import '../support/fake_webview_platform.dart';
import '../support/listing_detail_test_ads.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpDetail(
    WidgetTester tester,
    FakeListingDetailRepository repository,
  ) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...ambientRepositoryOverrides(favourites: false, listingDetail: false),
        listingDetailRepositoryProvider.overrideWithValue(repository),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    router.push('/home/listing/ad-1001');
    await tester.pumpAndSettle();
  }

  testWidgets('no tour3dLink: the 3D Tour section renders nothing', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      FakeListingDetailRepository(ad: testAd(), agent: testAgent()),
    );

    expect(find.text('3D Tour'), findsNothing);
    expect(find.text('Live 3D Tour'), findsNothing);
  });

  testWidgets('a tour3dLink shows the 3D Tour section', (tester) async {
    await pumpDetail(
      tester,
      FakeListingDetailRepository(
        ad: testAd(tour3dLink: 'https://tours.lacasa.uz/ad-1001'),
        agent: testAgent(),
      ),
    );

    expect(find.text('3D Tour'), findsOneWidget);
    expect(find.text('Live 3D Tour'), findsOneWidget);
  });

  testWidgets('tapping it resolves the tour3dView route', (tester) async {
    WebViewPlatform.instance = FakeWebViewPlatform();

    await pumpDetail(
      tester,
      FakeListingDetailRepository(
        ad: testAd(tour3dLink: 'https://tours.lacasa.uz/ad-1001'),
        agent: testAgent(),
      ),
    );

    final finder = find.byType(ListingTourSection);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    // Two pumps, not `pumpAndSettle`: the pushed screen shows an
    // indeterminate `CircularProgressIndicator` while the (fake) load is in
    // flight, which never "settles" — see `tour3d_view_screen_test.dart`'s
    // "route resolving" group for the same fix with the fuller explanation.
    // One pump processes the push, the second finishes the page transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(Tour3dViewScreen), findsOneWidget);
  });
}
