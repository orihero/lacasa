/// Bundled seed data for [FixtureListingDetailRepository], transcribed from
/// SCREENS.md §4.1 (all 8 property listings — unlike
/// `features/home/data/home_feed_fixtures.dart`, which only needs the 6
/// `Active` ones for the public feed, `listing-detail` must be able to
/// resolve *any* id a listing card could have linked to, including the Sold
/// (`ad-1005`) and Draft (`ad-1007`) rows, since `GET /ads/:id` itself is
/// not stage-scoped the way `GET /ads` is — only the list endpoint filters
/// to `stage: "ACTIVE"` server-side) and §4.3 (agents/coworkers, as
/// [AgentDetail] — the shape `GET /agents/:id` returns, richer than the
/// [AgentSummary] `home_feed_fixtures.dart` uses for the directory list).
///
/// Fields SCREENS.md's table doesn't specify (address, reference,
/// repairment, furniture, hashtags, description, nearPlacesList,
/// optionList, lat/lng, tour3dLink) are filled in here with plausible
/// values so every section `listing-detail` renders has something real to
/// show — but deliberately varied per ad (some `repairment`/`furniture`
/// left `null`, one `optionList` deliberately malformed, one `nearPlacesList`
/// deliberately empty, one pin deliberately absent) so the fixture also
/// exercises every "honest gap" this screen has to render, not just the
/// happy path. Coordinates are approximate Tashkent-district points, not
/// surveyed addresses — good enough for a placeholder pin, not to be read
/// as authoritative.
///
/// `photos`/`media` are left empty on every fixture ad, matching
/// `home_feed_fixtures.dart`'s own documented reason (no bundled image
/// asset to point at; [ListingPhoto]-style widgets degrade to their themed
/// placeholder either way) — except `ad-1001`, which is given one
/// `https://` photo URL specifically so `ListingPhoto`'s network-image path
/// (not just its no-url placeholder path) has a fixture-driven exerciser.
///
/// **Divergence flagged, mirroring `home_feed_fixtures.dart`'s own note**:
/// `ad-1006`/`ad-1008`'s §4.1 "Author" is a coworker (Sardor Abdullayev /
/// Kamola Rashidova), but `Ad.agentId` here still points at an
/// `agent-sardor`/`agent-kamola` fixture row so the agent block has
/// something to resolve — a real `GET /agents/:id` call would 404 for a
/// coworker id (`agents_resource.dart`'s own doc comment). This fixture
/// mirrors the mockup's demo shape, not what the live API would actually
/// return for these two ads; flagged in the build report, not fixed here.
library;

import '../../../api/api.dart';

Map<String, dynamic> _ad({
  required String id,
  required String title,
  required String district,
  required String category, // 'sale' | 'rent'
  required String type, // 'residential' | 'nonresidential'
  required String stage, // '1' active, '2' sold, '3' draft
  required num price,
  required int rooms,
  required num area,
  required int storey,
  required int floors,
  required String? repairment,
  required String? furniture,
  required String description,
  required List<String> nearPlacesList,
  required Object? optionList,
  required double? lat,
  required double? lng,
  required String? tour3dLink,
  required String agentId,
  required int createdAtSeconds,
  List<String> photos = const [],
}) {
  return {
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': district,
    'address': '$district district, Tashkent',
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
    'stage': stage,
    'description': description,
    'nearPlacesList': nearPlacesList,
    'optionList': optionList,
    'active': stage == '1',
    'lat': lat,
    'lng': lng,
    'tour3dLink': tour3dLink,
    'agentId': agentId,
    'coworkerId': '',
    'photos': photos,
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
    'repairment': ?repairment,
    'furniture': ?furniture,
  };
}

