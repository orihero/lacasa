/// The `.rail.promos` carousel: two full-bleed photo cards. **Also
/// non-interactive** (build spec, "Promo carousel" — neither `<article
/// class="promo">` nor its `.promo__go` arrow carries a `data-go` in the
/// source markup, flagged there as a divergence worth surfacing since
/// README's own decorative list doesn't call this out). No `onTap`
/// anywhere in this file, deliberately.
///
/// **And so, as of this pass, no arrow either.** Transcribing `.promo__go`
/// faithfully reproduced a control — a glass circle holding a ↗, the exact
/// vocabulary the rest of the app uses for "this opens something" — onto a
/// card that has nowhere to go. A decorative card is fine; a decorative
/// *button* is a lie the user only discovers by tapping it. The card keeps
/// its photo, veil and copy and drops the affordance, which is the half of
/// the mockup that was never backed by anything. The removal is recorded at
/// its own call site further down this file.
///
/// The cards carry the mockup's own photographs now, bundled under
/// `assets/promos/` rather than fetched — a promo is on screen in the first
/// frame of a cold start and with the radio off, so its art cannot be
/// something that might not arrive. The list itself comes from
/// [PromoBannerSource] (`../data/promo_banner.dart`), which is local because
/// no promotions endpoint and no admin surface exist to serve it — that file
/// documents the check and what a live source would take. The gradient each
/// card used to be *is* still here, at the very bottom: it is the ground under
/// both photo tiers, so even a build stripped of its assets shows a branded
/// banner rather than a broken-image glyph.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../data/promo_banner.dart';
import '../state/promo_banner_source_provider.dart';

class PromoCarousel extends ConsumerWidget {
  const PromoCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref
        .watch(promoBannerSourceProvider)
        .promos(AppLocalizations.of(context));

    // A source that yields nothing hides the rail rather than leaving a
    // 140px hole — the local source never does, but a live one could, and
    // handling it here is what keeps the swap a provider change.
    if (promos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      // `.promo{height:140px}`.
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        itemCount: promos.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.base),
        itemBuilder: (context, index) => _PromoCard(banner: promos[index]),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        // Painted on the card itself, not in the Stack, so it is the ground
        // every other layer sits on and can never be covered by a failed
        // photo — see [_PromoPhoto].
        gradient: banner.gradient,
        boxShadow: AppShadows.floatingPromo,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _PromoPhoto(
              assetPath: banner.assetPath,
              url: banner.imageUrl,
            ),
          ),
          // `.promo__veil{background:linear-gradient(105deg,
          // rgba(10,9,20,.78) 6%,rgba(10,9,20,.5) 48%,
          // rgba(10,9,20,.12) 100%)}`. CSS measures 105deg clockwise from
          // "to top", in the box's own pixel space: over 252x140 that is a
          // rise of tan(15°)*252 = 67.5px across the full width, i.e. ±0.48
          // in `Alignment`'s half-height units.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0, -0.48),
                  end: Alignment(1.0, 0.48),
                  colors: [
                    Color(0xC70A0914),
                    Color(0x800A0914),
                    Color(0x1F0A0914),
                  ],
                  stops: [0.06, 0.48, 1.0],
                ),
              ),
            ),
          ),
          // Not in the mockup, and kept anyway. `.promo__veil` alone was
          // tuned against two hand-cropped stills whose bright halves sit
          // clear of the copy; these photos come off a CDN with arbitrary
          // framing, and the veil thins to ~0.34 alpha at the right end of
          // the subtitle — 2.5:1 for white text over a pale photo, well
          // under AA. This second, purely vertical scrim brings that worst
          // case to ~4.9:1 while leaving the veil's diagonal read intact.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.28, 1.0],
                ),
              ),
            ),
          ),
          // `.promo__copy{left:15px;right:62px;bottom:15px}`. The mockup's
          // 62px right inset exists solely to clear `.promo__go`; with that
          // arrow gone (see this file's doc comment) the copy takes the
          // card's own 15px inset on both sides instead — keeping the hole
          // would have left the title wrapping around an absence.
          Positioned(
            left: 15,
            right: 15,
            bottom: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `.promo__copy h3{font-size:15px;font-weight:700;
                // line-height:1.24;letter-spacing:-.3px}`.
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.24,
                    letterSpacing: -0.3,
                  ),
                ),
                // `.promo__copy p{margin-top:5px;font-size:10px;
                // color:rgba(255,255,255,.78)}` — the alpha is the one part
                // not copied: .78 measures ~4.4:1 against a pale photo even
                // through both scrims above, so the subtitle keeps the .85
                // it shipped with (~4.9:1).
                const SizedBox(height: 5),
                Text(
                  banner.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // `.promo__go{right:14px;bottom:14px;width:34px;height:34px;
          // font-size:16px}` — **removed**, not restyled. A 34px circular
          // glass button holding a ↗ glyph is, everywhere else in this app,
          // the "opens something" affordance; on a card with no destination
          // it was the single most confident-looking no-op on the landing
          // screen. Nothing renders in its place: the card is a banner, and
          // a banner that does nothing should look like one. It comes back
          // with [PromoBanner.destination] the day a promotions endpoint
          // (or any admin surface behind it) exists to say where a card
          // goes — see `../data/promo_banner.dart`, which has no
          // destination field precisely because nothing can populate one.
        ],
      ),
    );
  }
}

