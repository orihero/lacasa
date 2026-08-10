/// Riverpod state for `notifications` (SCREENS.md §22) — one plain fetch,
/// no mutation (no read/unread toggling exists anywhere — see
/// `live_notifications_repository.dart`'s doc comment), so a
/// [FutureProvider] is enough; a retry re-fetches via `ref.invalidate`,
/// same pattern `agentDetailProvider` (`features/agents/state/
/// agents_providers.dart`) uses for its own single-fetch screens.
///
/// Not `.autoDispose`: this is a pushed screen reachable from a bell icon
/// on more than one header, likely to be opened and left multiple times in
/// one session — same non-autoDispose reasoning
/// `connected_accounts_providers.dart` gives for its own provider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shared.dart';
import 'notifications_repository_provider.dart';

final notificationsProvider =
    FutureProvider<List<WorkNotificationFixture>>((ref) {
      return ref.read(notificationsRepositoryProvider).fetchNotifications();
    });
