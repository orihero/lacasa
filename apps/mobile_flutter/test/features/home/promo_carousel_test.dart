// Widget tests for Home's promo carousel (lib/features/home/widgets/
// promo_carousel.dart), focused on the one thing the cards must never get
// wrong: what they look like when a photograph does not arrive.
//
// This needs no network guard and no ambient repository overrides —
// `promoBannerSourceProvider` is local and synchronous. And flutter_test
// already simulates "no connection" for us: `AutomatedTestWidgetsFlutterBinding`
// installs an `HttpOverrides` whose client answers 400 to everything, so
// `Image.network` here behaves exactly as it does on a plane. That makes the
// offline case the *default* case in this file — which is precisely why the
// real source's art has to be bundled, and why the third test below asserts
// that rather than asserting a URL.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/home/data/promo_banner.dart';
import 'package:lacasa_mobile/features/home/state/promo_banner_source_provider.dart';
import 'package:lacasa_mobile/features/home/widgets/promo_carousel.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_promo_banner_source.dart';

const _fallbackKey = ValueKey('promoBannerPhotoFallback');

const _gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF6C63FF), Color(0xFF3B2E8A)],
);

Widget _harness({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: const Scaffold(body: PromoCarousel()),
    ),
  );
}

/// The gradient actually painted by the card, read back off the rendered
/// `Container` rather than off the model, so the test proves the fallback art
/// reaches the screen.
Gradient? _cardGradient(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(PromoCarousel),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration as BoxDecoration?)?.gradient;
}

/// Every bundled photograph actually mounted, in rail order, read off the
/// rendered `Image`s rather than off the model — so the test proves the art
/// reaches the screen, not merely that a string was declared.
List<String> _assetPaths(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .whereType<AssetImage>()
      .map((provider) => provider.assetName)
      .toList();
}

void main() {
  testWidgets('an unreachable photo falls back to the card gradient, not a '
      'broken-image glyph', (tester) async {
    await tester.pumpWidget(
      _harness(
        overrides: [
          promoBannerSourceProvider.overrideWithValue(
            const FakePromoBannerSource([
              PromoBanner(
                title: 'One Post,\nEvery Channel',
                subtitle: 'Instagram, Telegram and YouTube',
                imageUrl: 'https://example.invalid/promo.jpg',
                gradient: _gradient,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The failed load renders as nothing at all, so the gradient underneath
    // is what the user sees.
    expect(find.byKey(_fallbackKey), findsOneWidget);
    expect(_cardGradient(tester), _gradient);

    // The copy survives the failure — a card that loses its photo is still a
    // finished banner.
    expect(find.text('One Post,\nEvery Channel'), findsOneWidget);
    expect(find.text('Instagram, Telegram and YouTube'), findsOneWidget);

    // No thrown ImageProvider error escaped the errorBuilder.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a banner with no photo URL renders the gradient without '
      'attempting a load', (tester) async {
    await tester.pumpWidget(
      _harness(
        overrides: [
          promoBannerSourceProvider.overrideWithValue(
            const FakePromoBannerSource([
              PromoBanner(
                title: 'New in\nYashnobod',
                subtitle: '4-room new builds from \$95,000',
                gradient: _gradient,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsNothing);
    expect(find.byKey(_fallbackKey), findsOneWidget);
    expect(_cardGradient(tester), _gradient);
    expect(find.text('New in\nYashnobod'), findsOneWidget);
  });

  testWidgets('a remote photo is layered over the bundled one, so a dead URL '
      'reveals the asset rather than the gradient', (tester) async {
    await tester.pumpWidget(
      _harness(
        overrides: [
          promoBannerSourceProvider.overrideWithValue(
            const FakePromoBannerSource([
              PromoBanner(
                title: 'One Post,\nEvery Channel',
                subtitle: 'Instagram, Telegram and YouTube',
                assetPath: 'assets/promos/promo-crosspost.jpg',
                imageUrl: 'https://example.invalid/promo.jpg',
                gradient: _gradient,
              ),
            ]),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // The network tier failed (every request 400s here) and collapsed to the
    // zero-size fallback; the asset tier is still mounted underneath it.
    expect(find.byKey(_fallbackKey), findsOneWidget);
    expect(_assetPaths(tester), ['assets/promos/promo-crosspost.jpg']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the real local source bundles its art, so every banner renders '
      'with no network at all', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // The load-bearing assertion of this file. Every request 400s here, which
    // is the offline device — so if the source reached for a URL, these cards
    // would be the flat gradients the rail used to be. Instead each one names
    // a bundled asset, and no `Image.network` is attempted at all (its failure
    // is what mounts `_fallbackKey`, so an empty finder proves the absence).
    expect(_assetPaths(tester), [
      'assets/promos/promo-crosspost.jpg',
      'assets/promos/promo-yashnobod.jpg',
    ]);
    expect(find.byKey(_fallbackKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card advertises no action it cannot perform', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // `.promo__go`'s ↗ button is gone (see promo_carousel.dart's doc
    // comment): nothing in this rail navigates, so nothing in it may look
    // like it does. The glyph is the whole affordance, so its absence is
    // the assertion — re-adding it without a destination fails here rather
    // than shipping.
    expect(find.byIcon(Icons.north_east_rounded), findsNothing);
    // The cards themselves still rendered — i.e. this passes because the
    // arrow is gone, not because the rail failed to build.
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('a source with no banners hides the rail entirely', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        overrides: [
          promoBannerSourceProvider.overrideWithValue(
            const FakePromoBannerSource([]),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(ListView), findsNothing);
    expect(find.byType(Image), findsNothing);
  });
}
