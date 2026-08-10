/// Picks [FixtureCoworkersRepository] or [LiveCoworkersRepository] once,
/// per `coworkers_mode.dart`'s compile-time switch — same shape as
/// `features/agents/state/agents_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/coworkers_mode.dart';
import '../data/coworkers_repository.dart';
import '../data/fixture_coworkers_repository.dart';
import '../data/live_coworkers_repository.dart';

final coworkersRepositoryProvider = Provider<CoworkersRepository>((ref) {
  if (useLiveCoworkersApi) {
    return LiveCoworkersRepository(LaCasaApi.create());
  }
  return FixtureCoworkersRepository();
});
