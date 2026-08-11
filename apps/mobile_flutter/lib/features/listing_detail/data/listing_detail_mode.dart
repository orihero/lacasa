/// Chooses which [ListingDetailRepository] the screen runs on: the real
/// [LaCasaApi] (default) or bundled fixtures — resolved through
/// `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to.
///
/// **To force listing-detail to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_LISTING_DETAIL_LIVE_API=false
/// ```
///
/// **To point listing-detail at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
///
/// One consequence worth stating, now that live is the default: a deep
/// link to an id fixtures can't resolve now correctly 404s against the
/// real backend instead of silently rendering seed content. Under the
/// explicit fixtures opt-in, the ids the fixture repository can resolve
/// are exactly the eight in `listing_detail_fixtures.dart`
/// (`ad-1001`…`ad-1008`) — the same ids Home's and Search's fixture feeds
/// hand out, so a fixtures-mode build stays internally consistent.
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveListingDetailApi = resolveUseLiveApi(
  const String.fromEnvironment(
    'LACASA_LISTING_DETAIL_LIVE_API',
    defaultValue: '',
  ),
);
