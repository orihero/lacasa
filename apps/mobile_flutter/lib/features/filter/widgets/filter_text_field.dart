/// A `GlassVariant.flatForm` text input — the theme's prescribed material
/// for an actual form field (`glass_surface.dart`'s own doc comment: "a
/// lens that bends its own label is the wrong material for one"). Used
/// for City/District (free text — see `filter_options.dart`'s doc comment
/// for why), Min/Max total area, and Storey.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class FilterTextField extends StatelessWidget {
  const FilterTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onChanged,
    this.suffixText,
    this.enabled = true,
    this.keyboardType,
  });

  /// Owned by the caller (`FilterSheet`'s `State`), not created here — a
  /// controller recreated on every rebuild would drop cursor
  /// position/focus on every keystroke, since this widget rebuilds on
  /// every field edit (the sheet recomputes its draft `AdFilters` and
  /// calls `setState` on each change to drive the live count preview).
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final String? suffixText;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GlassSurface(
        variant: GlassVariant.flatForm,
        borderRadius: BorderRadius.circular(AppRadii.control),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 4,
        ),
        child: TextField(
          enabled: enabled,
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: type.body.copyWith(color: colors.ink),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: placeholder,
            hintStyle: type.body.copyWith(color: colors.faint),
            suffixText: suffixText,
            suffixStyle: type.bodySmall.copyWith(color: colors.muted),
          ),
        ),
      ),
    );
  }
}
