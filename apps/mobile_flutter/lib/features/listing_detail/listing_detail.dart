/// Barrel for the `listing-detail` feature (SCREENS.md §3.7) —
/// `lib/navigation/app_router.dart` needs only this one import to wire both
/// branch routes that reach it (`/home/listing/:id`, `/search/listing/:id`).
///
/// The repository provider is exported too, because it is the seam widget
/// tests override to run the screen against a fake instead of the bundled
/// fixtures; nothing in the app itself should read it directly.
library;

export 'data/listing_detail_repository.dart';
export 'state/listing_detail_providers.dart';
export 'state/listing_detail_repository_provider.dart';
export 'widgets/listing_detail_screen.dart';
