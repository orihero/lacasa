/// A small, controllable [RegionsData] for `filter-sheet`'s City/District
/// picker tests — no coupling to `filter_regions_fixtures.dart`'s bundled
/// data, same "fake, not the real fixture" principle
/// `FakeFilterRepository` already follows for the live-count preview.
/// Shared with `test/features/search/search_screen_test.dart`'s
/// filter-sheet-handoff tests, which open the same sheet.
library;

import 'package:lacasa_mobile/api/api.dart';

const testRegionsData = RegionsData(
  regions: [
    Region(id: 1, name: 'Tashkent'),
    Region(id: 2, name: 'Samarkand'),
  ],
  districts: [
    District(id: 1, regionId: 1, name: 'Chilonzor'),
    District(id: 2, regionId: 1, name: 'Yunusobod'),
    District(id: 3, regionId: 2, name: 'Registon'),
  ],
);
