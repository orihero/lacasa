/// Riverpod state for `connected-accounts` (SCREENS.md §21) — the
/// Instagram account list plus its one real mutation, disconnect. Telegram/
/// YouTube need no provider of their own: Telegram's count reads straight
/// off `authSessionProvider` (`AuthUser.tgChatIds.length`) at the widget
/// level, and YouTube has no data to hold at all — see
/// `connected_accounts_repository.dart`'s doc comment.
///
/// Not `.autoDispose`: this is a *pushed* screen (SCREENS.md §1), same
/// bucket as `saved-listings`, and `saved_listings_providers.dart`'s own
/// provider isn't autoDispose either — a user bouncing back into this
/// screen mid-session should see the account list it already has, not
/// re-fetch every time.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'connected_accounts_repository_provider.dart';

class InstagramAccountsNotifier
    extends AsyncNotifier<List<ConnectedInstagramAccount>> {
  @override
  Future<List<ConnectedInstagramAccount>> build() =>
      ref.read(connectedAccountsRepositoryProvider).instagramAccounts();

  /// Disconnects [igUserId] then refetches — rather than optimistically
  /// removing it locally — so a server-side failure never leaves the UI
  /// showing an account as gone that the server still has connected.
  Future<void> disconnect(String igUserId) async {
    await ref
        .read(connectedAccountsRepositoryProvider)
        .disconnectInstagram(igUserId);
    ref.invalidateSelf();
    await future;
  }
}

final instagramAccountsProvider =
    AsyncNotifierProvider<
      InstagramAccountsNotifier,
      List<ConnectedInstagramAccount>
    >(InstagramAccountsNotifier.new);
