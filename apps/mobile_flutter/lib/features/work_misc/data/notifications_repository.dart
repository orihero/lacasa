/// Data-access seam for `notifications` (SCREENS.md §22).
///
/// **Contract ruling 7.11: there is no `notifications` endpoint anywhere in
/// `apps/api`.** [FixtureNotificationsRepository] renders §4.4's seed data
/// verbatim, which is the one ruling this contract actually makes. A live
/// implementation is explicitly optional ("a real design decision beyond
/// this contract's scope") — [LiveNotificationsRepository] is this
/// feature's own attempt at one, folding real `GET /leads` + `GET /my/ads`
/// + `GET /statistics/coworkers` + `GET /coworkers` data into the same
/// display shape, kept behind its own always-off `*_mode.dart` switch like
/// every other live repository in this app. See that file's own doc
/// comment for exactly what it can and can't honestly synthesize.
///
/// **Return type is [WorkNotificationFixture]** (from
/// `lib/shared/fixtures/work_seed_data.dart`), reused rather than a new
/// parallel model — that class's own doc comment anticipates a live source
/// "will need its own live-mode type," but on inspection the two sources
/// need exactly the same five fields (id/kind/title/relativeTime/unread/
/// targetId) to drive this screen's rows, and [relativeTime] is already
/// documented as "display-ready ... a live-mode notifications source is
/// free to use real [DateTime]s" — i.e. a live source computing its own
/// relative-time string and handing back the same shape was anticipated,
/// just not required. Introducing a second, structurally-identical class
/// here would only be a rename.
library;

import '../../../shared/shared.dart';

abstract class NotificationsRepository {
  /// Every notification row, most-recent-first — §22's "Rows" list, one
  /// fetch, no pagination (nothing in §4.4's seed data or any live source
  /// this repository folds implies one).
  Future<List<WorkNotificationFixture>> fetchNotifications();
}
