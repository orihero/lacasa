/// `PATCH /api/users/me` — the authenticated self-update endpoint behind
/// `edit-profile` (SCREENS.md §3.18). Every field is optional on the wire
/// (`apps/api/src/routes/users.js`'s `updateSchema`): a key that is omitted
/// from the request body leaves that column untouched, rather than the
/// caller having to round-trip the current value back. This mirrors
/// `contact_resource.dart`'s "the request type IS the wire shape" rule, just
/// with every field optional instead of required.
library;

import '../api_client.dart';
import '../models/auth_user.dart';

class UsersResource {
  final ApiClient _client;

  const UsersResource(this._client);

  /// `PATCH /api/users/me`. Requires auth — `Authorization: Bearer <token>`
  /// is attached by [ApiClient] whenever its [TokenStorage] holds one, same
  /// as every other authenticated resource; with no/an invalid token the
  /// server never reaches this handler at all (`requireAuth` middleware
  /// answers first, see below).
  ///
  /// [password], when provided, is hashed server-side and replaces the
  /// stored credential — there is no "current password" confirmation step
  /// on this endpoint, matching `apps/api/src/routes/users.js` exactly.
  ///
  /// Throws [ApiErrorException] with:
  /// - `code: validation` (400) — a field failed `updateSchema` (e.g. an
  ///   `email` that isn't a valid address, a `password` under 6 characters).
  /// - `code: emailTaken` (409) — [email] collides with another account's
  ///   unique index (`P2002` on `User.email`; SCREENS.md §3.18's "Error
  ///   updating profile: {message}" toast is how the screen should surface
  ///   this).
  /// - `code: unauthorized` (401) — no token, or an expired/invalid one.
  Future<MeResponse> updateMe({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) async {
    final json = await _client.request(
      method: 'PATCH',
      path: '/users/me',
      body: {
        'fullName': ?fullName,
        'phoneNumber': ?phoneNumber,
        'email': ?email,
        'avatar': ?avatar,
        'password': ?password,
      },
    );
    return MeResponse.fromJson(json as Map<String, dynamic>);
  }
}
