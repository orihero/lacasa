/// One full-bleed slide of `photo-gallery`.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../theme/theme.dart';
import '../data/gallery_item.dart';

/// Photos get pinch-to-zoom via a plain SDK [InteractiveViewer] — Flutter
/// ships this, no zoom package needed (the assignment's own §7 confirms
/// this is the one "gap" that isn't actually a gap).
///
/// Non-photo media (currently `AdMediaType.video`, plus the `unknown`
/// fallback every enum in this codebase carries) is deliberately **not**
/// run through [Image.network]: the wire URL is a video, not an image, so
/// loading it as one would either fail outright or — worse — silently
/// succeed against whatever unrelated resource happens to live at that
/// URL. Either way, [Image.network]'s `errorBuilder` path paints the exact
/// same "broken image" glyph used for a genuinely missing photo, which
/// conflates "we have no picture at all" with "we have a video here, this
/// screen just can't preview it" — a dishonest merge of two different
/// facts. This renders an explicit, correctly-labeled tile instead. No
/// video-player package is installed (see the assignment's §7 gap list),
/// so actual playback is out of scope for this pass — flagged in the
/// implementation report.
class GalleryMediaView extends StatefulWidget {
  const GalleryMediaView({
    super.key,
    required this.item,
    required this.onZoomChanged,
  });

  final GalleryItem item;

  /// Called whenever this slide's zoom crosses the 1.0 boundary, so the
  /// parent `PageView` can lock its own swipe physics while the visible
  /// slide is zoomed in. Pinch-zoom and swipe-to-next-photo are mutually
  /// exclusive readings of the same horizontal drag gesture — without
  /// this, `InteractiveViewer` and `PageView` fight over who owns it, and
  /// a user trying to pan a zoomed-in photo accidentally flips to the next
  /// one instead.
  final ValueChanged<bool> onZoomChanged;

  @override
  State<GalleryMediaView> createState() => _GalleryMediaViewState();
}

class _GalleryMediaViewState extends State<GalleryMediaView> {
  final _transformationController = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _handleTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.01;
    if (zoomed != _zoomed) {
      _zoomed = zoomed;
      widget.onZoomChanged(zoomed);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.isPhoto) {
      return _UnsupportedMediaTile(item: widget.item);
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1,
      maxScale: 4,
      child: _GalleryImage(url: widget.item.url),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _BrokenPhotoTile();

    return Center(
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const _BrokenPhotoTile(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Same "never a broken-image glyph, always a themed placeholder" contract
/// as `shared/widgets/listing_photo.dart`'s `ListingPhoto`, hand-rolled
/// here rather than imported: this canvas is intentionally black
/// regardless of app theme (a lightbox, not app chrome — matches
/// `GlassVariant.onPhoto`'s own "fixed, non-themed" contract used for the
/// overlay controls), whereas `ListingPhoto`'s placeholder is themed to
/// `LaCasaColors.sunk`/`.faint` for light or dark app surfaces. Two
/// genuinely different visual contexts, so this stays a small local
/// widget rather than a copy-with-override of the shared one.
class _BrokenPhotoTile extends StatelessWidget {
  const _BrokenPhotoTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.white38,
        size: 40,
      ),
    );
  }
}

class _UnsupportedMediaTile extends StatelessWidget {
  const _UnsupportedMediaTile({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isVideo = item.mediaType == AdMediaType.video;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_rounded : Icons.help_outline_rounded,
              color: Colors.white54,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              isVideo
                  ? "Video preview isn't available in the gallery yet."
                  : "This media type can't be previewed.",
              textAlign: TextAlign.center,
              style: type.body.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
