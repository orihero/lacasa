/// `/api/agents/:id/reviews` shapes (SCREENS.md §3.9) — `GET` (paged
/// listing), `POST` (upsert), `DELETE .../me`. See
/// `resources/agents_resource.dart` for the three methods that produce/
/// consume these.
library;

import 'wire_timestamp.dart';

/// Public identity only — `id`/`fullName`/`avatar`. A review's author can
/// be a buyer or another agent; neither their email nor phone number leaves
/// this endpoint (same restriction `AgentSummary`/`AgentDetail` already
/// apply to the *subject* of a card).
class ReviewAuthor {
  final String id;
  final String fullName;
  final String? avatar;

  const ReviewAuthor({
    required this.id,
    required this.fullName,
    required this.avatar,
  });

  factory ReviewAuthor.fromJson(Map<String, dynamic> json) {
    return ReviewAuthor(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatar: json['avatar'] as String?,
    );
  }
}

class AgentReview {
  final String id;

  /// Always an integer 1..5 — enforced both by a Zod schema server-side and
  /// a DB `CHECK` constraint underneath that.
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final ReviewAuthor author;

  const AgentReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.author,
  });

  factory AgentReview.fromJson(Map<String, dynamic> json) {
    return AgentReview(
      id: json['id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['createdAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      author: ReviewAuthor.fromJson(
        json['author'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// `GET /agents/:id/reviews`'s whole response — newest-first.
/// [nextCursor] is the previous page's last [AgentReview.id]; `null` means
/// there is no further page.
class AgentReviewPage {
  final List<AgentReview> reviews;
  final String? nextCursor;

  const AgentReviewPage({required this.reviews, required this.nextCursor});

  factory AgentReviewPage.fromJson(Map<String, dynamic> json) {
    return AgentReviewPage(
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((e) => AgentReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
