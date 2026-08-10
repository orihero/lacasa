/// `create-listing`'s persistent step indicator (§26: "Step indicator: '1
/// Basics · 2 Details · 3 Photos · 4 Publish.'", §5's "a persistent step
/// indicator (1–4) at the top").
library;

import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';

const List<String> kListingWizardStepLabels = [
  'Basics',
  'Details',
  'Photos',
  'Publish',
];

class ListingWizardStepIndicator extends StatelessWidget {
  const ListingWizardStepIndicator({super.key, required this.currentStep});

  /// 0-indexed (0 = Basics ... 3 = Publish).
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenGutter,
        vertical: AppSpacing.base,
      ),
      child: Row(
        children: [
          for (var i = 0; i < kListingWizardStepLabels.length; i++) ...[
            if (i != 0)
              Expanded(
                child: Container(
                  key: ValueKey('wizardStep-connector-$i'),
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  color: i <= currentStep ? AppAccent.color : colors.line,
                ),
              ),
            _StepDot(
              key: ValueKey('wizardStep-dot-$i'),
              index: i,
              label: kListingWizardStepLabels[i],
              isDone: i < currentStep,
              isActive: i == currentStep,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    super.key,
    required this.index,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  final int index;
  final String label;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final onOrDone = isDone || isActive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onOrDone ? AppAccent.color : colors.sunk,
            shape: BoxShape.circle,
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: type.micro.copyWith(
                    color: isActive ? Colors.white : colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: type.micro.copyWith(
            color: onOrDone ? colors.ink : colors.faint,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
