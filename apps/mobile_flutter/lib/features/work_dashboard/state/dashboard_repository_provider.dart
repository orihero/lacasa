/// Builds the one [DashboardRepository] the app ships —
/// [LiveDashboardRepository] over a real [LaCasaApi]. Every other Dashboard
/// provider reads through this one instead of constructing a repository
/// itself, which is also what lets a widget test swap in
/// `FakeDashboardRepository` with a single override.
///
/// There is no longer a choice to make here: the fixture repository and
/// `dashboard_mode.dart`'s compile-time `useLiveWorkDashboardApi` switch
/// this provider used to read are both gone. The provider stays because the
/// override seam is the point, not the branch.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/dashboard_repository.dart';
import '../data/live_dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return LiveDashboardRepository(LaCasaApi.create());
});
