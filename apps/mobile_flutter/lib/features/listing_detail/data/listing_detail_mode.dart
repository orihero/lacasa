/// Chooses which [ListingDetailRepository] the screen runs on: bundled
/// fixtures (default) or the real [LaCasaApi]. Same compile-time-switch
/// shape, and the same reasoning, as `features/home/data/home_feed_mode.dart`
/// — read that file's doc comment for why this is a `--dart-define` rather
/// than something derived from `lib/api/env.dart`'s base URL.
///
/// **To point listing-detail at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_LISTING_DETAIL_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
///
/// One consequence worth stating, since fixtures are the default: the ids
/// the fixture repository can resolve are exactly the eight in
/// `listing_detail_fixtures.dart` (`ad-1001`…`ad-1008`). Those are also the
/// ids Home's and Search's fixture feeds hand out, so tapping any card in
/// the default build lands on a real listing — but a deep link to a live
/// UUID will render the not-found state until this switch is on.
const bool useLiveListingDetailApi = bool.fromEnvironment(
  'LACASA_LISTING_DETAIL_LIVE_API',
);
