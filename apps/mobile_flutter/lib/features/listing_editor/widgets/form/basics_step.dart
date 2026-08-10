/// Step 1 "Basics" (§26) — Title, City, District, Address, Reference. Every
/// field required, exact error strings quoted from §26. Shared verbatim by
/// `create-listing` (as its own step) and `edit-listing` (as the top of its
/// single scroll).
library;

import 'package:flutter/material.dart';

import '../../../../theme/theme.dart';
import 'listing_form_fields.dart';
import 'listing_text_field.dart';

class BasicsStep extends StatelessWidget {
  const BasicsStep({super.key, required this.fields, required this.onChanged});

  final ListingFormFields fields;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingTextField(
          key: const ValueKey('listingField-title'),
          label: 'Title',
          required: true,
          controller: fields.title,
          errorText: fields.titleError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-city'),
          label: 'City',
          required: true,
          controller: fields.city,
          errorText: fields.cityError,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-district'),
          label: 'District',
          required: true,
          controller: fields.district,
          errorText: fields.districtError,
          enabled: fields.city.text.trim().isNotEmpty,
          hintText: fields.city.text.trim().isEmpty ? 'Pick a city first' : null,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-address'),
          label: 'Address',
          required: true,
          controller: fields.address,
          errorText: fields.addressError,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-reference'),
          label: 'Reference',
          required: true,
          controller: fields.reference,
          errorText: fields.referenceError,
          hintText: 'Orientation / landmark',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
