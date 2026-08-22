/// `/api/auth/instagram/*` — the connect/disconnect half of
/// `connected-accounts` (§21); [PublishResource.instagramAccounts]
/// (`publish_resource.dart`) is the read half. Both AGENT-only —
/// `apps/api/src/routes/instagramAuth.js` 403s a COWORKER caller on every
/// route here.
library;

import '../api_client.dart';

class InstagramAuthResource {
  final ApiClient _client;

  const InstagramAuthResource(this._client);

  /// `POST /auth/instagram/connect-url`. Returns the Meta OAuth authorize
  /// URL — open it in the **system browser** (Custom Tabs / SFSafariViewController),
  /// never an in-app `WebView`; Meta's OAuth terms forbid embedded webviews
  /// for this flow (SCREENS.md §21). The callback itself
  /// (`GET /auth/instagram/callback`) is a browser redirect target only —
  /// nothing in this client calls it directly.
  Future<String> connectUrl() async {
    final json = await _client.request(
      method: 'POST',
      path: '/auth/instagram/connect-url',
    );
    return (json as Map<String, dynamic>)['url'] as String? ?? '';
  }

  /// `DELETE /auth/instagram/:igUserId`. Idempotent — a `deleteMany`
  /// server-side, so this never 404s even if [igUserId] was already
  /// disconnected or never existed.
  Future<void> disconnect(String igUserId) async {
    await _client.request(
      method: 'DELETE',
      path: '/auth/instagram/$igUserId',
    );
  }
}
