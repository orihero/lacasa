/// The real, network-backed [ConnectedAccountsRepository] — a thin adapter
/// over [LaCasaApi.publish]/[LaCasaApi.instagramAuth], no new wire shapes
/// of its own, same rule `live_agents_repository.dart` follows.
library;

import '../../../api/api.dart';
import 'connected_accounts_repository.dart';

class LiveConnectedAccountsRepository implements ConnectedAccountsRepository {
  const LiveConnectedAccountsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() =>
      _api.publish.instagramAccounts();

  @override
  Future<String> instagramConnectUrl() => _api.instagramAuth.connectUrl();

  @override
  Future<void> disconnectInstagram(String igUserId) =>
      _api.instagramAuth.disconnect(igUserId);
}
