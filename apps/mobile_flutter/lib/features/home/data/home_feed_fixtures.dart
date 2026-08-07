/// Bundled seed data for [FixtureHomeFeedRepository], transcribed from
/// SCREENS.md §4.1 (property listings) and §4.3 (agents/coworkers) — the
/// same seed rows the mockup's own demo state uses. Only the six listings
/// whose §4.1 `Status` column is Active (`1`) are included: `ad-1005`
/// (Sold) and `ad-1007` (Draft) are omitted, mirroring `GET /ads`'s own
/// server-side `stage: "ACTIVE"` scoping (see `ads_resource.dart`) so the
/// fixture and the live API agree on what "the feed" contains.
///
/// `photos`/`media` are deliberately left empty on every fixture ad —
/// there is no bundled image asset to point at, and inventing a remote URL
/// would just turn into a failed network fetch, which is exactly what this
/// fixture exists to avoid. `ListingPhoto` (`widgets/listing_photo.dart`)
/// renders its themed placeholder box whenever a photo list is empty, so
/// this degrades to the same visual on every listing card.
library;

import '../../../api/api.dart';

Map<String, dynamic> _ad({
  required String id,
  required String title,
  required String district,
  required String category, // 'sale' | 'rent'
  required String type, // 'residential' | 'nonresidential'
  required num price,
  required int rooms,
  required num area,
  required int storey,
  required int floors,
  required String agentId,
  required int createdAtSeconds,
}) {
  return {
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': district,
    'address': null,
    'reference': null,
    'type': type,
    'category': category,
    'rooms': rooms,
    'area': area,
    'storey': storey,
    'floors': floors,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': '1', // active
    'description': null,
    'nearPlacesList': const <String>[],
    'optionList': null,
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': agentId,
    'coworkerId': '',
    'photos': const <String>[],
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
  };
}

/// Ordered so `.take(3)` (Featured Listings) and `.skip(3)` (Explore
/// Nearby) land on a mix that reads sensibly, rather than in `ad-1001..8`
/// id order — see the build spec's "On the source data for rails 5 and 8"
/// (the exact rail boundary is explicitly unspecified there).
final List<Ad> homeFeedFixtureAds = [
  _ad(
    id: 'ad-1001',
    title: 'Bright 3-room apartment in Chilonzor',
    district: 'Chilonzor',
    category: 'sale',
    type: 'residential',
    price: 78000,
    rooms: 3,
    area: 65,
    storey: 4,
    floors: 9,
    agentId: 'agent-javlon',
    createdAtSeconds: 1700000600,
  ),
  _ad(
    id: 'ad-1003',
    title: 'Family house with garden in Sergeli',
    district: 'Sergeli',
    category: 'sale',
    type: 'residential',
    price: 120000,
    rooms: 5,
    area: 140,
    storey: 1,
    floors: 2,
    agentId: 'agent-javlon',
    createdAtSeconds: 1700000500,
  ),
  _ad(
    id: 'ad-1004',
    title: 'Office space on Amir Temur avenue',
    district: 'Mirzo Ulugbek',
    category: 'rent',
    type: 'nonresidential',
    price: 900,
    rooms: 4,
    area: 110,
    storey: 6,
    floors: 12,
    agentId: 'agent-otabek',
    createdAtSeconds: 1700000400,
  ),
  _ad(
    id: 'ad-1002',
    title: 'Renovated studio near Yunusobod metro',
    district: 'Yunusobod',
    category: 'rent',
    type: 'residential',
    price: 350,
    rooms: 1,
    area: 32,
    storey: 2,
    floors: 5,
    agentId: 'agent-shahnoza',
    createdAtSeconds: 1700000300,
  ),
  _ad(
    id: 'ad-1006',
    title: 'Retail space near Chorsu bazaar',
    district: 'Shayxontohur',
    category: 'rent',
    type: 'nonresidential',
    price: 1200,
    rooms: 2,
    area: 48,
    storey: 1,
    floors: 1,
    agentId: 'agent-sardor',
    createdAtSeconds: 1700000200,
  ),
  _ad(
    id: 'ad-1008',
    title: 'Renovated 1-room near Yakkasaroy park',
    district: 'Yakkasaroy',
    category: 'rent',
    type: 'residential',
    price: 400,
    rooms: 1,
    area: 38,
    storey: 3,
    floors: 5,
    agentId: 'agent-kamola',
    createdAtSeconds: 1700000100,
  ),
].map(Ad.fromJson).toList(growable: false);

Map<String, dynamic> _agent({
  required String id,
  required String fullName,
  required int adsCount,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': '${id.replaceFirst('agent-', '')}@lacasa.uz',
    'phoneNumber': null,
    'avatar': null,
    'adsCount': adsCount,
  };
}

/// SCREENS.md §4.3, **agent** rows only — `apps/api/src/repositories/
/// agentRepository.js#findAgents` (backing `GET /agents`) filters strictly
/// to `role: "AGENT"`, so Sardor Abdullayev and Kamola Rashidova
/// (coworkers in §4.3's own table) would never actually come back from
/// that endpoint despite appearing in the mockup's static Top Agents rail
/// markup. This fixture mirrors what the live API would really return, not
/// the mockup's demo copy — flagged as a divergence in the build report.
final List<AgentSummary> homeFeedFixtureAgents = [
  _agent(id: 'agent-javlon', fullName: 'Javlon Rustamov', adsCount: 24),
  _agent(id: 'agent-shahnoza', fullName: 'Shahnoza Yoldosheva', adsCount: 18),
  _agent(id: 'agent-otabek', fullName: 'Otabek Yusupov', adsCount: 31),
].map(AgentSummary.fromJson).toList(growable: false);

/// Matches the mockup's own demo state: `ad-1001`'s heart renders filled
/// (`fav g on`) everywhere it appears, every other card starts unfavourited.
final Set<String> homeFeedFixtureSavedAdIds = {'ad-1001'};
