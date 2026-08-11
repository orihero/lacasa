/// JSON builders for the agents tests. Kept as wire-shaped maps run through
/// the real `fromJson` factories rather than hand-constructed model
/// instances, so a change to a factory's null-handling shows up here instead
/// of being bypassed.
library;

import 'package:lacasa_mobile/api/api.dart';

AgentSummary agentSummary({
  required String id,
  required String fullName,
  String? phoneNumber,
  String? email,
  int adsCount = 0,
}) {
  return AgentSummary.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email ?? '$id@lacasa.uz',
    'phoneNumber': phoneNumber,
    'avatar': null,
    'adsCount': adsCount,
  });
}

AgentDetail agentDetail({
  required String id,
  required String fullName,
  String? phoneNumber,
  String? email,
  int adsCount = 0,
  int dealsClosedCount = 0,
  // Optional, defaulting to the same "no reviews yet" shape
  // `AgentDetail.ratingAverage`'s doc comment requires of a real
  // zero-review agent — `null` average, `0` count — so every existing
  // call site built before `agent_reviews_section_test.dart` needed a
  // rated agent keeps compiling and keeps rendering "No reviews yet"
  // unchanged.
  double? ratingAverage,
  int ratingCount = 0,
}) {
  return AgentDetail.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email ?? '$id@lacasa.uz',
    'phoneNumber': phoneNumber,
    'avatar': null,
    'adsCount': adsCount,
    'dealsClosedCount': dealsClosedCount,
    'ratingAverage': ratingAverage,
    'ratingCount': ratingCount,
  });
}

/// One `GET /agents/:id/reviews` row — for `agent_reviews_section_test.dart`
/// and `FakeAgentsRepository`'s `reviews:` seed list. [authorId]/
/// [authorFullName] are required rather than defaulted: every test that
/// reaches for this helper is asserting something author-identity-shaped
/// (upsert-by-author, "is this mine", the reviewer's name on the tile), so a
/// silently-shared default author would make it too easy to write a test
/// that passes for the wrong reason.
AgentReview agentReview({
  required String id,
  required int rating,
  String? comment,
  required String authorId,
  required String authorFullName,
  String? authorAvatar,
  int createdAtSeconds = 1700000000,
}) {
  return AgentReview.fromJson({
    'id': id,
    'rating': rating,
    'comment': comment,
    'createdAt': {'seconds': createdAtSeconds},
    'author': {
      'id': authorId,
      'fullName': authorFullName,
      'avatar': authorAvatar,
    },
  });
}

Ad agentAd({
  required String id,
  required String title,
  String agentId = 'agent-a',
  String district = 'Yunusabad',
  num price = 90000,
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': district,
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'rooms': 3,
    'area': 72,
    'storey': 4,
    'floors': 9,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': '1',
    'description': null,
    'nearPlacesList': <String>[],
    'optionList': null,
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': agentId,
    'coworkerId': '',
    'photos': <String>[],
    'media': <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}
