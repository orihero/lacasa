/// Picks [FixtureNotificationsRepository] or [LiveNotificationsRepository]
/// once, per `notifications_mode.dart`'s compile-time switch — same shape
/// as `features/agents/state/agents_repository_provider.dart`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/fixture_notifications_repository.dart';
import '../data/live_notifications_repository.dart';
import '../data/notifications_mode.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  if (useLiveNotificationsApi) {
    return LiveNotificationsRepository(LaCasaApi.create());
  }
  return const FixtureNotificationsRepository();
});
