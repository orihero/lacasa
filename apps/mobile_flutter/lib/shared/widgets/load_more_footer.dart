/// The trailing sentinel row for a real, server-paged infinite-scroll list —
/// a spinner while the next page is in flight, or a tappable "Couldn't load
/// more — Retry" once it fails. Promoted out of `features/search`'s
/// `search_results_list.dart` (the first of this app's several server-paged
/// lists — `search`, `my-listings`, `agents`' review list) once a second
/// caller (`my_listings_list.dart`) needed the exact same failed/retry
/// affordance: without a visible "this failed" state, a load-more failure on
/// a *scroll-triggered* list (unlike a manual "Show more" button) silently
/// stops growing with no explanation the user can act on beyond "scroll
/// again and hope" — this widget is that explanation.
///
/// Deliberately not adopted by `agent_reviews_section.dart`'s reviews list:
/// that surface pages via an explicit "Show more reviews" tap, not a scroll
/// listener, so the button reappearing after a failure already **is** the
/// retry affordance — a second, redundant "failed" label under a button
/// whose own re-appearance already says "try again" would be noise, not
/// clarity. This widget earns its place specifically where the trigger is
/// invisible (scrolling) and the failure would otherwise be too.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import 'tap_target.dart';

class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({
    super.key,
    required this.failed,
    required this.onRetry,
    // Per-caller keys, not a fixed pair baked into this shared widget —
    // `search_results_list.dart`'s existing tests already key off
    // `searchLoadMoreRetry`/`searchLoadMoreSpinner`; forcing one shared
    // literal key here would either break that screen's tests on adoption
    // or force every future caller to match search's naming for no reason
    // beyond "got here first". Default to a generic pair so a new caller
    // that doesn't care can omit these entirely.
    this.retryKey = const ValueKey('loadMoreRetry'),
    this.spinnerKey = const ValueKey('loadMoreSpinner'),
  });

  final bool failed;
  final VoidCallback onRetry;
  final Key retryKey;
  final Key spinnerKey;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    if (failed) {
      final label = AppLocalizations.of(context).sharedLoadMoreFailedLabel;
      return Center(
        // Through [TapTarget], not a bare [GestureDetector] around the text:
        // this is the only affordance a scroll-triggered list gives the user
        // after a failed page, and as a bare detector it was tappable over
        // exactly the ~14dp of `bodySmall` glyph the font drew — under both
        // platform floors, on a row the user has to reach for at the very
        // bottom of a long list. See `tap_target.dart`.
        child: TapTarget(
          key: retryKey,
          semanticsLabel: label,
          onTap: onRetry,
          child: Text(
            label,
            style: type.bodySmall.copyWith(color: AppStatusColors.warningText),
          ),
        ),
      );
    }

    // `.endnote{margin:18px 0 4px;text-align:center;font-size:11px;
    // color:var(--faint)}` — the sentinel says what it is doing rather
    // than spinning unlabelled. Same `.endnote` rule on every list that
    // pages this way (search, my-listings, leads, saved-listings), so the
    // caption lives here with the spinner rather than per caller.
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            key: spinnerKey,
            width: 20,
            height: 20,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context).sharedLoadMoreLoadingLabel,
            textAlign: TextAlign.center,
            style: type.bodySmall.copyWith(color: colors.faint),
          ),
        ],
      ),
    );
  }
}
