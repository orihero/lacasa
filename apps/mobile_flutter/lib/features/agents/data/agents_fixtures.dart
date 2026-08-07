/// SCREENS.md §4.3 seed data for the two agent screens, plus the §4.1 ads
/// that belong to each of them.
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
library;

import '../../../api/api.dart';
import '../../home/data/home_feed_fixtures.dart';

/// `dealsClosedCount` per SCREENS.md §4.3's "Deals closed" column;
/// `adsCount` per its "Listings count" column. Both are carried here
/// rather than derived from [fixtureAgentAds] because the live API does
/// not derive them from the visible ad set either — `adsCount` is an
/// all-time event tally and `dealsClosedCount` counts SOLD ads, neither of
/// which is what `GET /ads?agentId=` returns.
Map<String, dynamic> _detail({
  required String id,
  required String fullName,
  required String phoneNumber,
  required int adsCount,
  required int dealsClosedCount,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': '${id.replaceFirst('agent-', '')}@lacasa.uz',
    'phoneNumber': phoneNumber,
    'avatar': null,
    'adsCount': adsCount,
    'dealsClosedCount': dealsClosedCount,
  };
}

final List<AgentDetail> _fixtureAgentDetails = [
  _detail(
    id: 'agent-javlon',
    fullName: 'Javlon Rustamov',
    phoneNumber: '+998901234567',
    adsCount: 24,
    dealsClosedCount: 9,
  ),
  _detail(
    id: 'agent-shahnoza',
    fullName: 'Shahnoza Yoldosheva',
    phoneNumber: '+998907654321',
    adsCount: 18,
    dealsClosedCount: 6,
  ),
  _detail(
    id: 'agent-otabek',
    fullName: 'Otabek Yusupov',
    phoneNumber: '+998935558899',
    adsCount: 31,
    dealsClosedCount: 14,
  ),
].map(AgentDetail.fromJson).toList(growable: false);

/// The directory list. Derived from [_fixtureAgentDetails] rather than
/// declared separately, so the name/phone/email a user reads on a card is
/// by construction the same one they read on the profile it opens.
final List<AgentSummary> fixtureAgents = _fixtureAgentDetails
    .map(
      (a) => AgentSummary(
        id: a.id,
        fullName: a.fullName,
        email: a.email,
        phoneNumber: a.phoneNumber,
        avatar: a.avatar,
        adsCount: a.adsCount,
      ),
    )
    .toList(growable: false);

/// Profile lookup by id. `null` for an unknown id — including a coworker
/// id, which the live endpoint 404s for the same reason (see this file's
/// doc comment). [FixtureAgentsRepository] turns that null into the same
/// `notFound` [ApiErrorException] the live one would throw.
AgentDetail? fixtureAgentById(String id) {
  for (final agent in _fixtureAgentDetails) {
    if (agent.id == id) return agent;
  }
  return null;
}

/// The §4.1 listings belonging to one agent, in the same order the feed
/// shows them. Returns empty for an agent with none — which is a real
/// state the profile renders ("No listings found."), not an error.
List<Ad> fixtureAgentAds(String agentId) {
  return homeFeedFixtureAds.where((ad) => ad.agentId == agentId).toList();
}
