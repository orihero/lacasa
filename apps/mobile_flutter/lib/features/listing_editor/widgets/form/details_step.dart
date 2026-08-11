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
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'additional_info_field.dart';
import 'listing_form_fields.dart';
import 'listing_text_field.dart';
import 'nearby_places_field.dart';

// Every option list below used to be a top-level `const` — a localized
// label means the list can no longer be built at compile time, so each is
// now a plain function of [AppLocalizations], called once per `build()`
// rather than hoisted back to a module-level constant (`ChoiceOption`
// itself stays a `const`-constructible class; only these lists' constant-
// ness is what the localized label removes).
List<ChoiceOption<AdType>> _typeOptions(AppLocalizations l10n) => [
  ChoiceOption(AdType.residential, l10n.listingEditorTypeResidentialOption),
  ChoiceOption(
    AdType.nonresidential,
    l10n.listingEditorTypeNonresidentialOption,
  ),
];

List<ChoiceOption<AdCategory>> _categoryOptions(AppLocalizations l10n) => [
  ChoiceOption(AdCategory.rent, l10n.listingEditorCategoryRentOption),
  ChoiceOption(AdCategory.sale, l10n.listingEditorCategorySaleOption),
];

List<ChoiceOption<Repairment>> _repairOptions(AppLocalizations l10n) => [
  ChoiceOption(
    Repairment.notRepaired,
    l10n.listingEditorRepairNotRepairedOption,
  ),
  ChoiceOption(Repairment.normal, l10n.listingEditorRepairNormalOption),
  ChoiceOption(Repairment.good, l10n.listingEditorRepairGoodOption),
  ChoiceOption(Repairment.excellent, l10n.listingEditorRepairExcellentOption),
];

List<ChoiceOption<Furniture>> _furnitureOptions(AppLocalizations l10n) => [
  ChoiceOption(
    Furniture.withFurniture,
    l10n.listingEditorFurnitureWithOption,
  ),
  ChoiceOption(
    Furniture.withoutFurniture,
    l10n.listingEditorFurnitureWithoutOption,
  ),
];

List<ChoiceOption<CurrencyCode>> _priceTypeOptions(AppLocalizations l10n) => [
  ChoiceOption(CurrencyCode.uzs, l10n.listingEditorPriceTypeUzsOption),
  ChoiceOption(CurrencyCode.usd, l10n.listingEditorPriceTypeUsdOption),
];

List<ChoiceOption<AdStage>> _stageOptions(AppLocalizations l10n) => [
  ChoiceOption(AdStage.active, l10n.listingEditorStageActiveOption),
  ChoiceOption(AdStage.sold, l10n.listingEditorStageSoldOption),
  ChoiceOption(AdStage.draft, l10n.listingEditorStageDraftOption),
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceChipGroup<AdType>(
          label: l10n.listingEditorTypeFieldLabel,
          keyPrefix: 'listingType',
          options: _typeOptions(l10n),
          selected: fields.type,
          allowDeselect: false,
          onChanged: (v) {
            fields.type = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<AdCategory>(
          label: l10n.listingEditorCategoryFieldLabel,
          keyPrefix: 'listingCategory',
          options: _categoryOptions(l10n),
          selected: fields.category,
          allowDeselect: false,
          onChanged: (v) {
            fields.category = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<Repairment>(
          label: l10n.listingEditorRepairFieldLabel,
          keyPrefix: 'listingRepair',
          options: _repairOptions(l10n),
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
                label: l10n.listingEditorRoomsFieldLabel,
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
                label: l10n.listingEditorAreaFieldLabel,
                controller: fields.area,
                suffixText: l10n.listingEditorAreaUnitSuffix,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
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
                label: l10n.listingEditorStoreyFieldLabel,
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
                label: l10n.listingEditorFloorsFieldLabel,
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
          label: l10n.listingEditorFurnitureFieldLabel,
          keyPrefix: 'listingFurniture',
          options: _furnitureOptions(l10n),
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
            label: l10n.listingEditorHashtagsFieldLabel,
            controller: fields.hashtags,
            hintText: l10n.listingEditorHashtagsHint,
            onChanged: onChanged,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-price'),
          label: l10n.listingEditorPriceFieldLabel,
          controller: fields.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 6),
        _PricePreview(fields: fields),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<CurrencyCode>(
          label: l10n.listingEditorPriceTypeFieldLabel,
          keyPrefix: 'listingPriceType',
          options: _priceTypeOptions(l10n),
          selected: fields.priceType,
          allowDeselect: false,
          onChanged: (v) {
            fields.priceType = v!;
            onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        ChoiceChipGroup<AdStage>(
          label: l10n.listingEditorStatusFieldLabel,
          keyPrefix: 'listingStatus',
          options: _stageOptions(l10n),
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
          label: l10n.listingEditorDescriptionFieldLabel,
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
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final value = double.tryParse(fields.price.text.trim());

    if (value == null) {
      return Text(
        l10n.listingEditorPricePreviewPlaceholder,
        style: type.bodySmall.copyWith(color: colors.faint),
      );
    }

    final suffix = fields.priceType == CurrencyCode.uzs
        ? l10n.listingEditorPriceTypeUzsOption
        : l10n.listingEditorPriceTypeUsdOption;
    return Text(
      l10n.listingEditorPricePreviewText(
        Formatters.groupedNumber(value),
        suffix,
      ),
      style: LaCasaTypography.tabular(
        type.bodySmall,
      ).copyWith(color: colors.ink2),
    );
  }
}
