/// `GET /api/publish/instagram/accounts`'s `accounts[]` — distinct from
/// `AuthUser.igAccounts` (`models/auth_user.dart`'s `IgAccount`): that one
/// is the bare `{igUserId, username, expiresAt}` embedded in every login/me
/// response, this one is the richer shape `connected-accounts` (SCREENS.md
/// §21) actually needs, straight from the Instagram Graph API
/// (`media_count`/`followers_count`/`follows_count`/`profile_picture_url`)
/// — all optional on the wire (the Graph API call that fills them in can
/// itself fail independent of the token being valid), so §21's "Posts {…}
/// / Followers {…} / Following {…}" rows should render only when present,
/// never fabricate a placeholder count for an absent field (see the
/// web/console survey's discrepancy #7 — console has this data and simply
/// never renders it; the fields are real).
library;

class ConnectedInstagramAccount {
  final String igUserId;
  final String? username;
  final DateTime? expiresAt;
  final String? profilePictureUrl;
  final int? mediaCount;
  final int? followersCount;
  final int? followsCount;

  const ConnectedInstagramAccount({
    required this.igUserId,
    required this.username,
    required this.expiresAt,
    required this.profilePictureUrl,
    required this.mediaCount,
    required this.followersCount,
    required this.followsCount,
  });

  factory ConnectedInstagramAccount.fromJson(Map<String, dynamic> json) {
    return ConnectedInstagramAccount(
      igUserId: json['igUserId'] as String? ?? '',
      username: json['username'] as String?,
      expiresAt: _parseIso(json['expiresAt']),
      profilePictureUrl: json['profile_picture_url'] as String?,
      mediaCount: (json['media_count'] as num?)?.toInt(),
      followersCount: (json['followers_count'] as num?)?.toInt(),
      followsCount: (json['follows_count'] as num?)?.toInt(),
    );
  }
}

DateTime? _parseIso(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
