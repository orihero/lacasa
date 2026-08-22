/// `listing-detail`'s hero: the photo/video carousel with the address,
/// title and price/spec pills laid over its lower third (SCREENS.md §3.7,
/// mockup `.hero`/`.hero__b`).
///
/// **Tapping any slide opens `photo-gallery` at that slide's index** — the
/// call site `photo_gallery_args.dart` documents. The whole [Ad] is handed
/// over rather than a resolved photo list, so the media-vs-photos
/// resolution rule stays owned by the gallery feature; this widget calls
/// the same [resolveGalleryItems] only to know how many slides to build.
///
/// **An ad with no media still renders a hero**, showing [ListingPhoto]'s
/// themed placeholder rather than collapsing — the title, address and price
/// are the point of this block and none of them depend on a photo existing.
/// Tapping it still opens the gallery, which has its own honest "No photos
/// available for this listing" state; that is a better answer than a dead
/// tap target that silently does nothing.
///
/// **A video slide is labeled, not advertised as playable.** It used to
/// carry `Icons.play_circle_outline_rounded` — the universal "press here
/// and it plays" glyph — while the gallery it opens has no video player at
/// all and answers with "Video preview isn't available in the gallery yet."
/// Two taps from a promise to a refusal, on the richest asset a listing
/// carries. Until a real player lands, the slide states the medium instead
/// of promising an action: a neutral `videocam_outlined` placeholder plus a
/// "Video" badge ([_VideoBadge]). The badge is not a button and does not
/// look like one — the exit from a video slide belongs on the gallery's own
/// tile, where the URL is in hand.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../photo_gallery/data/gallery_item.dart';

class ListingHero extends StatefulWidget {
  const ListingHero({
    super.key,
    required this.ad,
    required this.onOpenGallery,
  });

  final Ad ad;

  /// Called with the index of the tapped slide.
  final void Function(int index) onOpenGallery;

  /// `.hero{height:388px}`. Exposed so the screen can reserve the same
  /// height in its loading skeleton and not jump when the ad arrives.
  static const double height = 388;

  @override
  State<ListingHero> createState() => _ListingHeroState();
}

class _ListingHeroState extends State<ListingHero> {
  late final List<GalleryItem> _items;
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _items = resolveGalleryItems(widget.ad);
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `.hero{margin:0 7px}` — the hero is inset from the screen edge by
      // less than the 20px body gutter, deliberately.
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: SizedBox(
        height: ListingHero.height,
        child: ClipRRect(
          borderRadius: AppRadii.hero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _slides(),
              const _HeroVeil(),
              // Mirrors the slide counter's vertical arithmetic on the
              // opposite edge, so the badge clears `.hero__nav`'s back
              // button the same way the counter clears share/save. Gated on
              // the *visible* slide: a hero whose second slide is a video
              // must not claim the first one is.
              if (_currentIsVideo)
                Positioned(
                  left: AppSpacing.lg,
                  top:
                      MediaQuery.of(context).padding.top +
                      AppSpacing.base +
                      42 +
                      AppSpacing.sm,
                  child: const _VideoBadge(
                    key: ValueKey('listingHeroVideoBadge'),
                  ),
                ),
              if (_items.length > 1)
                Positioned(
                  right: AppSpacing.lg,
                  // Below `.hero__nav`, which floats over this hero from
                  // the screen's own Stack (`listing_detail_nav.dart`) at
                  // `top: AppSpacing.base` *inside a SafeArea*, with 42px
                  // buttons. The hero is the first child of an unpadded
                  // ListView, so it starts at y=0 and receives no status-
                  // bar inset of its own — a fixed offset therefore drew
                  // the counter underneath the share/save buttons on every
                  // device with a notch. Mirror the nav's own arithmetic
                  // instead, plus a gap.
                  top:
                      MediaQuery.of(context).padding.top +
                      AppSpacing.base +
                      42 +
                      AppSpacing.sm,
                  child: _SlideCounter(
                    current: _index + 1,
                    total: _items.length,
                  ),
                ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: 15,
                child: _HeroCaption(ad: widget.ad),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// True when the slide currently in view is a video, so the badge tracks
  /// the carousel rather than the ad as a whole.
  bool get _currentIsVideo =>
      _index < _items.length &&
      _items[_index].mediaType == AdMediaType.video;

  Widget _slides() {
    if (_items.isEmpty) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onOpenGallery(0),
        child: const ListingPhoto(url: null),
      );
    }

    return PageView.builder(
      controller: _controller,
      itemCount: _items.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) {
        final item = _items[i];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onOpenGallery(i),
          // A video's poster frame isn't something the wire gives us, so a
          // non-photo slide shows the placeholder here; the gallery owns
          // what happens next — see `gallery_media_view.dart`.
          //
          // `videocam_outlined`, never a play glyph: the placeholder names
          // what the slide holds without claiming a tap starts playback
          // this build cannot deliver (see this file's doc comment). The
          // `unknown` media type keeps a question mark for the same reason
          // — it is honestly unidentified, not a video.
          child: ListingPhoto(
            url: item.isPhoto ? item.url : null,
            icon: switch (item.mediaType) {
              AdMediaType.photo => Icons.image_rounded,
              AdMediaType.video => Icons.videocam_outlined,
              AdMediaType.unknown => Icons.help_outline_rounded,
            },
          ),
        );
      },
    );
  }
}

