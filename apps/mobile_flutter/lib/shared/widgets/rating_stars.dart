/// The read-only star row for an agent's aggregate rating — SCREENS.md
/// §3.9's **"Review: {rating}/5"**, quoted verbatim into the row's own
/// text so the directory card, `agent-profile`'s identity block, and
/// `listing-detail`'s agent block all render the identical string rather
/// than three independent paraphrases.
///
/// **`average == null` always renders "No reviews yet", never a zero-star
/// row.** This is the same rule [AgentSummary.ratingAverage]'s doc comment
/// pins down at the model layer — a SQL aggregate over zero rows produces
/// no row at all, not a row averaging to zero, so `null` and `0.0` are
/// different facts. A widget that collapsed them would silently reintroduce
/// the exact false trust signal `apps/mobile_flutter/README.md`'s
/// data-model gap note used to refuse outright. Every call site passes
/// [AgentSummary.ratingAverage]/[AgentDetail.ratingAverage] straight
/// through — never `?? 0`, never `.round()`'d before reaching here.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.average,
    required this.count,
    this.starSize = 13,
    this.showLabel = true,
  });

  /// `null` means "no reviews yet" — see this file's doc comment. Otherwise
  /// the server's own one-decimal aggregate (`Math.round(avg * 10) / 10`,
  /// `apps/api/src/services/agentService.js#ratingFor`), printed as-is.
  final double? average;

  /// `0` exactly when [average] is `null`; otherwise how many reviews the
  /// average was computed from. Shown alongside the average, not derived
  /// from it — a caller with a stale [average] but no [count] would be a
  /// contradiction this widget has no way to detect on its own.
  final int count;

  final double starSize;

  /// `false` renders the five icons alone, no trailing "Review: n/5 (m)"
  /// text — for a *single* review's own stars (`agent_reviews_section
  /// .dart`'s `_ReviewTile`), where that aggregate-shaped label would be
  /// meaningless (one review has no separate "count" to report). The
  /// `average == null` → "No reviews yet" branch still applies when this is
  /// `false`, even though no caller currently exercises it that way.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final rating = average;
    if (rating == null) {
      return showLabel
          ? Text(
              AppLocalizations.of(context).sharedNoReviewsYetLabel,
              style: type.bodySmall.copyWith(color: colors.muted),
            )
          : const SizedBox.shrink();
    }

    // Five discrete icons can only draw whole stars, so the *icon* row
    // rounds to the nearest whole star; the printed number stays the exact
    // one-decimal value the server sent ("Review: 4.5/5") rather than also
    // being rounded to match the icons.
    final filled = rating.round().clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(right: i == 4 ? 0 : 1),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: starSize,
              color: i < filled ? AppStatusColors.ratingStar : colors.faint,
            ),
          ),
        if (showLabel) ...[
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              AppLocalizations.of(
                context,
              ).sharedRatingLabel(rating.toStringAsFixed(1), count),
              overflow: TextOverflow.ellipsis,
              style: type.bodySmall.copyWith(color: colors.muted),
            ),
          ),
        ],
      ],
    );
  }
}
