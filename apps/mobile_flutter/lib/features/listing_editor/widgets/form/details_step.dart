/// Step 2 "Details" (§26) — every field the spec lists except Hashtags,
/// which `edit-listing` omits (§27: "no Hashtags field") and
/// `create-listing` includes via [showHashtags]. Only Description is
/// required; every other field here has a stated or first-listed-option
/// default (see `listing_form_fields.dart`'s own doc comment) and is
/// otherwise free-form.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../api/api.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'additional_info_field.dart';
import 'listing_form_fields.dart';
import 'listing_text_field.dart';
import 'nearby_places_field.dart';

const List<ChoiceOption<AdType>> _typeOptions = [
  ChoiceOption(AdType.residential, 'Residential'),
  ChoiceOption(AdType.nonresidential, 'Nonresidential'),
];

const List<ChoiceOption<AdCategory>> _categoryOptions = [
  ChoiceOption(AdCategory.rent, 'Rent'),
  ChoiceOption(AdCategory.sale, 'Sale'),
];

const List<ChoiceOption<Repairment>> _repairOptions = [
  ChoiceOption(Repairment.notRepaired, 'Not repaired'),
  ChoiceOption(Repairment.normal, 'Normal'),
  ChoiceOption(Repairment.good, 'Good'),
  ChoiceOption(Repairment.excellent, 'Excellent'),
];

const List<ChoiceOption<Furniture>> _furnitureOptions = [
  ChoiceOption(Furniture.withFurniture, 'With furniture'),
  ChoiceOption(Furniture.withoutFurniture, 'Without Furniture'),
];

const List<ChoiceOption<CurrencyCode>> _priceTypeOptions = [
  ChoiceOption(CurrencyCode.uzs, "so'm"),
  ChoiceOption(CurrencyCode.usd, 'y.e'),
];

const List<ChoiceOption<AdStage>> _stageOptions = [
  ChoiceOption(AdStage.active, 'Active'),
  ChoiceOption(AdStage.sold, 'Sold'),
  ChoiceOption(AdStage.draft, 'Draft'),
];

class DetailsStep extends StatelessWidget {
  const DetailsStep({
    super.key,
    required this.fields,
    required this.onChanged,
    this.showHashtags = true,
  });

  final ListingFormFields fields;
  final VoidCallback onChanged;
  final bool showHashtags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceChipGroup<AdType>(
          label: 'Type',
          keyPrefix: 'listingType',
          options: _typeOptions,
          selected: fields.type,
          allowDeselect: false,
          onChanged: (v) {
            fields.type = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<AdCategory>(
          label: 'Category',
          keyPrefix: 'listingCategory',
          options: _categoryOptions,
          selected: fields.category,
          allowDeselect: false,
          onChanged: (v) {
            fields.category = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<Repairment>(
          label: 'Repair',
          keyPrefix: 'listingRepair',
          options: _repairOptions,
          selected: fields.repairment,
          allowDeselect: false,
          onChanged: (v) {
            fields.repairment = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ListingTextField(
                key: const ValueKey('listingField-rooms'),
                label: 'Rooms',
                controller: fields.rooms,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: ListingTextField(
                key: const ValueKey('listingField-area'),
                label: 'Area',
                controller: fields.area,
                suffixText: 'm²',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ListingTextField(
                key: const ValueKey('listingField-storey'),
                label: 'Storey',
                controller: fields.storey,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: ListingTextField(
                key: const ValueKey('listingField-floors'),
                label: 'Floors',
                controller: fields.floors,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<Furniture>(
          label: 'Furniture',
          keyPrefix: 'listingFurniture',
          options: _furnitureOptions,
          selected: fields.furniture,
          allowDeselect: false,
          onChanged: (v) {
            fields.furniture = v!;
            onChanged();
          },
        ),
        if (showHashtags) ...[
          const SizedBox(height: AppSpacing.lg),
          ListingTextField(
            key: const ValueKey('listingField-hashtags'),
            label: 'Hashtags',
            controller: fields.hashtags,
            hintText: '#new #2024',
            onChanged: onChanged,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-price'),
          label: 'Price',
          controller: fields.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
        _PricePreview(fields: fields),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<CurrencyCode>(
          label: 'Price type',
          keyPrefix: 'listingPriceType',
          options: _priceTypeOptions,
          selected: fields.priceType,
          allowDeselect: false,
          onChanged: (v) {
            fields.priceType = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<AdStage>(
          label: 'Status',
          keyPrefix: 'listingStatus',
          options: _stageOptions,
          selected: fields.stage,
          allowDeselect: false,
          onChanged: (v) {
            fields.stage = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        NearbyPlacesField(
          places: fields.nearPlaces,
          onChanged: (v) {
            fields.nearPlaces = v;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AdditionalInfoField(rows: fields.additionalInfo, onChanged: onChanged),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-description'),
          label: 'Description',
          required: true,
          controller: fields.description,
          errorText: fields.descriptionError,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// "Price (number) with live currency preview" (§26) — a small read-only
/// line under the Price field showing the grouped-thousands figure plus
/// the selected currency's suffix, e.g. "78,000 so'm" / "350 y.e", updating
/// on every keystroke/currency-chip tap.
class _PricePreview extends StatelessWidget {
  const _PricePreview({required this.fields});

  final ListingFormFields fields;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final value = double.tryParse(fields.price.text.trim());

    if (value == null) {
      return Text(
        'Enter a price to see a preview.',
        style: type.bodySmall.copyWith(color: colors.faint),
      );
    }

    final suffix = fields.priceType == CurrencyCode.uzs ? "so'm" : 'y.e';
    return Text(
      '${Formatters.groupedNumber(value)} $suffix',
      style: LaCasaTypography.tabular(type.bodySmall).copyWith(color: colors.ink2),
    );
  }
}