final List<Ad> listingDetailFixtureAds =
    [
      _ad(
        id: 'ad-1001',
        title: 'Bright 3-room apartment in Chilonzor',
        district: 'Chilonzor',
        category: 'sale',
        type: 'residential',
        stage: '1',
        price: 78000,
        rooms: 3,
        area: 65,
        storey: 4,
        floors: 9,
        repairment: 'normal',
        furniture: 'withFurniture',
        description:
            'A bright, well-kept 3-room apartment on the 4th floor of a '
            'quiet 9-storey block in Chilonzor. Recently repainted, south-'
            'facing living room, and a balcony overlooking a courtyard '
            'garden.',
        nearPlacesList: const [
          'Chilonzor metro station (7 min walk)',
          'School #12',
          'Chorsu Bazaar (12 min drive)',
        ],
        optionList: const [
          {'key': 'Parking', 'value': 'Yes'},
          {'key': 'Balcony', 'value': '2'},
          {'key': 'Heating', 'value': 'Central'},
        ],
        lat: 41.2810,
        lng: 69.2050,
        tour3dLink: 'https://tours.lacasa.uz/ad-1001',
        agentId: 'agent-javlon',
        createdAtSeconds: 1700000600,
        photos: const ['https://images.lacasa.uz/fixtures/ad-1001-1.jpg'],
      ),
      _ad(
        id: 'ad-1002',
        title: 'Renovated studio near Yunusobod metro',
        district: 'Yunusobod',
        category: 'rent',
        type: 'residential',
        stage: '1',
        price: 350,
        rooms: 1,
        area: 32,
        storey: 2,
        floors: 5,
        repairment: 'good',
        furniture: 'withFurniture',
        description:
            'Fully renovated studio, two minutes from Yunusobod metro '
            'station. New kitchen, fast internet already installed, ready '
            'to move in.',
        nearPlacesList: const ['Yunusobod metro station (2 min walk)'],
        // Deliberately null — exercises the "no additional information"
        // honest-empty state alongside `ad-1003`'s malformed case below.
        optionList: null,
        lat: 41.3540,
        lng: 69.2870,
        tour3dLink: null,
        agentId: 'agent-shahnoza',
        createdAtSeconds: 1700000300,
      ),
      _ad(
        id: 'ad-1003',
        title: 'Family house with garden in Sergeli',
        district: 'Sergeli',
        category: 'sale',
        type: 'residential',
        stage: '1',
        price: 120000,
        rooms: 5,
        area: 140,
        storey: 1,
        floors: 2,
        // Both left unset — SCREENS.md fixes call these absent-from-wire,
        // not defaulted; this ad exercises that honest-gap rendering.
        repairment: null,
        furniture: null,
        description:
            'Spacious 5-room family house with a private garden and '
            'off-street parking, on a quiet residential street in Sergeli.',
        // Deliberately empty — exercises the "no nearby places listed"
        // honest-empty state.
        nearPlacesList: const [],
        // Deliberately the wrong wire shape (a bare string, not a list of
        // {key,value} maps) — `optionList` is untyped passthrough per the
        // build brief; this exercises the defensive parser degrading to
        // "no additional information" instead of throwing.
        optionList: 'malformed-not-a-list',
        lat: 41.2100,
        lng: 69.1800,
        tour3dLink: null,
        agentId: 'agent-javlon',
        createdAtSeconds: 1700000500,
      ),
      _ad(
        id: 'ad-1004',
        title: 'Office space on Amir Temur avenue',
        district: 'Mirzo Ulugbek',
        category: 'rent',
        type: 'nonresidential',
        stage: '1',
        price: 900,
        rooms: 4,
        area: 110,
        storey: 6,
        floors: 12,
        repairment: 'excellent',
        furniture: 'withoutFurniture',
        description:
            'Open-plan office space on the 6th floor of a modern business '
            'centre on Amir Temur avenue. Reception desk, meeting room and '
            'high-speed fibre already wired in.',
        nearPlacesList: const [
          'Amir Temur Square metro station',
          'Business centre parking',
        ],
        optionList: const [
          {'key': 'Meeting rooms', 'value': '2'},
          {'key': 'Elevator', 'value': 'Yes'},
        ],
        lat: 41.3350,
        lng: 69.3200,
        tour3dLink: null,
        agentId: 'agent-otabek',
        createdAtSeconds: 1700000400,
      ),
      _ad(
        id: 'ad-1005',
        title: 'Two-room flat in Mirobod',
        district: 'Mirobod',
        category: 'sale',
        type: 'residential',
        stage: '2', // Sold — GET /ads/:id is not stage-scoped, see file doc.
        price: 62500,
        rooms: 2,
        area: 54,
        storey: 7,
        floors: 16,
        repairment: 'normal',
        furniture: 'withFurniture',
        description:
            'Two-room flat on the 7th floor of a 16-storey tower in '
            'Mirobod, close to the city centre. Marked Sold — kept in the '
            'fixture set so `listing-detail` can resolve a non-Active id.',
        nearPlacesList: const ['Mirobod bazaar'],
        optionList: const [
          {'key': 'Elevator', 'value': 'Yes'},
        ],
        lat: 41.2960,
        lng: 69.2790,
        tour3dLink: null,
        agentId: 'agent-shahnoza',
        createdAtSeconds: 1700000700,
      ),
      _ad(
        id: 'ad-1006',
        title: 'Retail space near Chorsu bazaar',
        district: 'Shayxontohur',
        category: 'rent',
        type: 'nonresidential',
        stage: '1',
        price: 1200,
        rooms: 2,
        area: 48,
        storey: 1,
        floors: 1,
        repairment: 'notRepaired',
        furniture: 'withoutFurniture',
        description:
            'Ground-floor retail unit two blocks from Chorsu bazaar, high '
            'foot traffic, street-facing shopfront.',
        nearPlacesList: const ['Chorsu Bazaar (2 min walk)'],
        optionList: const [
          {'key': 'Street frontage', 'value': 'Yes'},
        ],
        lat: 41.3260,
        lng: 69.2280,
        tour3dLink: null,
        agentId: 'agent-sardor',
        createdAtSeconds: 1700000200,
      ),
      _ad(
        id: 'ad-1007',
        title: 'New-build 4-room in Yashnobod',
        district: 'Yashnobod',
        category: 'sale',
        type: 'residential',
        stage: '3', // Draft — same not-stage-scoped reasoning as ad-1005.
        price: 95000,
        rooms: 4,
        area: 88,
        storey: 12,
        floors: 17,
        repairment: 'good',
        furniture: 'withFurniture',
        description:
            'New-build 4-room apartment on the 12th floor, still being '
            'finished out — kept as a Draft-stage fixture.',
        nearPlacesList: const ['Yashnobod metro station (under construction)'],
        optionList: const [
          {'key': 'Balcony', 'value': '1'},
        ],
        lat: 41.2870,
        lng: 69.3350,
        tour3dLink: null,
        agentId: 'agent-otabek',
        createdAtSeconds: 1700000550,
      ),
      _ad(
        id: 'ad-1008',
        title: 'Renovated 1-room near Yakkasaroy park',
        district: 'Yakkasaroy',
        category: 'rent',
        type: 'residential',
        stage: '1',
        price: 400,
        rooms: 1,
        area: 38,
        storey: 3,
        floors: 5,
        repairment: 'normal',
        furniture: 'withFurniture',
        description:
            'Cosy, freshly renovated 1-room flat two minutes from '
            'Yakkasaroy park.',
        nearPlacesList: const ['Yakkasaroy park'],
        optionList: const [
          {'key': 'Balcony', 'value': '1'},
        ],
        // Deliberately no pin — exercises `Ad.hasPin == false` and the
        // Location section's "not available" honest state.
        lat: null,
        lng: null,
        tour3dLink: null,
        agentId: 'agent-kamola',
        createdAtSeconds: 1700000100,
      ),
    ].map(Ad.fromJson).toList(growable: false);

