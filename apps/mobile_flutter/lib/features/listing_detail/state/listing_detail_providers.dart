/// Riverpod state for `listing-detail`. Two independent families, keyed by
/// ad id and agent id respectively, mirroring the two-method split
/// `listing_detail_repository.dart` documents: the ad is fatal to the
/// screen, the agent is not, and merging them into one "screen data" fetch
/// would erase exactly that distinction.
///
/// **Families, not plain providers**, because this screen is pushed with an
/// id and more than one instance can be alive at once — a user can tap from
/// Home into `ad-1001`, tap its agent, tap another listing, and now two
/// listing-detail routes sit on the same back stack. A single shared
/// provider would have them fight over one slot.
///
/// **`.autoDispose`**, so state is dropped when the last route watching an
/// id pops. Without it every listing a user ever opened would be retained
/// (with its `Ad`, and its agent) for the process lifetime. The
/// counterargument — that popping back to a listing re-fetches it — costs
/// one request against a fixture/HTTP call that is already cheap and always
/// re-renders from a loading state the screen already implements.
///
/// **[FutureProvider], not [AsyncNotifier]**, unlike `home_feed_providers`
/// and `search_providers`: those expose commands (apply filters, set sort,
/// add a recent search) that need a notifier to hold them. This screen has
/// exactly one operation, "load", and one way to redo it — `ref.invalidate`,
/// which the Retry affordance calls. A notifier here would be a class whose
/// only member is `build`.
///
/// **Retry semantics.** Riverpod 3 auto-retries a thrown [Exception] with
/// exponential backoff (`ProviderContainer.defaultRetry`), which is left on
/// deliberately: a listing opened in a tunnel fills itself in when signal
/// returns. The visible Retry button is not redundant with it — it forces
/// an immediate attempt instead of waiting out the current backoff step.
/// Widget tests disable the automatic half at the [ProviderScope] level
/// (`retry: (_, _) => null`) so an error assertion is not racing a timer;
/// that is the same thing `home_feed_screen_test.dart` already does.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'listing_detail_repository_provider.dart';

/// The listing itself. A failure here is terminal for the screen — the
/// error propagates so the screen can render its full retry state, since
/// there is nothing to show without the ad.
final listingDetailProvider = FutureProvider.autoDispose.family<Ad, String>((
  ref,
  adId,
) {
  return ref.read(listingDetailRepositoryProvider).fetchAd(adId);
});

/// The listing's agent, for the agent block only. Resolves to `null` rather
/// than throwing for every failure mode — see
/// [ListingDetailRepository.fetchAgent]. Consumers therefore only ever see
/// `AsyncData(null)`, never `AsyncError`, for a missing agent, and render
/// the block's "unavailable" state from that.
final listingAgentProvider = FutureProvider.autoDispose
    .family<AgentDetail?, String>((ref, agentId) {
      return ref.read(listingDetailRepositoryProvider).fetchAgent(agentId);
    });
