/// Data shape and resolution rule for what `photo-gallery` renders — one
/// wire `Ad`'s photo/video set reduced to an ordered, gallery-ready list.
///
/// This feature has no repository/fixture/live split (see
/// `lib/features/photo_gallery/photo_gallery.dart`'s doc comment for why):
/// the gallery never fetches anything of its own, it only reshapes the
/// `Ad` handed to it via `PhotoGalleryArgs`. This file is the entirety of
/// that reshaping.
library;

import '../../../api/api.dart';

/// One slide of the gallery: a media URL plus which kind it is. Kept
/// distinct from [AdMedia] (rather than rendering straight off it) so the
/// gallery's widgets have one shape to deal with regardless of whether it
/// came from `Ad.media` or the `Ad.photos` fallback — see
/// [resolveGalleryItems].
class GalleryItem {
  const GalleryItem({required this.url, required this.mediaType});

  final String url;
  final AdMediaType mediaType;

  /// True for `AdMediaType.photo` only — `video` and the enum's own
  /// `unknown` fallback both render the honest "can't preview this"
  /// tile in `widgets/gallery_media_view.dart` rather than being run
  /// through `Image.network`, which would either silently fail or paint
  /// a "broken image" glyph indistinguishable from a genuinely missing
  /// photo — see that file's doc comment.
  bool get isPhoto => mediaType == AdMediaType.photo;
}

/// Resolves the ordered list of gallery slides for [ad].
///
/// `Ad.media` is the richer, position-ordered, photo/video-aware source —
/// prefer it whenever the ad has any, sorted by [AdMedia.position] since
/// the wire order is not itself guaranteed. `Ad.photos` (flat image-URL
/// list, already server-filtered to photos only) is the fallback for ads
/// that only have `photos` populated — every bundled fixture ad across the
/// app currently ships this way, per
/// `features/home/data/home_feed_fixtures.dart`'s own doc comment
/// ("`photos`/`media` are deliberately left empty on every fixture ad" —
/// read literally that's `media` empty, `photos` populated on at least the
/// active fixtures, which is exactly the shape this fallback exists for).
///
/// Never invents a slide that isn't backed by the wire: an ad with neither
/// list populated resolves to an empty list, and `PhotoGalleryScreen`
/// renders an honest "no photos" state rather than a placeholder that
/// reads as real.
List<GalleryItem> resolveGalleryItems(Ad ad) {
  if (ad.media.isNotEmpty) {
    final sorted = [...ad.media]
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted
        .map((m) => GalleryItem(url: m.url, mediaType: m.mediaType))
        .toList();
  }
  return ad.photos
      .map((url) => GalleryItem(url: url, mediaType: AdMediaType.photo))
      .toList();
}
