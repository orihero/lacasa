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

/// `.two{grid-template-columns:1fr 1fr;gap:11px}` — the horizontal gap
/// between two half-width fields sharing one row (City/District,
/// Rooms/Area, Storey/Floors, Price/Price type).
const double kListingFieldPairGap = 11;

/// `.inp,.selbox{height:52px}` — every single-line form control in this
/// feature is a fixed 52dp tall, so a text input and the picker beside it
/// line up exactly.
const double kListingControlHeight = 52;

/// `.ta{min-height:96px}` — multi-line inputs grow from here.
const double kListingTextAreaMinHeight = 96;

/// `.inp,.ta,.selbox{font-size:13px}` — one step up from the shared `body`
/// token (12px), which other screens rely on, so the bump lives at this
/// call site rather than in the theme.
TextStyle listingControlTextStyle(LaCasaTypography type) =>
    type.body.copyWith(fontSize: 13);

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
    final isMultiline = maxLines > 1;
    final controlStyle = listingControlTextStyle(type);

    final field = GlassSurface(
      variant: GlassVariant.flatForm,
      borderRadius: BorderRadius.circular(AppRadii.control),
      // `.inp` is a fixed 52px flex box with `padding:0 16px`; `.ta` grows
      // from a 96px minimum with `padding:15px 16px`.
      height: isMultiline ? null : kListingControlHeight,
      alignment: isMultiline ? null : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: isMultiline ? 15 : 0,
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        onChanged: (_) => onChanged?.call(),
        style: controlStyle.copyWith(color: colors.ink),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: controlStyle.copyWith(color: colors.faint),
          suffixText: suffixText,
          suffixStyle: type.bodySmall.copyWith(color: colors.muted),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        Opacity(
          opacity: enabled ? 1 : 0.5,
          child: isMultiline
              ? ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kListingTextAreaMinHeight,
                  ),
                  child: field,
                )
              : field,
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
