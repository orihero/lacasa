/// A controllable [ConnectedAccountsRepository] fake for widget tests — no
/// network, same shape as
/// `test/features/saved_listings/support/fake_saved_listings_repository.dart`.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_misc/data/connected_accounts_repository.dart';

class FakeConnectedAccountsRepository implements ConnectedAccountsRepository {
  FakeConnectedAccountsRepository({
    List<ConnectedInstagramAccount>? accounts,
    this.fetchError,
    this.connectUrlError,
    this.disconnectError,
    this.hold,
    String? connectUrl,
  }) : accounts = List.of(accounts ?? const []),
       connectUrl = connectUrl ?? 'https://instagram.example/oauth';

  final List<ConnectedInstagramAccount> accounts;
  final String connectUrl;
  final Object? fetchError;
  final Object? connectUrlError;
  final Object? disconnectError;

  /// When set, [instagramAccounts] awaits this before returning — the only
  /// way to observe a loading state in a widget test.
  final Completer<void>? hold;

  int fetchCallCount = 0;
  int connectUrlCallCount = 0;
  final List<String> disconnectedIds = [];

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async {
    fetchCallCount++;
    if (hold != null) await hold!.future;
    if (fetchError != null) throw fetchError!;
    return List.unmodifiable(accounts);
  }

  @override
  Future<String> instagramConnectUrl() async {
    connectUrlCallCount++;
    if (connectUrlError != null) throw connectUrlError!;
    return connectUrl;
  }

  @override
  Future<void> disconnectInstagram(String igUserId) async {
    if (disconnectError != null) throw disconnectError!;
    disconnectedIds.add(igUserId);
    accounts.removeWhere((a) => a.igUserId == igUserId);
  }
}
