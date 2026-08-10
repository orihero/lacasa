/// The uppercase eyebrow label above a form field or chip group. Promoted
/// out of two independent copies: `features/filter/widgets/
/// filter_field_label.dart`'s `FilterFieldLabel` (plain text, every field
/// here is optional so nothing is ever marked required) and
/// `features/listing_editor/widgets/form/listing_field_label.dart`'s
/// `ListingFieldLabel`, which is the exact same widget plus an asterisk
/// marker for the one required field (`Ad.description`) `create-listing`/
/// `edit-listing` has. `required: false` (the default) renders identically
/// to the old `FilterFieldLabel` — this is a strict superset, not a
/// behavior change for either caller.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;

  /// Appends a small asterisk-style marker so a required field reads as
  /// such even before a user triggers validation by tapping Next/Save.
  final bool required;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      // `Text.rich`, not a bare `RichText` (the original `ListingFieldLabel`
      // used the latter): `find.text(...)` only matches `Text`/`Text.rich`
      // by default, and `FilterFieldLabel`'s existing widget tests
      // (`find.text('SORT')` etc.) rely on that — see `filter_sheet_crm_test
      // .dart`.
      child: Text.rich(
        TextSpan(
          text: text.toUpperCase(),
          style: type.label.copyWith(color: colors.muted),
          children: required
              ? [
                  TextSpan(
                    text: ' *',
                    style: type.label.copyWith(color: AppStatusColors.errorText),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
