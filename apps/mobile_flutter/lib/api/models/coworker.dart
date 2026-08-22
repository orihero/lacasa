/// The `Coworker` wire shape (`apps/api/src/routes/coworkers.js`) — the
/// truth for `GET /coworkers`, `GET /coworkers/:id`, `POST /coworkers` and
/// `PATCH /coworkers/:id`'s responses. Genuinely only these five fields —
/// no `listingsCount`/`closed`/`lastActive`; a screen that wants those
/// derives them client-side from `Ad.coworkerId`/`GET /statistics/coworkers`
/// the same way `apps/console/src/screens/coworkers/*` does (see the web/
/// console survey).
library;

class Coworker {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;

  /// Field name is `avatar`, not `avatarUrl`, on this wire shape — mapped
  /// from the `avatarUrl` DB column server-side, but that renaming does not
  /// carry through to JSON.
  final String? avatar;
  final String agentId;

  const Coworker({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.agentId,
  });

  factory Coworker.fromJson(Map<String, dynamic> json) {
    return Coworker(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      agentId: json['agentId'] as String? ?? '',
    );
  }
}
