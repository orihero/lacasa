/// Data-access seam for all three coworker screens — `coworkers-list`
/// (SCREENS.md §35), `coworker-detail` (§36) and `add-coworker` (§37). Two
/// implementations: [FixtureCoworkersRepository] (bundled seed data, no
/// network) and [LiveCoworkersRepository] (the real [LaCasaApi]) — see
/// `coworkers_mode.dart` for which one the app wires up by default.
///
/// **Five CRUD methods plus one read-only aggregate.** [summary] backs
/// `coworkers-list`'s "Ads count" row and `coworker-detail`'s "N listings ·
/// Active {relative time}" summary line — [Coworker] itself carries neither
/// figure (see that model's own doc comment). This used to be two separate
/// methods ([ads]/[activity], long since removed) that a screen folded by
/// `coworkerId` itself; `GET /statistics/coworkers/summary` now does that
/// fold server-side, so this repository has one aggregate method instead of
/// two raw-material ones. Kept independent of [list] (not bundled into its
/// return shape) so a failed summary fetch degrades only the derived
/// figures, never the roster itself — the same failure-isolation rule
/// `agents_repository.dart`'s `fetchAgentAds` split follows.
///
/// **"Sale count" used to have no method here at all — that was wrong.**
/// WORK_TAB_CONTRACT.md's ruling 7.6 originally read "no such status exists
/// anywhere in this schema" as "there is nothing to derive this from," but
/// `ActivityEventStage.adSold` events always carried `coworkerId`, and
/// `GET /statistics/coworkers/summary` folds them into
/// [CoworkerSummary.adsSoldCount] — real data, now covered by [summary]
/// along with the other two figures.
library;

import '../../../api/api.dart';

abstract class CoworkersRepository {
  /// `GET /coworkers` — every coworker on the caller's team. Returns an
  /// empty list rather than throwing when there are none; the empty state
  /// is `coworkers-list`'s own job.
  Future<List<Coworker>> list();

  /// One coworker, for `coworker-detail`. Throws [ApiErrorException]
  /// `code: notFound` for an unknown id or one outside the caller's team.
  Future<Coworker> getById(String id);

  /// `POST /coworkers`. Throws [ApiErrorException] with `code: forbidden`
  /// (a COWORKER-role caller), `code: solo_realtor` (a SOLO agent — see
  /// `coworkers_resource.dart`'s own doc comment for the exact copy),
  /// `code: validation`, or `code: emailTaken`. Every one of those carries
  /// the server's own words in [ApiErrorException.message] — see
  /// `add_coworker_screen.dart`'s doc comment for why this repository
  /// doesn't try to pre-classify `solo_realtor` any further than "a 403
  /// with a message worth showing verbatim".
  Future<Coworker> create({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatar,
  });

  /// `PATCH /coworkers/:id`. AGENT only, regardless of solo/agency — see
  /// `apps/api/src/routes/coworkers.js`'s `PATCH` handler, which has no
  /// `realtorKind` check at all (only [create] does). Uses the
  /// [OptionalField] omit/clear-vs-set convention throughout — see that
  /// class's own doc comment.
  Future<Coworker> update(
    String id, {
    OptionalField<String>? fullName,
    OptionalField<String>? email,
    OptionalField<String?>? phoneNumber,
    OptionalField<String?>? avatar,
    OptionalField<String>? password,
  });

  /// `DELETE /coworkers/:id`. AGENT only. Throws `code: notFound` for an
  /// unknown id or one outside the caller's team.
  Future<void> delete(String id);

  /// `GET /statistics/coworkers/summary` — one [CoworkerSummary] row per
  /// coworker on the caller's team (ads created/sold, leads created,
  /// last-active timestamp). Independent of [list] so a failed summary
  /// fetch degrades only the derived figures, never the roster — see this
  /// file's own doc comment.
  Future<List<CoworkerSummary>> summary();
}
