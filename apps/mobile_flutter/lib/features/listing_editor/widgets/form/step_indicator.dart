/// `create-listing`'s persistent step indicator (§26: "Step indicator: '1
/// Basics · 2 Details · 3 Photos · 4 Publish.'", §5's "a persistent step
/// indicator (1–4) at the top").
///
/// **It is navigation, not decoration** (finding: it used to be neither —
/// four bars and four captions with no gesture handler anywhere, so fixing
/// a typo'd Title from step 4 cost three Backs and three Nexts through a
/// twelve-field form, and the indicator sat there the whole time looking
/// like the control that ought to do it). Every step *behind* the current
/// one is now a tap target; the current one and everything ahead of it are
/// deliberately inert.
///
/// **Why backward only.** §5's step-progression rule puts validation on
/// **Next** — "Next validates only the current step's required fields
/// before advancing". A tap that jumped forward would be a second way to
/// advance that runs none of it, which is not a shortcut but a hole. A tap
/// that jumps backward is exactly **Back**, which §5 says never
/// re-validates, repeated a few times — so it needs no new rule of its own.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/theme.dart';

/// The 4 step labels in order — was a top-level `const List<String>` before
/// localization; now a function of [AppLocalizations] since the labels are
/// no longer compile-time constants (see [ListingWizardStepIndicator.build]
/// for the one call site).
List<String> listingWizardStepLabels(AppLocalizations l10n) => [
  l10n.listingEditorStepBasicsLabel,
  l10n.listingEditorStepDetailsLabel,
  l10n.listingEditorStepPhotosLabel,
  l10n.listingEditorStepPublishLabel,
];

class ListingWizardStepIndicator extends StatelessWidget {
  const ListingWizardStepIndicator({
    super.key,
    required this.currentStep,
    this.onStepTapped,
  });

  /// 0-indexed (0 = Basics ... 3 = Publish).
  final int currentStep;

  /// Called with the 0-indexed step the user tapped. Only ever invoked for
  /// a step **strictly before** [currentStep] — see this file's doc comment.
  /// Leave `null` to keep the old purely-decorative indicator (nothing does
  /// today; the parameter is optional so a future non-wizard host can embed
  /// the bars as a plain progress read).
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = listingWizardStepLabels(l10n);
    final onTapped = onStepTapped;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenGutter,
        vertical: AppSpacing.base,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i != 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _Step(
                key: ValueKey('wizardStep-$i'),
                // The step number is composed at render time — the ARB
                // holds "Basics"/"Details"/… only, so no locale carries a
                // hardcoded digit.
                label: '${i + 1} ${labels[i]}',
                // The screen reader gets the bare step name, not the
                // numbered caption: "Go to 1 Basics" reads as a stray digit
                // aloud, and the position is already conveyed by the order
                // of the four.
                semanticsLabel: l10n.listingEditorStepGoToSemanticsLabel(
                  labels[i],
                ),
                isReached: i <= currentStep,
                isCurrent: i == currentStep,
                onTap: onTapped != null && i < currentStep
                    ? () => onTapped(i)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One `.step`: a 4px `.step__bar` — accent-gradient once reached, `--sunk`
/// otherwise — over a left-aligned `N Label` caption. The mockup draws no
/// numbered circles and no connector lines; the bars themselves are the
/// progress read.
///
/// A completed step ([onTap] non-null) wraps the whole column in an opaque
/// hit-test region, so the tap target is the full bar-plus-caption cell
/// (roughly 80x25dp on a 360dp screen) rather than the 4dp bar or the ~10px
/// caption text alone — either of those on its own would be well under the
/// touch-size guideline, same reasoning as `ListingPhotoRemoveBadge`'s
/// padded-out 22dp circle.
class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.isReached,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool isReached;
  final bool isCurrent;

  /// `null` for the current step and every step ahead of it — see
  /// [ListingWizardStepIndicator.onStepTapped].
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: isReached ? AppAccent.gradient : null,
            color: isReached ? null : colors.sunk,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: type.caption.copyWith(
            color: isCurrent ? colors.ink : colors.faint,
          ),
        ),
      ],
    );

    final tap = onTap;
    if (tap == null) return column;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: column,
      ),
    );
  }
}
