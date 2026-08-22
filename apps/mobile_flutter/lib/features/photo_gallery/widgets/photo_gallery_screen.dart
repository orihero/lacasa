/// `photo-gallery` (SCREENS.md §3.8) — a full-screen, no-chrome swipeable
/// lightbox reached from `listing-detail`'s photo carousel. See
/// `../photo_gallery.dart` for why this feature has no repository/state
/// layer, and `../photo_gallery_args.dart` for the exact `extra:` contract
/// the router needs to wire this in.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../data/gallery_item.dart';
import '../photo_gallery_args.dart';
import 'gallery_media_view.dart';
import 'gallery_page_dots.dart';
import 'gallery_thumbnail_strip.dart';
import 'gallery_top_overlay.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key, required this.args});

  final PhotoGalleryArgs args;

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late final List<GalleryItem> _items;
  late final PageController _pageController;
  late int _currentIndex;

  /// True while the currently-visible slide is pinch-zoomed in. Locks the
  /// `PageView`'s own swipe physics for that duration — see
  /// `GalleryMediaView`'s doc comment for why zoom and swipe can't both
  /// listen to the same drag at once.
  bool _swipeLocked = false;

  /// SCREENS.md §5 ("Gallery swipe"): "tapping the image toggles the
  /// thumbnail strip and counter chrome". The mockup's stage carries the
  /// same `data-gal-chrome` hook.
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _items = resolveGalleryItems(widget.args.ad);
    _currentIndex = _items.isEmpty
        ? 0
        : widget.args.startIndex.clamp(0, _items.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// A tap anywhere on the stage flips the chrome — except while the slide
  /// is pinch-zoomed, where a tap is part of the zoom interaction and
  /// hiding the way out mid-gesture would be hostile.
  void _toggleChrome() {
    if (_swipeLocked) return;
    setState(() => _chromeVisible = !_chromeVisible);
  }

  /// SCREENS.md §5: "swipe down or tap 'X' dismisses to listing-detail".
  /// Velocity-gated so a slow vertical drag inside a zoomed photo (which
  /// pans instead) never closes the screen out from under the user.
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_swipeLocked) return;
    if ((details.primaryVelocity ?? 0) > 320) _close();
  }

  void _jumpTo(int index) {
    setState(() => _swipeLocked = false);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _items.isEmpty
            ? _EmptyGallery(onClose: _close)
            : _populatedGallery(),
      ),
    );
  }

  Widget _populatedGallery() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleChrome,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: PageView.builder(
            controller: _pageController,
            physics: _swipeLocked
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            itemCount: _items.length,
            onPageChanged: (i) {
              setState(() {
                _currentIndex = i;
                _swipeLocked = false;
              });
            },
            itemBuilder: (context, i) {
              return GalleryMediaView(
                key: ValueKey('gallery-slide-$i-${_items[i].url}'),
                item: _items[i],
                onZoomChanged: (zoomed) {
                  if (i != _currentIndex) return;
                  if (zoomed != _swipeLocked) {
                    setState(() => _swipeLocked = zoomed);
                  }
                },
              );
            },
          ),
        ),
        // All of the chrome fades together on tap, and stops taking taps
        // while it is out of the way.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_chromeVisible,
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GalleryTopOverlay(
                    currentIndex: _currentIndex,
                    total: _items.length,
                    onClose: _close,
                    onStep: (delta) => _jumpTo(_currentIndex + delta),
                  ),
                  if (_items.length > 1) ...[
                    Positioned(
                      left: AppSpacing.xl,
                      right: AppSpacing.xl,
                      bottom:
                          GalleryThumbnailStrip.bottomInset +
                          GalleryThumbnailStrip.reservedHeight +
                          AppSpacing.sm,
                      child: Center(
                        child: GalleryPageDots(
                          total: _items.length,
                          currentIndex: _currentIndex,
                        ),
                      ),
                    ),
                    GalleryThumbnailStrip(
                      items: _items,
                      currentIndex: _currentIndex,
                      onSelect: _jumpTo,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white54,
                  size: 40,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  AppLocalizations.of(context).galleryEmptyStateMessage,
                  textAlign: TextAlign.center,
                  style: type.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.base,
          left: AppSpacing.base,
          child: GalleryCloseButton(onTap: onClose),
        ),
      ],
    );
  }
}
