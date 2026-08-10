/// A labelled `.glf` flat-glass text input with an optional per-field
/// [errorText] line and an optional [trailing] adornment (the password
/// show/hide toggle, chiefly). Promoted out of three byte-identical
/// private `_FormField`s (`add_coworker_screen.dart`,
/// `coworker_detail_screen.dart`, `edit_profile_screen.dart`) — the
/// coworker pair was a verbatim copy-paste of each other, and
/// `edit_profile_screen.dart`'s own copy (which both of them cite as
/// precedent in their doc comments, without reusing it) turned out to be
/// the exact same widget a third time.
///
/// **Deliberately not merged further**, into a single field widget that
/// also serves every other labelled-field shape in this app:
///  - `features/listing_editor/widgets/form/listing_text_field.dart`'s
///    `ListingTextField` carries a required-field asterisk
///    ([FieldLabel]'s `required` flag), a `suffixText` (e.g. "m²"), and a
///    padding rule that tightens for single-line rows
///    (`maxLines > 1 ? base : 4`) — `create-listing`/`edit-listing` packs
///    far more fields onto one screen than any form this widget serves,
///    and that denser rhythm is a real, load-bearing visual difference,
///    not an oversight.
///  - `features/leads/widgets/lead_form_controls.dart`'s `LeadTextField`
///    is closer in shape (fixed padding, no suffix/required marker) but
///    still its own widget — see that file's doc comment.
///  - `features/auth/widgets/auth_form_widgets.dart`'s `AuthField` was
///    already, deliberately, kept separate from this widget's ancestor
///    (`edit_profile_screen.dart`'s `_FormField`) before this
///    consolidation pass — see that file's doc comment: nullable
///    `onChanged`, an `onSubmitted` hook, a `helperText` mode, and a
///    56px/full-width submit button its sibling `AuthPrimaryButton` uses
///    that this shape's 52px buttons don't. Those differences are exactly
///    as real today as they were when that split was first made, so this
///    pass leaves it standing rather than re-litigating a settled call.
///
/// Three call sites converging on one, truly identical widget is a clean
/// merge; folding in the other two would mean this widget growing a pile
/// of flags (`required`, `suffixText`, `compactPadding`, `helperText`,
/// `onSubmitted`, a second button-height knob…) to paper over forms that
/// were never actually the same shape — worse than a few honest, smaller
/// widgets each named for the one thing they render.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

class LabelledFormField extends StatelessWidget {
  const LabelledFormField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.inputFormatters,
    this.trailing,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: type.label.copyWith(color: colors.muted)),
        const SizedBox(height: AppSpacing.sm),
        GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  inputFormatters: inputFormatters,
                  onChanged: (_) => onChanged(),
                  style: type.body.copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: type.body.copyWith(color: colors.faint),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, size: 14, color: AppStatusColors.errorText),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  errorText!,
                  style: type.bodySmall.copyWith(color: AppStatusColors.errorText),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
