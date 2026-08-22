/// Barrel for the `photo-gallery` feature (SCREENS.md §3.8) —
/// `lib/navigation/app_router.dart` only needs this one import to wire the
/// `/photo-gallery` root-navigator route.
///
/// **No `data/<feature>_repository.dart` / fixture / live / mode split**,
/// unlike `features/home`'s canon layout. This screen never calls the
/// network itself: SCREENS.md's own API table for `photo-gallery` says
/// "No fetch — receives `Ad` (or just `photos`/`media`) via `extra:` from
/// `listing-detail`". A repository interface exists to abstract over
/// *how data arrives* (fixture literals vs. a live HTTP call); there is no
/// second "how" here to abstract over, so adding one would be a fixture
/// class with no live counterpart and a mode switch that never switches —
/// ceremony with nothing behind it. What the pattern *does* still apply
/// to is `data/gallery_item.dart`'s `resolveGalleryItems`, which plays the
/// same "reshape the wire model into what the screen wants" role a
/// repository normally would, just without an async boundary.
///
/// Same reasoning for `state/`: the only screen-local value
/// (`PhotoGalleryScreen`'s current page index) is transient, single-
/// instance-per-mount UI state — a `PageController`/`setState` concern,
/// the same category as a `TabController` — not shared app state another
/// widget elsewhere needs to read, so it stays local rather than promoted
/// to a Riverpod provider. If a future screen needs to *react* to which
/// gallery slide is open from outside this widget tree, that would be the
/// signal to add one.
library;

export 'photo_gallery_args.dart';
export 'widgets/photo_gallery_screen.dart';
