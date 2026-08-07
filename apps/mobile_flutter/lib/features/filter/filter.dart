/// Barrel for `lib/features/filter/` — same convention as
/// `features/search/search.dart` and `features/home/home.dart`.
///
/// Unlike the other buyer-browse features, nothing here is wired into
/// `app_router.dart`: SCREENS.md §1 buckets `filter-sheet` as a bottom
/// sheet, not a route. The entry point is [showFilterSheet], called from
/// whichever screen owns a "Filters" button — `listing-search` today, and
/// `my-listings` later via `FilterSheet`'s unwired `isCrm` seam.
library;

export 'widgets/filter_sheet.dart';
