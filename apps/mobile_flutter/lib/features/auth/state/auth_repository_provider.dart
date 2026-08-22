/// Picks [FixtureAuthRepository] or [LiveAuthRepository] once, per
/// `auth_mode.dart`'s compile-time switch — same shape as
/// `features/agents/state/agents_repository_provider.dart`.
///
/// [FixtureAuthRepository] is handed its own [SecureTokenStorage] rather
/// than sharing a Dart object with [LiveAuthRepository]'s
/// `LaCasaApi.create()`, and that is fine, not an oversight: see
/// `live_auth_repository.dart`'s doc comment for why two separate
/// `SecureTokenStorage()` instances are still two handles onto the exact
/// same persisted keystore entry.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/auth_repository.dart';
import '../data/live_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return LiveAuthRepository(LaCasaApi.create());
});