/// `.promo img{position:absolute;inset:0;width:100%;height:100%;
/// object-fit:cover}` — the mockup's single `<img>`, rendered as a stack of
/// tiers so that "the photo is missing" is never a state the user can reach.
/// Bottom to top: [PromoBanner.gradient] (painted by [_PromoCard] itself),
/// then the bundled [assetPath], then a remote [url] if a source ever supplies
/// one. Each tier only ever *covers* the one below, so every failure degrades
/// by one step instead of falling all the way to nothing.
///
/// This is the one photo surface in the app that does **not** route through
/// `shared/widgets/listing_photo.dart`, and the exception is deliberate.
/// `ListingPhoto`'s whole contract is that a missing or failed photo becomes
/// an *opaque* themed placeholder — a `colors.sunk` box with a centred icon.
/// That is right for a listing card, where the placeholder is the only thing
/// there is to draw, and wrong here: painted over the card it would hide the
/// tiers underneath, turning the promo into exactly the grey broken-photo box
/// the fallbacks are meant to prevent. So the failure state is *nothing at
/// all* — a zero-size box that lets the layer beneath show through — which no
/// shared placeholder can express. The invariant `ListingPhoto` protects still
/// holds: no `errorBuilder`-less `Image.network` anywhere, and no state that
/// renders a broken-image glyph.
class _PromoPhoto extends StatelessWidget {
  const _PromoPhoto({required this.assetPath, required this.url});

  final String? assetPath;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final tiers = <Widget>[
      if (assetPath != null && assetPath!.isNotEmpty)
        Image.asset(
          assetPath!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // A bundled asset can only fail if the build dropped it, but the
          // gradient beneath is exactly the right answer if it ever does.
          errorBuilder: (context, error, stackTrace) => _fallback,
        ),
      if (url != null && url!.isNotEmpty)
        Image.network(
          url!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _fallback,
          // Nothing, not a spinner: while the remote tier loads, the asset
          // under it is already the finished card.
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _fallback,
        ),
    ];

    if (tiers.isEmpty) return _fallback;
    if (tiers.length == 1) return tiers.single;
    return Stack(fit: StackFit.expand, children: tiers);
  }

  /// Keyed so the fallback path is assertable —
  /// `test/features/home/promo_carousel_test.dart` drives it by letting the
  /// test harness fail every network image, which is what a device with no
  /// connection does too.
  static const Widget _fallback = SizedBox.shrink(
    key: ValueKey('promoBannerPhotoFallback'),
  );
}
