/// The `extra:` payload `RoutePaths.tour3dView` expects. `tour3dView` (like
/// `photoGallery`/`mapView`) carries zero path params — see
/// `route_paths.dart` — so `extra:` is the only channel `listing-detail`'s
/// 3D Tour section has to tell that screen which URL to open.
///
/// A bare `String` would work just as well for the one field this carries
/// today, but every other `extra:` payload in the app is a named type (see
/// `PhotoGalleryArgs`) precisely so `state.extra is! X` at the route
/// boundary reads as "wrong/missing payload" rather than "wrong string
/// showed up here by coincidence" — a raw `String` could just as easily be
/// a stray value from a different route's fallback.
library;

class Tour3dViewArgs {
  const Tour3dViewArgs({required this.url});

  /// Already validated by the pusher (`ListingTourSection`) against
  /// [Ad.tour3dLink]'s non-null check, but **not** trusted as validated by
  /// the time it reaches [Tour3dViewScreen] — that screen re-checks the
  /// scheme itself. See its doc comment for why a second check at the
  /// render boundary is not redundant with the server's write-boundary one.
  final String url;
}
