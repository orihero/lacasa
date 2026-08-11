/// Bundled seed data for [FixtureRegionsRepository]. **Deliberately not a
/// subset of the real `@lacasa/domain` regions.json** (14 regions / 203
/// districts, official Uzbek-language names like "Toshkent shahri" /
/// "Chilonzor tumani") — this build's own `search_fixtures.dart`/
/// `filter_ads_fixtures.dart` seed ads were already authored against
/// SCREENS.md §4.1 with plain English names (`city: 'Tashkent'`,
/// `district: 'Chilonzor'`, no "tumani" suffix), and `Ad.district`/`Ad.city`
/// are free text everywhere (never validated against the regions
/// vocabulary — see `filter_options.dart`'s former gap note). Bundling the
/// *real* official names here instead would give the fixture-mode picker
/// options that can never exact-match any bundled ad, silently zeroing out
/// every fixture search the moment a user actually used the picker —
/// worse than admitting this is a small fixture-only vocabulary, sized and
/// spelled to agree with this build's own seed ads, not the live server's.
///
/// **One region.** The seed ads only ever use `city: 'Tashkent'`, so a
/// second/third region here would be picker chrome with nothing behind it
/// — [FilterCityDistrictSection]'s cascade is still fully exercised (City
/// disabled → enabled → District list scoped to the chosen region) with
/// just the one, same as every other *_fixtures.dart file in this codebase
/// only ever bundles what its own screen's fixture ads actually reference.
/// [LiveRegionsRepository] is what serves the real 14/203 vocabulary.
library;

import '../../../api/api.dart';

const List<Region> filterFixtureRegions = [Region(id: 1, name: 'Tashkent')];

/// Names transcribed verbatim from `search_fixtures.dart`/
/// `filter_ads_fixtures.dart`'s own `district` values.
const List<District> filterFixtureDistricts = [
  District(id: 1, regionId: 1, name: 'Chilonzor'),
  District(id: 2, regionId: 1, name: 'Yunusobod'),
  District(id: 3, regionId: 1, name: 'Sergeli'),
  District(id: 4, regionId: 1, name: 'Mirzo Ulugbek'),
  District(id: 5, regionId: 1, name: 'Mirobod'),
  District(id: 6, regionId: 1, name: 'Shayxontohur'),
  District(id: 7, regionId: 1, name: 'Yashnobod'),
  District(id: 8, regionId: 1, name: 'Yakkasaroy'),
];

const RegionsData filterFixtureRegionsData = RegionsData(
  regions: filterFixtureRegions,
  districts: filterFixtureDistricts,
);
