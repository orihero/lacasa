/// Bundled seed data for [FixtureFilterRepository], transcribed from
/// SCREENS.md §4.1 (property listings) — all 8 rows this time, not just
/// the 6 Active ones `features/home/data/home_feed_fixtures.dart` bundles.
/// A filter count preview that only ever "sees" 6 of the 8 seed ads would
/// silently disagree with what `listing-search`'s own results list (which
/// needs all 8 to exercise Sold/Draft-adjacent states, per the recon
/// brief) shows — this file exists so the two can agree once
/// `listing-search` is built, even though this feature never renders the
/// Sold/Draft ones itself (the repository always re-scopes to
/// `stage: "ACTIVE"` before counting — see `fixture_filter_repository.dart`
/// — mirroring `GET /ads`'s own server-side scoping for a non-agent
/// caller, see `ads_resource.dart`).
///
/// This is a second, independent transcription of the same SCREENS.md
/// table `home_feed_fixtures.dart` already transcribes — the two files
/// cannot share code because `home_feed_fixtures.dart` is not exported
/// from `features/home/home.dart` and this task's hard rules forbid
/// reaching into another feature's directory. Flagged in the build report
/// as a real duplication that should be resolved by promoting one shared
/// ads-fixture file (e.g. under `lib/shared/`) the next time either
/// feature is touched.
///
/// SCREENS.md §4.1's table has no `repairment`/`furniture` column, so
/// there is no spec value to transcribe for those two fields. The values
/// below are filled in locally, only so the Furniture/Repair chip filters
/// have something non-trivial to match against in fixture mode — they are
/// not a real API field being invented (both fields are real, documented
/// `Ad` fields; only *which* seed ad has *which* value is this file's own
/// choice, same as `createdAtSeconds` ordering already is in
/// `home_feed_fixtures.dart`). Never treat these two columns as
/// spec-mandated.
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
  required String stage, // '1' active | '2' sold | '3' draft
  required String repairment,
  required String furniture,
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
    'repairment': repairment,
    'rooms': rooms,
    'area': area,
    'storey': storey,
    'floors': floors,
    'furniture': furniture,
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

/// All 8 of SCREENS.md §4.1's listings, `ad-1001`..`ad-1008` in table
/// order.
final List<Ad> filterFixtureAds =
    [
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
        stage: '1',
        repairment: 'good',
        furniture: 'withoutFurniture',
        agentId: 'agent-javlon',
        createdAtSeconds: 1700000700,
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
        stage: '1',
        repairment: 'excellent',
        furniture: 'withFurniture',
        agentId: 'agent-shahnoza',
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
        stage: '1',
        repairment: 'normal',
        furniture: 'withoutFurniture',
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
        stage: '1',
        repairment: 'good',
        furniture: 'withoutFurniture',
        agentId: 'agent-otabek',
        createdAtSeconds: 1700000400,
      ),
      _ad(
        id: 'ad-1005',
        title: 'Two-room flat in Mirobod',
        district: 'Mirobod',
        category: 'sale',
        type: 'residential',
        price: 62500,
        rooms: 2,
        area: 54,
        storey: 7,
        floors: 16,
        stage: '2',
        repairment: 'normal',
        furniture: 'withFurniture',
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
        stage: '1',
        repairment: 'notRepaired',
        furniture: 'withoutFurniture',
        agentId: 'agent-sardor',
        createdAtSeconds: 1700000200,
      ),
      _ad(
        id: 'ad-1007',
        title: 'New-build 4-room in Yashnobod',
        district: 'Yashnobod',
        category: 'sale',
        type: 'residential',
        price: 95000,
        rooms: 4,
        area: 88,
        storey: 12,
        floors: 17,
        stage: '3',
        repairment: 'notRepaired',
        furniture: 'withoutFurniture',
        agentId: 'agent-otabek',
        createdAtSeconds: 1700000100,
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
        stage: '1',
        repairment: 'excellent',
        furniture: 'withFurniture',
        agentId: 'agent-kamola',
        createdAtSeconds: 1700000000,
      ),
    ].map(Ad.fromJson).toList(growable: false);
