/// Barrel for the `contact-sheet` feature (SCREENS.md §3.11). A screen that
/// needs the sheet imports this one file and calls [showContactSheet];
/// nothing here is a route, because the sheet is not one (SCREENS.md §1
/// buckets it under "Bottom sheet", alongside `filter-sheet`).
library;

export 'data/contact_prefill.dart';
export 'data/contact_repository.dart';
export 'state/contact_repository_provider.dart';
export 'widgets/contact_sheet.dart';
