/// SCREENS.md §4.3 seed data for the two agent screens, plus the §4.1 ads
/// that belong to each of them, plus a small seed set of reviews backing
/// the `ratingAverage`/`ratingCount` this run adds.
///
/// **Agents only — the two coworkers in §4.3's table are absent on
/// purpose.** `apps/api/src/repositories/agentRepository.js#findAgents`
/// (behind `GET /agents`) filters strictly to `role: "AGENT"`, so Sardor
/// Abdullayev and Kamola Rashidova would never come back from the endpoint
/// this fixture stands in for, despite appearing in the mockup's static
/// markup. Same call `home_feed_fixtures.dart` already made for the Top
/// Agents rail; the two files agree, which is the point.
///
/// **Ads are re-used, not re-typed.** The per-agent grids slice
/// `homeFeedFixtureAds` by `agentId` rather than declaring a second copy of
/// the §4.1 listings — one seed set, so a fixture agent's grid and the
/// Home feed can never drift into showing different versions of the same
/// listing.
///
/// **Reviews are seeded deliberately unevenly**, so fixture mode exercises
/// all three states a real deployment can be in without any network:
/// `agent-javlon` has two reviews (one from `fixture-user-buyer` — the
/// same account `features/auth/data/fixture_auth_repository.dart`'s seed
/// login signs in as — so signing in as the buyer and opening his profile
/// shows a real pre-filled "edit your review" flow, not just a "leave a
/// review" one), `agent-shahnoza` has one, and `agent-otabek` has none —
/// the "No reviews yet" case §3.9 asks for. [FixtureAgentsRepository]
/// recomputes `ratingAverage`/`ratingCount` from this seed (and from
/// whatever a test/demo session posts on top of it) rather than this file
/// hardcoding a number that could drift from the reviews backing it.
library;

import '../../../api/api.dart';
import '../../home/data/home_feed_fixtures.dart';

/// `dealsClosedCount` per SCREENS.md §4.3's "Deals closed" column;
/// `adsCount` per its "Listings count" column. Both are carried here
/// rather than derived from [fixtureAgentAds] because the live API does
/// not derive them from the visible ad set either — `adsCount` is an
/// all-time event tally and `dealsClosedCount` counts SOLD ads, neither of
/// which is what `GET /ads?agentId=` returns.
///
/// `ratingAverage`/`ratingCount` are deliberately left off this builder —
/// [FixtureAgentsRepository] derives them from [fixtureAgentReviewSeed] at
/// construction time and on every review mutation, the same way the live
/// server derives them from the `agent_reviews` table rather than storing
/// them on the user row.
Map<String, dynamic> _detail({
  required String id,
  required String fullName,
  required String phoneNumber,
  required int adsCount,
  required int dealsClosedCount,
  String? address,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': '${id.replaceFirst('agent-', '')}@lacasa.uz',
    'phoneNumber': phoneNumber,
    'avatar': null,
    'adsCount': adsCount,
    'dealsClosedCount': dealsClosedCount,
    'address': address,
  };
}

/// [FixtureAgentsRepository]'s starting point for each agent's mutable
/// detail row — no rating fields (see [_detail]'s doc comment). Public so
/// the repository can seed its own per-instance copy; nothing else should
/// read agent identity from here directly.
final List<AgentDetail> fixtureAgentDetails =
    [
      _detail(
        id: 'agent-javlon',
        fullName: 'Javlon Rustamov',
        phoneNumber: '+998901234567',
        adsCount: 24,
        dealsClosedCount: 9,
        address: '12 Amir Temur Street, Tashkent',
      ),
      _detail(
        id: 'agent-shahnoza',
        fullName: 'Shahnoza Yoldosheva',
        phoneNumber: '+998907654321',
        adsCount: 18,
        dealsClosedCount: 6,
        // No address on file — the honest-absence case §3.9's directory
        // card and §3.10's profile must both be able to render.
      ),
      _detail(
        id: 'agent-otabek',
        fullName: 'Otabek Yusupov',
        phoneNumber: '+998935558899',
        adsCount: 31,
        dealsClosedCount: 14,
        address: '45 Mustaqillik Avenue, Tashkent',
      ),
    ].map(AgentDetail.fromJson).toList(growable: false);

/// The §4.1 listings belonging to one agent, in the same order the feed
/// shows them. Returns empty for an agent with none — which is a real
/// state the profile renders ("No listings found."), not an error.
List<Ad> fixtureAgentAds(String agentId) {
  return homeFeedFixtureAds.where((ad) => ad.agentId == agentId).toList();
}

Map<String, dynamic> _review({
  required String id,
  required int rating,
  String? comment,
  required int createdAtSeconds,
  required String authorId,
  required String authorFullName,
}) {
  return {
    'id': id,
    'rating': rating,
    'comment': comment,
    'createdAt': {'seconds': createdAtSeconds},
    'author': {'id': authorId, 'fullName': authorFullName, 'avatar': null},
  };
}

/// [FixtureAgentsRepository]'s starting reviews, keyed by agent id,
/// newest-first (matching `GET /agents/:id/reviews`'s own ordering) — see
/// this file's doc comment for why the three agents are seeded unevenly.
/// `agent-otabek` has no entry at all, which is exactly what "zero
/// reviews" looks like: an absent map key, not an empty-but-present list
/// pretending to be more deliberate than it is.
final Map<String, List<AgentReview>> fixtureAgentReviewSeed = {
  'agent-javlon': [
    _review(
      id: 'review-seed-javlon-2',
      rating: 4,
      comment: 'Very responsive, minor scheduling hiccups.',
      createdAtSeconds: 1706000000,
      authorId: 'buyer-amir',
      authorFullName: 'Amir Q.',
    ),
    _review(
      id: 'review-seed-javlon-1',
      rating: 5,
      comment: 'Sold our flat in two weeks flat. Highly recommend.',
      createdAtSeconds: 1704000000,
      // The fixture auth seed's buyer login (`fixture_auth_repository.dart`)
      // — see this file's doc comment for why that's deliberate.
      authorId: 'fixture-user-buyer',
      authorFullName: 'Dilnoza Yusupova',
    ),
  ],
  'agent-shahnoza': [
    _review(
      id: 'review-seed-shahnoza-1',
      rating: 5,
      comment: null,
      createdAtSeconds: 1705000000,
      authorId: 'buyer-lola',
      authorFullName: 'Lola N.',
    ),
  ],
}.map(
  (agentId, reviews) => MapEntry(
    agentId,
    reviews.map(AgentReview.fromJson).toList(growable: false),
  ),
);
