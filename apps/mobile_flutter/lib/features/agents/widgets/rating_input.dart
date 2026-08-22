/// A tappable 1-5 star picker for `agent_review_sheet.dart`'s "leave a
/// review" form — the input counterpart to `shared/widgets/rating_stars.dart`'s
/// read-only display. Kept as its own small widget rather than folded into
/// [RatingStars] itself: one is a static row driven by a nullable server
/// aggregate, the other is a controlled input driven by local form state,
/// and a single widget trying to be both would need a `readOnly` flag and
/// two different color/tap contracts fighting over one build method.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';

class RatingInput extends StatelessWidget {
  const RatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.starSize = 34,
  });

  /// 0 means "nothing chosen yet" — distinct from a real 1-star rating, so
  /// the sheet can tell "hasn't picked" apart from "picked the lowest
  /// score" when deciding whether Submit is enabled.
  final int value;

  final ValueChanged<int> onChanged;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Semantics(
            button: true,
            selected: i <= value,
            label: l10n.reviewsRatingInputStarLabel(i),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: starSize,
                  // Same pairing rule as `shared/widgets/rating_stars.dart`:
                  // the unpicked star uses `glyphTrack` so it stays lower
                  // contrast than the picked one. Borrowing the `faint`
                  // *text* token reversed that. See
                  // `LaCasaColors.glyphTrack`.
                  color: i <= value
                      ? AppStatusColors.ratingStar
                      : colors.glyphTrack,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
