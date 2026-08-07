/// Bundled seed data for [FixtureSearchRepository], transcribed from
/// SCREENS.md §4.1 (property listings) — **all 8 rows**, including the two
/// `home_feed_fixtures.dart` deliberately omits (`ad-1005` Sold, `ad-1007`
/// Draft). Home only ever needed the always-active browse feed; this
/// screen's fixture repository needs the full pool so it can apply the same
/// `stage: "ACTIVE"` scoping the real `GET /ads` endpoint applies
/// server-side (see `search_repository.dart`) rather than baking that
/// scoping into what's bundled here — the fixture and the live API should
/// agree on *why* Sold/Draft never surface on this public screen, not just
/// that they don't.
///
/// `photos`/`media` are deliberately left empty on every fixture ad, same
/// rationale as `home_feed_fixtures.dart`: no bundled image asset to point
/// at, and `ListingPhoto` already renders a themed placeholder for an empty
/// photo list.
///
/// `lat`/`lng` are also left `null` on every fixture ad — SCREENS.md §4.1
/// has no coordinate column, and `map-view`'s own screen (built by a
/// different agent in this batch) is responsible for whatever it does with
/// `Ad.hasPin == false` results.
library;

import '../../../api/api.dart';

Map<String, dynamic> _ad({
  required String id,
  required String title,
  required String district,
  required String category, // 'sale' | 'rent'
  required String type, // 'residential' | 'nonresidential'
  required String stage, // '1' active | '2' sold | '3' draft
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
    'stage': stage,
    'description': null,
    'nearPlacesList': const <String>[],
    'optionList': null,
    'active': stage == '1',
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

/// SCREENS.md §4.1, all 8 rows, in table order (`ad-1001..ad-1008`).
final List<Ad> searchFixtureAllAds =
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
        agentId: 'agent-javlon',
        createdAtSeconds: 1700000700,
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
        agentId: 'agent-shahnoza',
        createdAtSeconds: 1700000600,
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
        agentId: 'agent-otabek',
        createdAtSeconds: 1700000400,
      ),
      _ad(
        id: 'ad-1005',
        title: 'Two-room flat in Mirobod',
        district: 'Mirobod',
        category: 'sale',
        type: 'residential',
        stage: '2', // sold — must never surface via public search
        price: 62500,
        rooms: 2,
        area: 54,
        storey: 7,
        floors: 16,
        agentId: 'agent-shahnoza',
        createdAtSeconds: 1700000300,
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
        agentId: 'agent-sardor',
        createdAtSeconds: 1700000200,
      ),
      _ad(
        id: 'ad-1007',
        title: 'New-build 4-room in Yashnobod',
        district: 'Yashnobod',
        category: 'sale',
        type: 'residential',
        stage: '3', // draft — must never surface via public search
        price: 95000,
        rooms: 4,
        area: 88,
        storey: 12,
        floors: 17,
        agentId: 'agent-otabek',
        createdAtSeconds: 1700000100,
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
        agentId: 'agent-kamola',
        createdAtSeconds: 1700000000,
      ),
    ].map(Ad.fromJson).toList(growable: false);
