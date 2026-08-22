/// `create-listing`'s footer (§26: "Back/Next per step; final step
/// Create"). [onBack] is `null` on the first step (nothing to go back to);
/// [primaryLabel] is "Next" for steps 1–3, "Create" for step 4.
///
/// **Why a null [onPrimary] drops the gradient instead of dimming it**
/// (UX audit §10.5, "disabled states dim the explanation hardest"). The
/// primary control used to keep `AppAccent.gradient` and its 22dp accent
/// glow under a flat `Opacity(0.6)`. A 60%-alpha accent gradient over this
/// screen's background is still an unmistakably *accent* pill with a
/// coloured shadow under it, so "you cannot continue yet" and "continue"
/// read as the same affordance at a glance — on the one control that gates
/// creating a listing at all. Two things follow from that:
///
/// 1. The disabled state is a **different** control, not a faded one: the
///    `colors.sunk` fill and `colors.ink2` label the Back button already
///    uses, and no glow at all. Nothing about it says "accent", so nothing
///    about it says "tap me".
/// 2. It is paired with the reason. Removing the affordance without
///    saying why is the failure §10.5 is actually about, so the disabled
///    footer prints
///    [AppLocalizations.listingEditorWizardDisabledReasonMessage] above the
///    row at full opacity in `colors.ink2` — never dimmed, because the
///    line that explains the dimming is the last thing that may be hard to
///    read.
///
/// [Semantics] carries the same fact for screen readers via
/// `enabled: false`, which the bare `Opacity` never did — a
/// [GestureDetector] with a null `onTap` is simply silent about being
/// unavailable.
///
/// **[submitting] is deliberately *not* this state.** Mid-submit the
/// button keeps its accent fill and swaps the label for a spinner: the
/// work is in flight, the tap did land, and there is no user-fixable
/// reason to explain. Only a null [onPrimary] — "this step is not
/// satisfied yet" — is the disabled case.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/theme.dart';

class ListingWizardFooter extends StatelessWidget {
  const ListingWizardFooter({
    super.key,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.submitting = false,
    this.disabledReason,
  });

  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool submitting;

  /// Why the primary control is unavailable, shown above the row whenever
  /// [onPrimary] is `null`. Defaults to
  /// [AppLocalizations.listingEditorWizardDisabledReasonMessage] — a
  /// caller with a *more specific* reason ("upload a photo first") should
  /// pass it, because a specific reason is always the better copy; the
  /// generic one exists so that no caller can disable the button while
  /// saying nothing.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final enabled = onPrimary != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.base,
        AppSpacing.screenGutter,
        MediaQuery.of(context).padding.bottom + AppSpacing.base,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!enabled) ...[
            Text(
              key: const ValueKey('listingWizard-disabledReason'),
              disabledReason ?? l10n.listingEditorWizardDisabledReasonMessage,
              textAlign: TextAlign.center,
              // `ink2`, at full opacity, on purpose — see this file's doc
              // comment. This is the only thing on screen that tells the
              // user what to do next.
              style: type.caption.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              if (onBack != null) ...[
                Expanded(
                  child: GestureDetector(
                    key: const ValueKey('listingWizard-back'),
                    onTap: onBack,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.sunk,
                        borderRadius: BorderRadius.circular(
                          AppRadii.pillButton,
                        ),
                      ),
                      child: Text(
                        l10n.listingEditorWizardBackLabel,
                        style: type.rowTitle.copyWith(color: colors.ink2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
              ],
              Expanded(
                flex: onBack != null ? 1 : 2,
                child: Semantics(
                  button: true,
                  enabled: enabled,
                  child: GestureDetector(
                    key: const ValueKey('listingWizard-primary'),
                    onTap: submitting ? null : onPrimary,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: enabled ? null : colors.sunk,
                        gradient: enabled ? AppAccent.gradient : null,
                        borderRadius: BorderRadius.circular(
                          AppRadii.pillButton,
                        ),
                        boxShadow: enabled
                            ? const [
                                BoxShadow(
                                  color: AppAccent.shadowColor,
                                  blurRadius: 22,
                                  spreadRadius: -8,
                                  offset: Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              primaryLabel,
                              style: type.rowTitle.copyWith(
                                color: enabled ? Colors.white : colors.ink2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
