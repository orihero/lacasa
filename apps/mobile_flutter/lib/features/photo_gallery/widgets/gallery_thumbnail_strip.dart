/// Bottom thumbnail strip — "bottom thumbnail strip (tap to jump)" per
/// SCREENS.md §3.8.
///
/// Deliberately hand-rolls its own tiny image-with-fallback rendering
/// rather than reusing `shared/widgets/listing_photo.dart`'s
/// [ListingPhoto]: a thumbnail also has to represent a *video* slide with
/// a distinct glyph (see `gallery_media_view.dart`'s doc comment for why
/// that's not the same thing as "photo failed to load"), which
/// `ListingPhoto`'s single generic-image-icon fallback doesn't
/// distinguish. Reusing it here would mean either accepting that
/// conflation or forking its internals anyway — hand-rolling is honest
/// about which contract this is.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/gallery_item.dart';

class GalleryThumbnailStrip extends StatelessWidget {
  const GalleryThumbnailStrip({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<GalleryItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// `.gv__th{width:62px;height:62px;border-radius:14px;opacity:.5}` with
  /// `.gv__th.on{opacity:1;box-shadow:0 0 0 2px #fff}` — the inactive tile
  /// is dimmed, not outlined; only the active one takes a ring.
  static const double _size = 62;
  static const double _radius = 14;

  /// The vertical footprint this strip reserves at the bottom of the
  /// screen (its own height) — exposed so `photo_gallery_screen.dart` can
  /// stack [GalleryPageDots] just above it without the two overlapping.
  static const double reservedHeight = _size;

  /// `.gv__strip{bottom:24px}` — exposed for the same reason.
  static const double bottomInset = 24;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      // `.gv__strip{bottom:24px;gap:9px;padding:0 18px}`.
      bottom: bottomInset,
      child: SizedBox(
        height: _size,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 9),
          itemBuilder: (context, i) {
            final active = i == currentIndex;
            final item = items[i];
            return Semantics(
              button: true,
              selected: active,
              label: AppLocalizations.of(
                context,
              ).galleryThumbnailSemanticsLabel(i + 1, items.length),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: active ? 1 : 0.5,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_radius),
                      border: active
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.isPhoto
                        ? (item.url.isEmpty
                              ? const _ThumbPlaceholder(
                                  icon: Icons.image_rounded,
                                )
                              : Image.network(
                                  item.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const _ThumbPlaceholder(
                                        icon: Icons.image_rounded,
                                      ),
                                ))
                        : const _ThumbPlaceholder(icon: Icons.videocam_rounded),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white12,
      child: Center(child: Icon(icon, color: Colors.white38, size: 18)),
    );
  }
}
