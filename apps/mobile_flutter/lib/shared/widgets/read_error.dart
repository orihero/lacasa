/// The one place a **read** failure is turned into copy.
///
/// `api/transport.dart` already classifies a request that never reached the
/// server — a connection timeout, a refused connection, a cancellation —
/// into a [NetworkException] with its own message, and every *form* in this
/// app branches on that type to say "No connection. Check your network and
/// try again." instead of "Something went wrong". **Not one read path did.**
/// Ten-plus list surfaces each bound the error object and then ignored it,
/// rendering a fixed per-screen string: `search_results_list.dart`'s
/// "Couldn't load listings.", `my_listings_list.dart`'s "Couldn't load your
/// ads.", `coworkers_list_screen.dart`'s "Couldn't load your coworkers",
/// notifications', the featured rail's, saved-listings', the agents
/// directory's, publish-status', both leads views'.
///
/// **Why a per-screen string alone was the defect.** Each of those strings
/// is individually correct — the screen genuinely could not load its data —
/// and each is individually *useless* in the one case that produces all of
/// them at once. Turn the network off and the app fragments into a dozen
/// identical anonymous "Couldn't load X" cards: a dozen separate-looking
/// failures, none naming the single fact that explains every one of them,
/// each inviting a Retry that cannot possibly succeed. The user is left to
/// infer "the app is broken" from twelve independent accusations when the
/// truth is "you are offline". There is no global connectivity banner in
/// this build to carry that fact instead, so the read paths have to carry it
/// themselves — and they have to carry it *identically*, or the user still
/// sees a dozen different sentences for one condition.
///
/// So the per-screen string is not deleted, it is **demoted to a fallback**:
/// it stays exactly right for a 500, a malformed body, or a permission
/// error, where "which screen failed" really is the most specific thing the
/// app knows. [describeReadError] picks between the two.
///
/// ```dart
/// error: (error, _) => FullWidthState(
///   icon: readErrorIcon(error),
///   message: describeReadError(
///     l10n,
///     error,
///     fallback: l10n.myListingsLoadErrorMessage,
///   ),
///   actionLabel: l10n.sharedRetryLabel,
///   onAction: () => ref.invalidate(myListingsResultsProvider),
/// ),
/// ```
///
/// [readErrorIcon] is split out rather than folded into a single
/// value-object return because [FullWidthState] and [RailRetryCard] take
/// `icon` and `message` as separate positional-ish named arguments; two
/// small pure functions read better at a call site than
/// `final d = describe(...); ... d.icon ... d.message`, and a caller whose
/// widget hard-codes its own glyph (today [RailRetryCard] does) can take the
/// message half alone without carrying an unused field.
///
/// This deliberately does **not** branch on [ApiErrorException] — a decoded
/// server error carries the server's own words, and `lib/l10n/README.md`'s
/// rule is that `ApiErrorBody.message` is rendered verbatim or not at all,
/// never re-keyed through an ARB lookup. A screen that wants to show a
/// specific server code's copy should keep doing that in its own file; this
/// helper only claims the case where there is no server response at all.
library;

import 'package:flutter/material.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';

/// True when [error] is a request that never got an answer from the server
/// — the connectivity case, as classified by `api/transport.dart`.
///
/// Exposed so a caller can make a *third* decision from the same predicate
/// (suppressing a "Retry" that cannot work, say) without re-deriving the
/// type test and drifting away from what [describeReadError] considers
/// offline.
bool isOfflineReadError(Object error) => error is NetworkException;

/// The message to render for a failed read: a single shared "you're
/// offline" string when [error] is a [NetworkException], and the caller's
/// own per-screen [fallback] otherwise.
///
/// [fallback] is required, not defaulted: the per-screen string is the
/// better copy in every non-connectivity case, and a default would quietly
/// let a call site drop it and regress the screen to a generic error.
String describeReadError(
  AppLocalizations l10n,
  Object error, {
  required String fallback,
}) {
  return isOfflineReadError(error) ? l10n.sharedOfflineErrorMessage : fallback;
}

/// The glyph to pair with [describeReadError]'s output.
///
/// `wifi_off_rounded` when offline — the icon is the half of the state a
/// user reads first, and leaving a generic error triangle above "No
/// connection" wastes it. Every existing read call site passes
/// `Icons.error_outline_rounded`, which is why that is the default: swapping
/// a site over is a one-word change, not a re-decision about its non-offline
/// glyph.
IconData readErrorIcon(
  Object error, {
  IconData fallback = Icons.error_outline_rounded,
}) {
  return isOfflineReadError(error) ? Icons.wifi_off_rounded : fallback;
}
