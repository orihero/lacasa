/// Offline stand-in for [CoworkersRepository], seeded from
/// `work_seed_data.dart`'s [workCoworkersFixtures]/[workAdsFixtures]/
/// [workStatisticsCoworkersFixture] (§4.3 of SCREENS.md). No network, no
/// [LaCasaApi] dependency — what all three coworker screens render from by
/// default (see `coworkers_mode.dart`).
///
/// **Mutations are real, in-memory, for the lifetime of this instance.**
/// [create]/[update]/[delete] mutate a private copy of the seed list rather
/// than either no-op-ing or throwing — a fixture "Save"/"Delete" that
/// silently did nothing would make `coworker-detail`/`add-coworker`
/// impossible to exercise with no network at all, which is exactly the
/// scenario this build must render sensibly through. `ads`/`activity` stay
/// static (nothing in this feature ever mutates an ad or an activity
/// event), matching `apps/console`'s own choice to keep those two lists
/// read-only inputs to `deriveCoworkerMetrics`.
///
/// **Failure modes mirror the live endpoint's shape**, same rule
/// `fixture_agents_repository.dart`'s 404 and `fixture_auth_repository.dart`'s
/// 401 already follow: an unknown id throws the identical [ApiErrorException]
/// (`notFound`, 404) the live API would, and a colliding email throws the
/// identical `emailTaken` (409) — a fixture whose failure mode differs from
/// production is a fixture that hides the bug it exists to reveal.
///
/// **Does not replicate the `solo_realtor` 403.** That check depends on the
/// *signed-in session's* `realtorKind`, which this repository has no
/// access to (it is constructed with no dependency on `authSessionProvider`,
/// matching every other fixture repository in this app) — and the screens
/// already gate the "+ Add new coworker" entry point on that same field via
/// `authSessionProvider` directly (WORK_TAB_CONTRACT.md's own instruction),
/// so a fixture-mode agent never reaches this repository's [create] while
/// SOLO in the first place. See `add_coworker_screen.dart`'s doc comment
/// for the full reasoning, including why this is flagged rather than worked
/// around.
library;

import '../../../api/api.dart';
import '../../../shared/fixtures/work_seed_data.dart';
import 'coworkers_repository.dart';

class FixtureCoworkersRepository implements CoworkersRepository {
  FixtureCoworkersRepository() : _coworkers = List.of(workCoworkersFixtures);

  final List<Coworker> _coworkers;

  int _nextId = 1;

  @override
  Future<List<Coworker>> list() async => List.unmodifiable(_coworkers);

  @override
  Future<Coworker> getById(String id) async {
    for (final coworker in _coworkers) {
      if (coworker.id == id) return coworker;
    }
    throw _notFound;
  }

  @override
  Future<Coworker> create({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatar,
  }) async {
    _assertEmailFree(email, excludingId: null);
    final created = Coworker(
      id: 'coworker-fixture-${_nextId++}',
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      avatar: avatar,
      // The two real coworkers in the seed data (`coworker-sardor`/
      // `coworker-kamola`) each report to a different agent
      // (`agent-javlon`/`agent-shahnoza` — see `work_seed_data.dart`'s own
      // note on this file's id scheme); a freshly-created fixture coworker
      // has no real signed-in agent id to inherit in an offline build with
      // no session-aware fixture wiring (see this file's doc comment), so
      // `agent-javlon` is as good a stand-in as any — nothing in this
      // feature keys off it besides this row's own `Coworker.agentId`.
      agentId: 'agent-javlon',
    );
    _coworkers.add(created);
    return created;
  }

  @override
  Future<Coworker> update(
    String id, {
    OptionalField<String>? fullName,
    OptionalField<String>? email,
    OptionalField<String?>? phoneNumber,
    OptionalField<String?>? avatar,
    OptionalField<String>? password,
  }) async {
    final index = _coworkers.indexWhere((c) => c.id == id);
    if (index == -1) throw _notFound;
    final current = _coworkers[index];

    if (email != null) _assertEmailFree(email.value, excludingId: id);

    final updated = Coworker(
      id: current.id,
      fullName: fullName != null ? fullName.value : current.fullName,
      email: email != null ? email.value : current.email,
      phoneNumber: phoneNumber != null ? phoneNumber.value : current.phoneNumber,
      avatar: avatar != null ? avatar.value : current.avatar,
      agentId: current.agentId,
    );
    _coworkers[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final removed = _coworkers.any((c) => c.id == id);
    if (!removed) throw _notFound;
    _coworkers.removeWhere((c) => c.id == id);
  }

  @override
  Future<List<Ad>> ads() async => workAdsFixtures;

  @override
  Future<List<ActivityEvent>> activity() async => workStatisticsCoworkersFixture;

  void _assertEmailFree(String email, {required String? excludingId}) {
    final normalized = email.trim().toLowerCase();
    final clash = _coworkers.any(
      (c) => c.id != excludingId && c.email.toLowerCase() == normalized,
    );
    if (clash) {
      throw ApiErrorException(
        statusCode: 409,
        body: const ApiErrorBody(
          code: ApiErrorCode.emailTaken,
          message: 'Email is already registered',
        ),
      );
    }
  }

  static final ApiErrorException _notFound = ApiErrorException(
    statusCode: 404,
    body: const ApiErrorBody(
      code: ApiErrorCode.notFound,
      message: 'Coworker not found',
    ),
  );
}
