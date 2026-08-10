/// The real, network-backed [LeadsRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own.
library;

import '../../../api/api.dart';
import 'leads_repository.dart';

class LiveLeadsRepository implements LeadsRepository {
  const LiveLeadsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<Lead>> list() => _api.leads.list();

  @override
  Future<Lead> getById(String id) => _api.leads.getById(id);

  @override
  Future<Lead> create(LeadWriteInput input) => _api.leads.create(input);

  @override
  Future<Lead> update(String id, LeadWriteInput input) =>
      _api.leads.update(id, input);

  @override
  Future<void> delete(String id) => _api.leads.delete(id);

  @override
  Future<List<Coworker>> coworkers() => _api.coworkers.list();
}
