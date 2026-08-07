/// The uppercase eyebrow label above every field group in the sheet —
/// `LaCasaTypography.label`'s doc comment requires the caller apply
/// `.toUpperCase()` itself (Flutter has no CSS text-transform
/// equivalent); this is the one place that rule is applied for this
/// feature.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class FilterFieldLabel extends StatelessWidget {
  const FilterFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: type.label.copyWith(color: colors.muted),
      ),
    );
  }
}
