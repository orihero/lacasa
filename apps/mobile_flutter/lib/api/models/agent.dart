/// `GET /api/agents` (list) and `GET /api/agents/:id` (detail) shapes.
/// Both are public, unauthenticated endpoints. `adsCount` on both is an
/// all-time `AD_CREATED` event tally, NOT a live count of the agent's
/// current listings — it never decreases, even for a deleted or now-sold ad.
library;

class AgentSummary {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final int adsCount;

  const AgentSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.adsCount,
  });

  factory AgentSummary.fromJson(Map<String, dynamic> json) {
    return AgentSummary(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      adsCount: (json['adsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AgentDetail {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatar;

  /// `AD_CREATED` event count — the same measure [AgentSummary.adsCount] uses.
  final int adsCount;

  /// This agent's ads currently at stage SOLD ("2"). Detail only; the
  /// directory (`AgentSummary`) omits it.
  final int dealsClosedCount;

  const AgentDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.adsCount,
    required this.dealsClosedCount,
  });

  factory AgentDetail.fromJson(Map<String, dynamic> json) {
    return AgentDetail(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      adsCount: (json['adsCount'] as num?)?.toInt() ?? 0,
      dealsClosedCount: (json['dealsClosedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
