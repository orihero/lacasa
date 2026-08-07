/// The `extra:` payload `RoutePaths.photoGallery` expects. `mapView` and
/// `photoGallery` both carry zero path params (see `route_paths.dart`), so
/// go_router's `extra:` is the only channel `listing-detail` has to tell
/// this screen which ad's photos to open and which one was tapped.
///
/// **Router wiring the integration agent needs** — the one-line
/// `app_router.dart` change (do not make it yourself, see that file's own
/// "DO NOT EDIT" note):
/// ```dart
/// import 'package:lacasa_mobile/features/photo_gallery/photo_gallery.dart';
///
/// GoRoute(
///   path: RoutePaths.photoGallery,
///   parentNavigatorKey: rootNavigatorKey,
///   builder: (context, state) =>
///       PhotoGalleryScreen(args: state.extra as PhotoGalleryArgs),
/// ),
/// ```
/// and the call site inside `listing-detail` (SCREENS.md §3.7: "Photo/
/// video carousel ... tap → `photo-gallery`"):
/// ```dart
/// context.push(
///   RoutePaths.photoGallery,
///   extra: PhotoGalleryArgs(ad: ad, startIndex: tappedIndex),
/// );
/// ```
library;

import '../../api/api.dart';

class PhotoGalleryArgs {
  const PhotoGalleryArgs({required this.ad, this.startIndex = 0});

  /// The ad whose `media`/`photos` the gallery renders — see
  /// `data/gallery_item.dart#resolveGalleryItems` for which field wins.
  /// Passing the whole `Ad` (rather than a pre-resolved photo list) keeps
  /// the media-vs-photos resolution rule in one place (this feature) so
  /// `listing-detail` doesn't have to duplicate it — see that file's doc
  /// comment.
  final Ad ad;

  /// Which slide to open on, 0-indexed — the index of whichever photo the
  /// user tapped in `listing-detail`'s carousel. Out-of-range values
  /// (negative, or >= the resolved item count) clamp rather than throw;
  /// see `widgets/photo_gallery_screen.dart`.
  final int startIndex;
}
