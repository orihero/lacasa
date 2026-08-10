/// `create-listing`'s footer (§26: "Back/Next per step; final step
/// Create"). [onBack] is `null` on the first step (nothing to go back to);
/// [primaryLabel] is "Next" for steps 1–3, "Create" for step 4.
library;

import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';

class ListingWizardFooter extends StatelessWidget {
  const ListingWizardFooter({
    super.key,
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.submitting = false,
  });

  final VoidCallback? onBack;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.base,
        AppSpacing.screenGutter,
        MediaQuery.of(context).padding.bottom + AppSpacing.base,
      ),
      child: Row(
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
                    borderRadius: BorderRadius.circular(AppRadii.pillButton),
                  ),
                  child: Text('Back', style: type.rowTitle.copyWith(color: colors.ink2)),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
          ],
          Expanded(
            flex: onBack != null ? 1 : 2,
            child: GestureDetector(
              key: const ValueKey('listingWizard-primary'),
              onTap: submitting ? null : onPrimary,
              child: Opacity(
                opacity: onPrimary == null ? 0.6 : 1,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppAccent.gradient,
                    borderRadius: BorderRadius.circular(AppRadii.pillButton),
                    boxShadow: const [
                      BoxShadow(
                        color: AppAccent.shadowColor,
                        blurRadius: 22,
                        spreadRadius: -8,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(primaryLabel, style: type.rowTitle.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
