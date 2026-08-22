/// A controllable [RegionsRepository] for this feature's filter-sheet
/// handoff tests.
///
/// `regionsRepositoryProvider` builds `LiveRegionsRepository` around
/// `LaCasaApi.create()` unconditionally now — the bundled
/// `FixtureRegionsRepository` and the `FLUTTER_TEST` switch in
/// `lib/api/app_mode.dart` that used to force it are both gone. The ambient
/// override installs `InertRegionsRepository`, which answers with an empty
/// vocabulary; that is right for the tests that merely pass through the
/// sheet, but the two handoff tests here actually *pick a city*, so they
/// need a repository that serves one. Hence this fake, wired with
/// `testRegionsData` from `test/features/filter/support/fake_regions_data
/// .dart` (whose own doc comment already names this file's suite as a
/// consumer) so both suites pick from the same vocabulary.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/data/regions_repository.dart';

class FakeRegionsRepository implements RegionsRepository {
  FakeRegionsRepository(this.data);

  final RegionsData data;

  @override
  Future<RegionsData> fetchAll() async => data;
}
