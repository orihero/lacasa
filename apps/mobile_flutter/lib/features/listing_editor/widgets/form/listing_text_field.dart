/// A labelled `GlassVariant.flatForm` text input with an optional per-field
/// error line — the form-field primitive every Basics/Details row in
/// `create-listing`/`edit-listing` reduces to. Shape matches
/// `shared/widgets/labelled_form_field.dart`'s `LabelledFormField` (label +
/// error line) crossed with `features/filter/widgets/filter_text_field
/// .dart`'s glass styling; kept as its own widget rather than folded into
/// `LabelledFormField` — see that file's doc comment for the load-bearing
/// differences (required-asterisk label via [FieldLabel], `suffixText`, the
/// compact single-line padding this feature's denser forms need).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';

class ListingTextField extends StatelessWidget {
  const ListingTextField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.hintText,
    this.suffixText,
    this.required = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hintText;
  final String? suffixText;
  final bool required;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        Opacity(
          opacity: enabled ? 1 : 0.5,
          child: GlassSurface(
            variant: GlassVariant.flatForm,
            borderRadius: BorderRadius.circular(AppRadii.control),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: maxLines > 1 ? AppSpacing.base : 4,
            ),
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              maxLines: maxLines,
              textCapitalization: textCapitalization,
              onChanged: (_) => onChanged?.call(),
              style: type.body.copyWith(color: colors.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: type.body.copyWith(color: colors.faint),
                suffixText: suffixText,
                suffixStyle: type.bodySmall.copyWith(color: colors.muted),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppStatusColors.errorText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  errorText!,
                  style: type.bodySmall.copyWith(
                    color: AppStatusColors.errorText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
