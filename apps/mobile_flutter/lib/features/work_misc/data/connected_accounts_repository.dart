/// Data-access seam for `connected-accounts` (SCREENS.md §21) — the
/// Instagram half only. Telegram/YouTube have no fetchable data of their
/// own to abstract behind a repository at all:
///
/// - **Telegram** is a bare count (`AuthUser.tgChatIds.length`) that
///   already lives on the signed-in session (`authSessionProvider`) — see
///   `WORK_TAB_CONTRACT.md` ruling 7.10. Reading it through a second seam
///   here would just be a duplicate, always-in-sync-by-construction copy of
///   state this repository doesn't own and cannot invalidate independently.
/// - **YouTube** has zero backing data or OAuth route anywhere in
///   `apps/api` (same ruling) — there is nothing to fetch.
///
/// So this interface only ever needs to cover Instagram: the one channel
/// with a real, independently-fetchable account list.
library;

import '../../../api/api.dart';

abstract class ConnectedAccountsRepository {
  /// `GET /publish/instagram/accounts` — every Instagram account the
  /// signed-in agent has connected. `media_count`/`followers_count`/
  /// `follows_count`/`profile_picture_url` are each independently optional
  /// (ruling 7.9) — render each only when present, never fabricate a
  /// placeholder count for an absent field.
  Future<List<ConnectedInstagramAccount>> instagramAccounts();

  /// `POST /auth/instagram/connect-url` — the Meta OAuth authorize URL.
  /// There is no `url_launcher` in this build (contract §5.3), so the
  /// caller's job is to copy this to the clipboard and tell the user to
  /// paste it into their browser, never to attempt an in-app `WebView`
  /// (forbidden outright by Meta's OAuth terms, and by SCREENS.md §21).
  Future<String> instagramConnectUrl();

  /// `DELETE /auth/instagram/:igUserId`. Idempotent server-side.
  Future<void> disconnectInstagram(String igUserId);
}
