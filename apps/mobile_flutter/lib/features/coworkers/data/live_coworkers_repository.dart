/// The real, network-backed [CoworkersRepository] — a thin adapter over
/// [LaCasaApi] that adds no wire shapes of its own, matching
/// `live_agents_repository.dart`'s own rule.
///
/// [summary] goes through [StatisticsResource.coworkersSummary] — always
/// the caller's team's complete, unfiltered history (no `filterType`/
/// date-range param on that endpoint either), same as the raw
/// `StatisticsResource.coworkers` feed this used to fold client-side.
library;

import '../../../api/api.dart';
import 'coworkers_repository.dart';

class LiveCoworkersRepository implements CoworkersRepository {
  const LiveCoworkersRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<Coworker>> list() => _api.coworkers.list();

  @override
  Future<Coworker> getById(String id) => _api.coworkers.getById(id);

  @override
  Future<Coworker> create({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatar,
  }) => _api.coworkers.create(
    fullName: fullName,
    email: email,
    password: password,
    phoneNumber: phoneNumber,
    avatar: avatar,
  );

  @override
  Future<Coworker> update(
    String id, {
    OptionalField<String>? fullName,
    OptionalField<String>? email,
    OptionalField<String?>? phoneNumber,
    OptionalField<String?>? avatar,
    OptionalField<String>? password,
  }) => _api.coworkers.update(
    id,
    fullName: fullName,
    email: email,
    phoneNumber: phoneNumber,
    avatar: avatar,
    password: password,
  );

  @override
  Future<void> delete(String id) => _api.coworkers.delete(id);

  @override
  Future<List<CoworkerSummary>> summary() => _api.statistics.coworkersSummary();
}
