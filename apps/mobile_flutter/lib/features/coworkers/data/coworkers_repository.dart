/// Data-access seam for all three coworker screens — `coworkers-list`
/// (SCREENS.md §35), `coworker-detail` (§36) and `add-coworker` (§37). Two
/// implementations: [FixtureCoworkersRepository] (bundled seed data, no
/// network) and [LiveCoworkersRepository] (the real [LaCasaApi]) — see
/// `coworkers_mode.dart` for which one the app wires up by default.
///
/// **Five CRUD methods plus two read-only "raw material" methods.**
/// [ads]/[activity] exist purely so a caller can derive `listingsCount`/
/// `lastActive` client-side — [Coworker] itself carries neither field (see
/// that model's own doc comment), matching `apps/console`'s own
/// `deriveCoworkerMetrics` helper (`apps/console/src/data/useCoworkers.ts`)
/// exactly: real numbers, folded from data that already has a wire
/// contract, never invented. Kept as two separate methods rather than
/// bundled into [list]'s own return shape so a failure in either degrades
/// only the derived figure it feeds, never the roster itself — the same
/// failure-isolation rule `agents_repository.dart`'s `fetchAgentAds` split
/// follows.
///
/// **"Deals closed" has no method here at all.** WORK_TAB_CONTRACT.md's
/// ruling 7.6 is explicit: that number is `LeadStatus.SUCCESS`-shaped and
/// no such status exists anywhere in this schema (Prisma, wire, or
/// otherwise) — there is nothing to derive, so no method pretends to derive
/// it. A screen wanting to say so renders an em dash directly, not a call
/// to a method that would have to invent a zero.
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

  /// Every ad visible to the caller's agent/coworker session — used purely
  /// to derive each coworker's listings count client-side
  /// (`Ad.coworkerId == coworker.id`), per WORK_TAB_CONTRACT.md ruling 7.6.
  /// Independent of [list] so an ads-fetch failure degrades only the
  /// derived count, never the roster.
  Future<List<Ad>> ads();

  /// Every [ActivityEvent] for the caller's agent — used purely to derive
  /// each coworker's "last active" timestamp client-side (the latest
  /// [ActivityEvent.createdAt] for a matching `coworkerId`), per ruling
  /// 7.6. Independent of [list]/[ads] for the same reason.
  Future<List<ActivityEvent>> activity();
}
