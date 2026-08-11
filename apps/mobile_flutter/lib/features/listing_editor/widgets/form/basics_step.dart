/// Step 1 "Basics" (§26) — Title, City, District, Address, Reference. Every
/// field required, exact error strings quoted from §26. Shared verbatim by
/// `create-listing` (as its own step) and `edit-listing` (as the top of its
/// single scroll).
library;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/theme.dart';
import 'listing_form_fields.dart';
import 'listing_text_field.dart';

class BasicsStep extends StatelessWidget {
  const BasicsStep({super.key, required this.fields, required this.onChanged});

  final ListingFormFields fields;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingTextField(
          key: const ValueKey('listingField-title'),
          label: l10n.listingEditorTitleFieldLabel,
          required: true,
          controller: fields.title,
          errorText: fields.titleError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-city'),
          label: l10n.listingEditorCityFieldLabel,
          required: true,
          controller: fields.city,
          errorText: fields.cityError,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-district'),
          label: l10n.listingEditorDistrictFieldLabel,
          required: true,
          controller: fields.district,
          errorText: fields.districtError,
          enabled: fields.city.text.trim().isNotEmpty,
          hintText: fields.city.text.trim().isEmpty
              ? l10n.listingEditorDistrictDisabledHint
              : null,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-address'),
          label: l10n.listingEditorAddressFieldLabel,
          required: true,
          controller: fields.address,
          errorText: fields.addressError,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-reference'),
          label: l10n.listingEditorReferenceFieldLabel,
          required: true,
          controller: fields.reference,
          errorText: fields.referenceError,
          hintText: l10n.listingEditorReferenceHint,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
