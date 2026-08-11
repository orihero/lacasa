/// Offline stand-in for [RegionsRepository], backed by
/// `filter_regions_fixtures.dart`'s bundled City/District pair — see that
/// file's doc comment for why it's a small fixture-only vocabulary, not a
/// subset of the real 203-district one.
library;

import '../../../api/api.dart';
import 'filter_regions_fixtures.dart';
import 'regions_repository.dart';

class FixtureRegionsRepository implements RegionsRepository {
  const FixtureRegionsRepository();

  @override
  Future<RegionsData> fetchAll() async => filterFixtureRegionsData;
}
