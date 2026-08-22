/// The real, network-backed [ContactRepository] — a thin adapter over
/// [LaCasaApi.contact], deliberately catching nothing. Unlike the agent
/// fetch in `listing-detail`, a failure here must reach the caller: the
/// user typed something and is entitled to know it didn't arrive.
library;

import '../../../api/api.dart';
import 'contact_repository.dart';

class LiveContactRepository implements ContactRepository {
  const LiveContactRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<void> submit(ContactRequest request) => _api.contact.submit(request);
}
