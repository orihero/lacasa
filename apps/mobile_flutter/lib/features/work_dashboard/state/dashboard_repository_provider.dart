/// Picks [FixtureDashboardRepository] or [LiveDashboardRepository] once, per
/// `dashboard_mode.dart`'s compile-time switch. Every other Dashboard
/// provider reads through this one instead of constructing a repository
/// itself.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/dashboard_mode.dart';
import '../data/dashboard_repository.dart';
import '../data/fixture_dashboard_repository.dart';
import '../data/live_dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (useLiveWorkDashboardApi) {
    return LiveDashboardRepository(LaCasaApi.create());
  }
  return const FixtureDashboardRepository();
});
