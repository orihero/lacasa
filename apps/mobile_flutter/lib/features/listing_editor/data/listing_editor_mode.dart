/// Chooses which [ListingEditorRepository] the feature's four screens run
/// on: the real [LaCasaApi] (default) or bundled fixtures — resolved
/// through `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to.
///
/// **To force the listing editor to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_LISTING_EDITOR_LIVE_API=false
/// ```
///
/// **To point the listing editor at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveListingEditorApi = resolveUseLiveApi(
  const String.fromEnvironment(
    'LACASA_LISTING_EDITOR_LIVE_API',
    defaultValue: '',
  ),
);
