/// A controllable [RegionsRepository] for `basics_step_test.dart`'s
/// City/District picker coverage (finding M6) — deliberately not
/// `filter_regions_fixtures.dart`'s bundled single-region vocabulary
/// (`FixtureRegionsRepository`, what `flutter test`'s forced-fixtures mode
/// actually wires up by default), since exercising the City→District
/// *cascade* (a City change scoping District to a different region) needs
/// at least two regions to change between. Same "fake, not the real
/// fixture" principle as `test/features/filter/support/fake_regions_data
/// .dart`'s own `testRegionsData` — that file lives under `features/filter/`
/// (not owned by this change) so this is its own copy rather than an
/// import across feature test boundaries.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/data/regions_repository.dart';

class FakeRegionsRepository implements RegionsRepository {
  FakeRegionsRepository({this.data, this.error});

  RegionsData? data;
  Object? error;

  @override
  Future<RegionsData> fetchAll() async {
    if (error != null) return Future.error(error!);
    return data!;
  }
}
