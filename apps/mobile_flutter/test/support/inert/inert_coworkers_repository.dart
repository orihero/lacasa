/// A [CoworkersRepository] that answers everything with nothing.
///
/// **Why this exists.** `lib/api/app_mode.dart` used to force a bundled
/// `FixtureCoworkersRepository` under `FLUTTER_TEST`; that fixture is gone
/// and the guard with it, so `coworkersRepositoryProvider` now
/// unconditionally builds [LiveCoworkersRepository] around
/// `LaCasaApi.create()`. Any widget test that mounts the real router gets
/// the app shell, and the shell reaches into far more repositories than the
/// screen under test — so an un-overridden provider fires real HTTP out of
/// the test process, hangs, and the test dies on `pumpAndSettle timed out`
/// with nothing pointing at the cause. Overriding the provider with this
/// class makes that whole class of failure impossible.
///
/// **Deliberately inert, and only that.** Every method returns the emptiest
/// value its signature permits and none of them throw — an empty roster, an
/// empty summary, and, for the three methods whose return type is a
/// non-nullable [Coworker], a zero-valued placeholder (empty ids, empty
/// strings, null contact fields). It is not a stand-in for the real
/// repository and it deliberately does not remember anything: [create] does
/// not add to what [list] returns, and [delete] does not remove from it. A
/// test that wants coworker behaviour — a populated roster, a
/// `code: notFound` on [getById], the `solo_realtor` rejection [create]
/// raises for a solo agent — should not extend or bend this class. It
/// should override the provider with a purpose-built fake from
/// `test/features/coworkers/support/` that models exactly the behaviour it
/// asserts on.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/data/coworkers_repository.dart';

/// The neutral [Coworker] the three object-returning methods hand back.
///
/// [Coworker] has no empty value of its own — all six fields are required
/// and three of them are non-nullable [String]s — so "return nothing" has to
/// be spelled as a fully zeroed instance. Empty ids are intentional: a
/// screen that routes or fetches off `id`/`agentId` gets an obviously blank
/// value rather than a plausible-looking one that could quietly pass an
/// assertion.
const Coworker _inertCoworker = Coworker(
  id: '',
  fullName: '',
  email: '',
  phoneNumber: null,
  avatar: null,
  agentId: '',
);

class InertCoworkersRepository implements CoworkersRepository {
  const InertCoworkersRepository();

  @override
  Future<List<Coworker>> list() async => const [];

  @override
  Future<Coworker> getById(String id) async => _inertCoworker;

  @override
  Future<Coworker> create({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatar,
  }) async => _inertCoworker;

  @override
  Future<Coworker> update(
    String id, {
    OptionalField<String>? fullName,
    OptionalField<String>? email,
    OptionalField<String?>? phoneNumber,
    OptionalField<String?>? avatar,
    OptionalField<String>? password,
  }) async => _inertCoworker;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<CoworkerSummary>> summary() async => const [];
}
