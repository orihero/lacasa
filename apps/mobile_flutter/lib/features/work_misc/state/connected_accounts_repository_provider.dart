/// Picks [FixtureConnectedAccountsRepository] or
/// [LiveConnectedAccountsRepository] once, per `connected_accounts_mode.dart`'s
/// compile-time switch — same shape as
/// `features/agents/state/agents_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/connected_accounts_mode.dart';
import '../data/connected_accounts_repository.dart';
import '../data/fixture_connected_accounts_repository.dart';
import '../data/live_connected_accounts_repository.dart';

final connectedAccountsRepositoryProvider =
    Provider<ConnectedAccountsRepository>((ref) {
      if (useLiveConnectedAccountsApi) {
        return LiveConnectedAccountsRepository(LaCasaApi.create());
      }
      return FixtureConnectedAccountsRepository();
    });
