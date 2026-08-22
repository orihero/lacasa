// Pins where the favourite heart is *painted* on each of the three shared
// listing cards, not just how big its hit box is.
//
// This test exists because of a regression the hit-box work introduced and
// no existing test could see. [TapTarget] centres the mockup-sized chip
// inside a 48dp box, so the number a card passes to `Positioned` stopped
// describing the chip and started describing the box — and every card that
// kept the mockup's own `.fav{top:…;right:…}` inset silently moved its heart
// inward by half the difference (`.fcard`'s by 7px, straight past the CSS
// rule quoted in the line above it). `favourite_button_test.dart` asserted
// the 48dp box and the 34dp chip and passed throughout, because both numbers
// were still right; only the *offset* between them had changed, which is
// exactly what is measured here.
//
// Each case measures the painted [GlassSurface] chip against the photo it
// sits on, so it fails if the inset, the chip size, or
// [FavouriteButton.cornerInset]'s arithmetic drifts — and it is stated in
// the mockup's own numbers, so the assertion can be checked against the CSS
// rule without re-deriving anything.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_favourite_ad_ids_repository.dart';

Map<String, dynamic> _adJson(String id) => {
  'id': id,
  'title': 'Listing $id',
  'city': 'Tashkent',
  'district': 'Chilonzor tumani',
  'address': null,
  'reference': null,
  'type': 'residential',
  'category': 'sale',
  'rooms': 3,
  'area': 60,
  'storey': 2,
  'floors': 9,
  'hashtags': null,
  'price': 100000,
  'priceType': 'usd',
  'stage': '1',
  'description': null,
  'nearPlacesList': <String>[],
  'optionList': null,
  'active': true,
  'lat': null,
  'lng': null,
  'tour3dLink': null,
  'agentId': 'agent-1',
  'coworkerId': '',
  'photos': <String>[],
  'media': <Map<String, dynamic>>[],
  'createdAt': {'seconds': 1700000000},
  'updatedAt': {'seconds': 1700000000},
};

void main() {
  final ad = Ad.fromJson(_adJson('ad-1'));
  const heartKey = ValueKey('favourite-ad-1');

  /// Pumps [card] on its own, signed out — which is a heart-visible session
  /// (saving needs an account, *seeing* the control does not), so no
  /// `authSessionProvider` setup is needed to make the chip appear.
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    final container = ProviderContainer(
      overrides: [
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
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
          home: Scaffold(body: Center(child: card)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The painted chip's distance from the photo's top-right corner — `dx`
  /// from the right edge, `dy` from the top edge — i.e. exactly the pair the
  /// mockup's `.fav{top:…;right:…}` rule specifies.
  Offset paintedCornerInset(WidgetTester tester) {
    final photo = tester.getRect(find.byType(ListingPhoto));
    final chip = tester.getRect(
      find.descendant(
        of: find.byKey(heartKey),
        matching: find.byType(GlassSurface),
      ),
    );
    return Offset(photo.right - chip.right, chip.top - photo.top);
  }

  void expectPaintedAt(WidgetTester tester, double inset, double chipSize) {
    final painted = paintedCornerInset(tester);
    expect(painted.dx, moreOrLessEquals(inset, epsilon: 0.01));
    expect(painted.dy, moreOrLessEquals(inset, epsilon: 0.01));
    expect(
      tester.getSize(
        find.descendant(
          of: find.byKey(heartKey),
          matching: find.byType(GlassSurface),
        ),
      ),
      Size(chipSize, chipSize),
    );
    // The whole point of the compensation is that it costs the hit box
    // nothing: the TapTarget is still laid out at the full 48dp floor.
    expect(tester.getSize(find.byKey(heartKey)), const Size(48, 48));
  }

  testWidgets('.fcard paints its 34px heart 9px from the corner', (
    tester,
  ) async {
    // `.fcard__ph .fav{top:9px;right:9px}`.
    await pumpCard(tester, FullListingCard(ad: ad, onTap: () {}));
    expectPaintedAt(tester, 9, 34);
  });

  testWidgets('.vcard paints its 28px heart 8px from the corner', (
    tester,
  ) async {
    // `.vcard__ph .fav{top:8px;right:8px}`. The card's photo is `Expanded`,
    // so it needs a bounded cell rather than a free-floating pump.
    await pumpCard(
      tester,
      SizedBox(
        width: 165,
        height: 230,
        child: CompactListingCard(ad: ad, onTap: () {}),
      ),
    );
    expectPaintedAt(tester, 8, 28);
  });

  testWidgets('.lcard paints its 26px heart 7px from the corner', (
    tester,
  ) async {
    // `.lcard .fav{top:7px;right:7px}` — the same inset its category badge
    // uses on the other corner, which is why they must be allowed to differ
    // as *positioned* values while matching as painted ones.
    await pumpCard(
      tester,
      SizedBox(
        width: 360,
        child: RowListingCard(ad: ad, onTap: () {}),
      ),
    );
    expectPaintedAt(tester, 7, 26);
  });

  testWidgets('the badge and the heart still read as one gutter on .lcard', (
    tester,
  ) async {
    // The badge is positioned by what it paints and the heart by its hit
    // box, so a reader seeing `left: _overlayInset` next to `right: _favInset`
    // could reasonably think the two corners disagree. They do not: this
    // asserts the painted gap from each edge is the same number.
    await pumpCard(
      tester,
      SizedBox(
        width: 360,
        child: RowListingCard(ad: ad, onTap: () {}),
      ),
    );

    final photo = tester.getRect(find.byType(ListingPhoto));
    final badge = tester.getRect(
      find.ancestor(of: find.text('Sale'), matching: find.byType(GlassSurface)),
    );
    expect(badge.left - photo.left, moreOrLessEquals(7, epsilon: 0.01));
    expect(badge.top - photo.top, moreOrLessEquals(7, epsilon: 0.01));
    expect(paintedCornerInset(tester).dx, moreOrLessEquals(7, epsilon: 0.01));
  });
}