Map<String, dynamic> _agent({
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

/// SCREENS.md §4.3, all 5 rows (agents *and* coworkers) — see this file's
/// doc comment for why `ad-1006`/`ad-1008`'s coworker authors still get an
/// `agent-`-prefixed row here even though `GET /agents/:id` would 404 for a
/// real coworker id.
final List<AgentDetail> listingDetailFixtureAgents =
    [
      _agent(
        id: 'agent-javlon',
        fullName: 'Javlon Rustamov',
        phoneNumber: '+998901112233',
        adsCount: 24,
        dealsClosedCount: 9,
      ),
      _agent(
        id: 'agent-shahnoza',
        fullName: 'Shahnoza Yoldosheva',
        phoneNumber: '+998902223344',
        adsCount: 18,
        dealsClosedCount: 6,
      ),
      _agent(
        id: 'agent-otabek',
        fullName: 'Otabek Yusupov',
        phoneNumber: '+998903334455',
        adsCount: 31,
        dealsClosedCount: 14,
      ),
      _agent(
        id: 'agent-sardor',
        fullName: 'Sardor Abdullayev',
        phoneNumber: '+998904445566',
        adsCount: 11,
        dealsClosedCount: 3,
      ),
      _agent(
        id: 'agent-kamola',
        fullName: 'Kamola Rashidova',
        phoneNumber: '+998905556677',
        adsCount: 8,
        dealsClosedCount: 2,
      ),
    ].map(AgentDetail.fromJson).toList(growable: false);
