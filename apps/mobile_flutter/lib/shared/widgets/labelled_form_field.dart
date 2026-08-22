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

/// `.inp{font-size:13px}` — the value and placeholder step for form inputs,
/// one notch above [LaCasaTypography.body] (12px, which is running prose).
/// No token sits at 13px, so it is stated once here and shared by the input
/// and its hint. `features/auth/widgets/auth_form_widgets.dart` states the
/// same rule for `AuthField`; the two field widgets stay separate (see this
/// library's doc comment) but the mockup gives them one `.inp` rule, so the
/// number must not drift between them.
TextStyle _inputStyle(LaCasaTypography type) =>
    type.body.copyWith(fontSize: 13);

class LabelledFormField extends StatelessWidget {
  const LabelledFormField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.helperText,
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

  /// The static `.hint` line under the box — a rule the user needs before
  /// submitting, not after (edit-profile's "At least 6 characters. Only
  /// needed if you are changing it."). Suppressed while [errorText] is
  /// set: the mockup never stacks `.hint` under `.err`, and the error is
  /// the more urgent of the two.
  final String? helperText;

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
        Text(
          label.toUpperCase(),
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassSurface(
          variant: GlassVariant.flatForm,
          // `.inp{height:52px;padding:0 16px;border-radius:18px}` — a stated
          // height, not one derived from the text's own line box, so the
          // field renders the same size here as it does in `login`/`register`
          // (a user moves straight between those and `edit-profile`).
          height: 52,
          borderRadius: BorderRadius.circular(AppRadii.control),
          // `.pw .eye{position:absolute;right:6px;…;width:40px;height:40px}`
          // — the mockup overlays the eye on the input, so its 40px box sits
          // 6px from the field's edge. Laid out in-row here, so the trailing
          // edge drops to 6px whenever a [trailing] control is present and
          // keeps `.inp`'s own 16px otherwise.
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: trailing == null ? AppSpacing.lg : 6,
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
                  style: _inputStyle(type).copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: _inputStyle(type).copyWith(color: colors.faint),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (!hasError && helperText != null)
          // `.hint{margin-top:6px;padding-left:3px;font-size:10.5px;
          // line-height:1.5;color:var(--faint)}`.
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 3),
            child: Text(
              helperText!,
              style: type.bodySmall.copyWith(color: colors.faint),
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
