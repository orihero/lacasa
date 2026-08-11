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
import '../../../theme/theme.dart';
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

  static const double _size = 56;

  /// The vertical footprint this strip reserves at the bottom of the
  /// screen (its own height) — exposed so `photo_gallery_screen.dart` can
  /// stack [GalleryPageDots] just above it without the two overlapping.
  static const double reservedHeight = _size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: AppSpacing.lg,
      child: SizedBox(
        height: _size,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, i) {
            final active = i == currentIndex;
            final item = items[i];
            return Semantics(
              button: true,
              selected: active,
              label: AppLocalizations.of(context).galleryThumbnailSemanticsLabel(
                i + 1,
                items.length,
              ),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: active ? Colors.white : Colors.white24,
                      width: active ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: item.isPhoto
                      ? (item.url.isEmpty
                            ? const _ThumbPlaceholder(icon: Icons.image_rounded)
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
