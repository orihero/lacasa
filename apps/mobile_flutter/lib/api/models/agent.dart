/// `GET /api/agents` (list) and `GET /api/agents/:id` (detail) shapes.
/// Both are public, unauthenticated endpoints. `adsCount` on both is an
/// all-time `AD_CREATED` event tally, NOT a live count of the agent's
/// current listings — it never decreases, even for a deleted or now-sold ad.
///
/// [AgentSummary.ratingAverage]/[ratingCount] and [AgentSummary.address]
/// (mirrored on [AgentDetail]) are this run's additions
/// (`docs/04-api-spec.md`'s Users/agents section) — see
/// [AgentSummary.ratingAverage]'s own doc comment for the null-vs-zero
/// rule, which is load-bearing.
library;

class AgentSummary {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatar;
  final int adsCount;

  /// Free-text office/contact address — `null` when the agent never set
  /// one. Optional in the constructor (default `null`), not `required`, so
  /// call sites built before this field existed (fixture builders that
  /// still only pass id/fullName/email/phoneNumber/avatar/adsCount) keep
  /// compiling unchanged.
  final String? address;

  /// The `agent_reviews` aggregate average, rounded to one decimal
  /// server-side. **`null` means "no reviews yet," and must never be
  /// coerced to `0`/`0.0`** — a SQL `groupBy` aggregate produces no row at
  /// all for an agent nobody has rated, so there is no average to compute;
  /// treating that absence as a zero would render a one-star card for
  /// someone with zero actual reviews. Render [ratingAverage] `== null` as
  /// "No reviews yet" (SCREENS.md §3.9), never as a zero-star rating.
  /// Optional in the constructor, defaulting to `null`, for the same
  /// backward-compatibility reason as [address].
  final double? ratingAverage;

  /// `0` when [ratingAverage] is `null` — unlike [ratingAverage] itself,
  /// zero *is* the honest value here: zero reviews is exactly what a zero
  /// count means. Optional in the constructor, defaulting to `0`.
  final int ratingCount;

  const AgentSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.adsCount,
    this.address,
    this.ratingAverage,
    this.ratingCount = 0,
  });

  factory AgentSummary.fromJson(Map<String, dynamic> json) {
    return AgentSummary(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      adsCount: (json['adsCount'] as num?)?.toInt() ?? 0,
      address: json['address'] as String?,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
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

  /// See [AgentSummary.address]'s doc comment.
  final String? address;

  /// See [AgentSummary.ratingAverage]'s doc comment — the same
  /// null-means-no-reviews rule applies here.
  final double? ratingAverage;

  /// See [AgentSummary.ratingCount]'s doc comment.
  final int ratingCount;

  const AgentDetail({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatar,
    required this.adsCount,
    required this.dealsClosedCount,
    this.address,
    this.ratingAverage,
    this.ratingCount = 0,
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
      address: json['address'] as String?,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble(),
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
