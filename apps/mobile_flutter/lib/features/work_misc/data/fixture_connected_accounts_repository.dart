/// Offline stand-in for [ConnectedAccountsRepository], backed by
/// `connected_accounts_fixtures.dart`. No network, no [LaCasaApi]
/// dependency — what this screen renders from by default (see
/// `connected_accounts_mode.dart`).
///
/// **Mutable, unlike most fixture repositories in this app.** Disconnect
/// is a real, observable action on this screen (§21's per-card
/// "Disconnect" button) — a fixture that always reported the same
/// connected account regardless of what the user just tapped would make
/// the button a lie. This instance keeps its seeded list in memory and
/// actually removes an id on [disconnectInstagram], the same "fixture
/// still behaves like the real thing" bar `auth`'s `FixtureAuthRepository`
/// sets for its own mutations.
library;

import '../../../api/api.dart';
import 'connected_accounts_fixtures.dart';
import 'connected_accounts_repository.dart';

class FixtureConnectedAccountsRepository
    implements ConnectedAccountsRepository {
  FixtureConnectedAccountsRepository()
    : _accounts = [fixtureInstagramAccount()];

  final List<ConnectedInstagramAccount> _accounts;

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async =>
      List.unmodifiable(_accounts);

  @override
  Future<String> instagramConnectUrl() async =>
      'https://www.instagram.com/oauth/authorize?client_id=fixture&redirect_uri=https://lacasa.uz/auth/instagram/callback';

  @override
  Future<void> disconnectInstagram(String igUserId) async {
    _accounts.removeWhere((a) => a.igUserId == igUserId);
  }
}
