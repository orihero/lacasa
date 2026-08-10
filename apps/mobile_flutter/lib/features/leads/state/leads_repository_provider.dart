/// Picks [FixtureLeadsRepository] or [LiveLeadsRepository] once, per
/// `leads_mode.dart`'s compile-time switch. Every other `leads` provider
/// reads through this one instead of constructing a repository itself.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/fixture_leads_repository.dart';
import '../data/leads_mode.dart';
import '../data/leads_repository.dart';
import '../data/live_leads_repository.dart';

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  if (useLiveLeadsApi) {
    return LiveLeadsRepository(LaCasaApi.create());
  }
  return FixtureLeadsRepository();
});
