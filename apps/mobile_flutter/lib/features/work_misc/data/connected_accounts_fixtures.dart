/// Bundled fixture data for `connected-accounts`' Instagram half —
/// deliberately not part of `lib/shared/fixtures/work_seed_data.dart`
/// (that file's own doc comment scopes it to §4.1–§4.6's ad/lead/agent/
/// notification/dashboard seed rows; Instagram accounts have no §4 entry
/// of their own). One connected account, seeded with every optional field
/// present, so [FixtureConnectedAccountsRepository]'s default state
/// demonstrates ruling 7.9's "these fields are real, render them" case
/// rather than only ever showing the empty/absent-field path.
library;

import '../../../api/api.dart';

ConnectedInstagramAccount fixtureInstagramAccount() {
  return ConnectedInstagramAccount.fromJson({
    'igUserId': 'ig-javlon-rustamov',
    'username': 'lacasa.javlon',
    'expiresAt': '2026-11-01T00:00:00.000Z',
    'profile_picture_url': null,
    'media_count': 86,
    'followers_count': 1420,
    'follows_count': 210,
  });
}
