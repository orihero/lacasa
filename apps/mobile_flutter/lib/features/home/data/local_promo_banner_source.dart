/// The only [PromoBannerSource] there is — see `promo_banner.dart` for the
/// (verified) reason there is no live one.
///
/// Both photographs are the mockup's **own** art, not substitutes for it.
/// `mockup-e-liquid-glass.html` paints every `[data-ph]` from a `window.PHOTOS`
/// registry of base64 JPEGs, and two of its keys are exactly these cards'
/// backgrounds: `promo-crosspost` (the white-and-timber villa) and
/// `promo-yashnobod` (the white new-build low-rise). Both were decoded out of
/// that registry into `assets/promos/` at 500x300 — 51 KB the pair, a clean 2x
/// for the 252x140 card.
///
/// They are **bundled, not fetched**, and that is the whole point of this
/// file's shape. A promo is chrome: it is on screen in the first frame of a
/// cold start, before any request could have answered, and it is on screen
/// with the radio off. Hotlinking it — even to reachable URLs, even to the
/// `frankfurt.apollo.olxcdn.com` host the app already loads listing photos
/// from — means the offline and cold-start cases fall through to
/// [PromoBanner.gradient], i.e. to the flat coloured rectangles this rail used
/// to be. An asset cannot fail that way.
///
/// [PromoBanner.imageUrl] is therefore null here. It is not a gap: it is the
/// tier a promotions endpoint would fill (see `promo_banner.dart`), painted
/// *over* the asset so the bundled art stays the floor rather than being
/// replaced by a URL that might not answer.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'promo_banner.dart';

class LocalPromoBannerSource implements PromoBannerSource {
  const LocalPromoBannerSource();

  @override
  List<PromoBanner> promos(AppLocalizations l10n) => [
    PromoBanner(
      title: l10n.homePromoOneTitle,
      subtitle: l10n.homePromoOneSubtitle,
      assetPath: 'assets/promos/promo-crosspost.jpg',
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6C63FF), Color(0xFF3B2E8A)],
      ),
    ),
    PromoBanner(
      title: l10n.homePromoTwoTitle,
      subtitle: l10n.homePromoTwoSubtitle,
      assetPath: 'assets/promos/promo-yashnobod.jpg',
      // The copy ("4-room new builds from $95,000") was written from the one
      // `Yashnobod tumani` row in `apps/api/prisma/seed-data/olx-listings.json`
      // — a real listing whose own `photos[0]` is a live OLX CDN URL. Not used:
      // that photo is a 933x700 arbitrary CDN crop of one ad, while the card
      // wants the designer's 500x300 framing, and pointing a permanent banner
      // at a single ad's photo makes the banner die when the ad does.
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E8A6B), Color(0xFF14432F)],
      ),
    ),
  ];
}