/// `.hero__veil` — the four-stop vertical scrim that keeps white caption
/// text legible over an arbitrary photo. Without it the title is
/// unreadable over a bright sky and fine over a dark interior, which is
/// not a contrast ratio anyone can rely on.
class _HeroVeil extends StatelessWidget {
  const _HeroVeil();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x3D0C0A16),
              Color(0x000C0A16),
              Color(0x570A0912),
              Color(0xC70A0912),
            ],
            stops: [0.0, 0.30, 0.62, 1.0],
          ),
        ),
      ),
    );
  }
}

/// A glass pill naming the visible slide's medium. Deliberately the same
/// `GlassVariant.onPhoto` chrome as [_SlideCounter] — informational hero
/// furniture, not a control — because the one thing this badge must not do
/// is read as "tap me to play". See this file's doc comment for the
/// promise-then-refuse loop it replaced.
class _VideoBadge extends StatelessWidget {
  const _VideoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      distortionWidth: 7,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_outlined,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).listingHeroVideoBadgeLabel,
            style: type.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// `{n}/{total}`, shown only for a multi-slide hero — a "1/1" counter tells
/// the user nothing they can act on.
class _SlideCounter extends StatelessWidget {
  const _SlideCounter({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      distortionWidth: 7,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        '$current/$total',
        style: LaCasaTypography.tabular(
          type.caption,
        ).copyWith(color: Colors.white),
      ),
    );
  }
}

/// `.hero__b` — address row, title, and the price/spec pill pair.
class _HeroCaption extends StatelessWidget {
  const _HeroCaption({required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final specLine = Formatters.statLine(ad);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // `.place` — pin icon + "{district}, {city}" (SCREENS.md §3.7's
        // address row).
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.place_rounded,
              size: 12,
              color: Color(0xDBFFFFFF),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                _placeLabel(ad),
                overflow: TextOverflow.ellipsis,
                style: type.bodySmall.copyWith(
                  color: const Color(0xDBFFFFFF),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          ad.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: type.heroTitle.copyWith(
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 14,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _HeroPill(label: Formatters.price(ad)),
            if (specLine.isNotEmpty) _HeroPill(label: specLine, thin: true),
          ],
        ),
      ],
    );
  }

  /// `{district}, {city}` — either half alone when the other is blank,
  /// rather than a dangling comma. The wire defaults both to `''` rather
  /// than null (see `Ad.fromJson`), so emptiness is the test, not null.
  static String _placeLabel(Ad ad) {
    return [
      ad.district,
      ad.city,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }
}

/// `.hpill g` — glass over photo, 27px tall.
class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, this.thin = false});

  final String label;
  final bool thin;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: BorderRadius.circular(14),
      distortionWidth: 7,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Text(
        label,
        style: LaCasaTypography.tabular(type.bodySmall).copyWith(
          color: Colors.white,
          fontWeight: thin ? FontWeight.w500 : FontWeight.w600,
        ),
      ),
    );
  }
}
