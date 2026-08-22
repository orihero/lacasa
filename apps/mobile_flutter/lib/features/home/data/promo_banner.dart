/// The data seam behind Home's `.rail.promos` carousel.
///
/// **No promotions endpoint exists today, and no admin surface that could
/// feed one.** Confirmed rather than assumed: `apps/api/prisma/schema.prisma`
/// declares no banner/promo/campaign model, `apps/api/src/routes/` exposes no
/// such route, `UserRole` is `USER | AGENT | COWORKER` with no `ADMIN` member
/// and `middleware/roles.js` has no admin guard — and even
/// `mockups/web-admin.html`, the *proposed* admin surface, draws seven screens
/// (`x-over`/`x-apps`/`x-users`/`x-mod`/`x-tours`/`x-plans`/`x-audit`), none of
/// them a banner manager. `mockups/WEB.md` says so outright: "There is no
/// `ADMIN` role." So the promo list is local because nothing else exists to
/// serve it, not because it was judged uninteresting to make configurable.
///
/// This file exists so that stops being a rewrite. [PromoBannerSource] is the
/// only thing `promo_carousel.dart` reads; pointing
/// `state/promo_banner_source_provider.dart` at a live implementation is a
/// one-line change, and `_PromoCard`'s render path never learns where a
/// [PromoBanner] came from.
///
/// Deliberately **synchronous**: a `Future` here would buy a loading frame on
/// every Home build in exchange for a list that is already in memory. If the
/// eventual source is a real fetch, [PromoBannerSource.promos] returns a
/// `Future`, `PromoCarousel` grows the same `AsyncValue` shell every other
/// rail on Home already has (`shared/widgets/list_states.dart`), and the card
/// itself still does not change.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// One `.promo` card: the copy and its art, in three tiers — a bundled
/// [assetPath] over a [gradient] ground, with an optional remote [imageUrl]
/// on top for the day a backend has something newer to say. Every tier below
/// the top one keeps rendering, so no single failure leaves a hole.
class PromoBanner {
  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.assetPath,
    this.imageUrl,
  });

  /// Pre-joined with the same `\n` the original two-element `titleLines` list
  /// was rendered with (`spec.titleLines.join('\n')`) — the ARB message itself
  /// now carries that newline, so there is nothing left to join at render
  /// time.
  final String title;

  final String subtitle;

  /// `.promo img{position:absolute;inset:0;width:100%;height:100%;
  /// object-fit:cover}` — the bundled photograph behind the copy, e.g.
  /// `assets/promos/promo-crosspost.jpg`. This is the tier that makes the
  /// card *always* right: an asset needs no connection, no cache warm-up and
  /// no first-frame delay. Nullable only so a future server-authored banner,
  /// which by definition ships no asset, is still expressible.
  final String? assetPath;

  /// A remote photograph painted over [assetPath] once it decodes. Null for
  /// every banner today — it is the seam a promotions endpoint fills, not a
  /// second-guess of the bundled art. Kept nullable and topmost so a live
  /// source can override the picture without the local tiers going anywhere:
  /// a dead URL simply reveals the asset underneath.
  final String? imageUrl;

  /// The bottom ground, painted underneath both photo tiers and never
  /// removed. A [Gradient] is presentation living in a data class on purpose:
  /// it is the last line of "must render sensibly with no network"
  /// (`shared/widgets/listing_photo.dart`'s own contract), so whoever supplies
  /// a banner supplies its fallback with it rather than leaving the widget to
  /// guess one for a card it has never seen.
  final Gradient gradient;
}

/// Where [PromoBanner]s come from. One implementation today
/// (`LocalPromoBannerSource`); see this library's doc comment for why there is
/// no live one and what it would take to add.
abstract class PromoBannerSource {
  /// Takes [AppLocalizations] because promo copy is this app's own words, not
  /// the server's — the same reason `promo_carousel.dart` built its list from
  /// a [BuildContext] before this seam existed. A future live source that
  /// receives server-authored copy would ignore the argument and pass the wire
  /// strings straight through, per `lib/l10n/README.md`'s rule on rendering
  /// server-authored text verbatim.
  List<PromoBanner> promos(AppLocalizations l10n);
}
