/// The real, network-backed [CoworkersRepository] — a thin adapter over
/// [LaCasaApi] that adds no wire shapes of its own, matching
/// `live_agents_repository.dart`'s own rule.
///
/// [ads] goes through [AgentAdsResource.myList] (not the public
/// [AdsResource]) so it returns every stage (ACTIVE/SOLD/DRAFT) — a coworker
/// listings count that silently dropped a coworker's sold/draft ads would
/// undercount them. [activity] goes through [StatisticsResource.coworkers],
/// which — see that method's own doc comment — ignores any date-range
/// concept entirely; there is nothing to filter on here.
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
  Future<List<Ad>> ads() => _api.agentAds.myList();

  @override
  Future<List<ActivityEvent>> activity() => _api.statistics.coworkers();
}
