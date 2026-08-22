/// Step 1 "Basics" (§26) — Title, City, District, Address, Reference. Every
/// field required, exact error strings quoted from §26. Shared verbatim by
/// `create-listing` (as its own step) and `edit-listing` (as the top of its
/// single scroll).
///
/// **City/District (finding M6)** are a cascading Region → District picker,
/// not free text — §26 says "select" for both, and a fabricated District
/// string used to pass validation just because it was non-empty. Sourced
/// from the *same* `regionsDataProvider`
/// (`features/filter/state/regions_repository_provider.dart`) `filter-
/// sheet`'s own City/District picker already uses, rather than standing up
/// a second fetch of the same `GET /regions` vocabulary — that provider is
/// a plain (non-`autoDispose`) app-lifetime cache already, so a
/// `create-listing`/`edit-listing` session opened after `filter-sheet` has
/// ever loaded it doesn't even re-fetch. Rendered with
/// `shared/widgets/glass_option_picker.dart`'s `GlassPickerField` — the
/// promoted, required-field-capable sibling of `filter_city_district
/// _section.dart`'s own tap-to-pick styling (see that file's own doc
/// comment for why it isn't reused directly: this feature owns nothing
/// under `features/filter/`).
///
/// **A seeded ad's City/District may not match the picker vocabulary
/// exactly** (`edit-listing`'s prefill — the OLX-imported seed ads carry
/// values like "Toshkent" / "Mirzo-Ulug'bek tumani" that predate this
/// picker's taxonomy). Two deliberate calls, not oversights:
///  - The field's displayed **value never requires membership in the
///    option list** — `GlassPickerField.value` is shown verbatim whether or
///    not it matches an option (same as `_OptionRow`'s own `selected`
///    check, which simply doesn't highlight anything if nothing matches).
///    A picker that silently blanked an unmatched existing value on first
///    render would corrupt that field the moment the user hit Save without
///    ever touching it.
///  - District's option list falls back to the **full unscoped district
///    list** (every district, every region) when City has text that
///    doesn't match any known region, rather than disabling the field
///    outright. City not matching means the cascade has nothing to scope
///    District *by*, but District is still a required field the user must
///    get through Save/Next with — better to let them pick a real district
///    from the whole vocabulary than to lock a required field with no way
///    to satisfy it short of also fixing City first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/glass_option_picker.dart';
import '../../../../theme/theme.dart';
import '../../../filter/state/regions_repository_provider.dart';
import 'listing_form_fields.dart';
import 'listing_text_field.dart';

class BasicsStep extends ConsumerWidget {
  const BasicsStep({super.key, required this.fields, required this.onChanged});

  final ListingFormFields fields;
  final VoidCallback onChanged;

  /// Re-runs validation for whichever Basics fields already have a visible
  /// error, then notifies the caller — finding P1. A field the user hasn't
  /// reached Next/Submit with yet stays silent (its error string is still
  /// `null`, so [ListingFormFields.revalidateTouchedBasics] is a no-op for
  /// it), but once a field HAS shown its "{Field} is required" text, fixing
  /// it clears that text on the very keystroke/pick that fixes it, rather
  /// than leaving it stuck until the next full Next/Submit pass. Wraps
  /// [onChanged] (not a replacement for it) — the parent screen's own
  /// `_touched`/discard-confirmation bookkeeping is unaffected.
  ///
  /// Takes [l10n] directly rather than a [BuildContext] — every call site
  /// in [build] that reaches this is inside an `onTap`'s `async` closure,
  /// called *after* an `await showGlassOptionPicker(...)`; resolving
  /// `AppLocalizations.of(context)` there would be a `BuildContext` used
  /// across an async gap (this widget has no `State`/`mounted` to guard
  /// it with, being a [ConsumerWidget]). [build] already resolves `l10n`
  /// once, synchronously, before any of those closures are created, so
  /// each just closes over that value instead.
  void _handleChanged(AppLocalizations l10n) {
    fields.revalidateTouchedBasics(l10n);
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final regionsAsync = ref.watch(regionsDataProvider);

    final Widget cityField = regionsAsync.when(
      loading: () => GlassPickerField(
        key: const ValueKey('listingField-city'),
        label: l10n.listingEditorCityFieldLabel,
        value: null,
        placeholder: l10n.filterRegionsLoadingPlaceholder,
        errorText: fields.cityError,
        enabled: false,
      ),
      error: (error, stackTrace) => GlassPickerField(
        key: const ValueKey('listingField-city'),
        label: l10n.listingEditorCityFieldLabel,
        value: null,
        placeholder: l10n.filterRegionsErrorPlaceholder,
        errorText: fields.cityError,
        enabled: false,
        onRetry: () => ref.invalidate(regionsDataProvider),
      ),
      data: (regions) {
        final currentCity = fields.city.text.trim().isEmpty
            ? null
            : fields.city.text;
        return GlassPickerField(
          key: const ValueKey('listingField-city'),
          label: l10n.listingEditorCityFieldLabel,
          value: currentCity,
          placeholder: '',
          errorText: fields.cityError,
          onTap: () async {
            final selected = await showGlassOptionPicker(
              context,
              title: l10n.filterCityPickerTitle,
              options: regions.regions.map((r) => r.name).toList(),
              current: currentCity,
            );
            if (selected == currentCity) return;
            fields.city.text = selected!;
            // A new City almost certainly invalidates whichever
            // District was picked under the old one — District is
            // *scoped* to City (§26's cascade), not just gated on it
            // being non-empty, so carrying a stale District across a
            // City change would silently mismatch the two on submit.
            fields.district.text = '';
            _handleChanged(l10n);
          },
        );
      },
    );

    final Widget districtField = regionsAsync.when(
      loading: () => GlassPickerField(
        key: const ValueKey('listingField-district'),
        label: l10n.listingEditorDistrictFieldLabel,
        value: null,
        placeholder: l10n.filterRegionsLoadingPlaceholder,
        errorText: fields.districtError,
        enabled: false,
      ),
      error: (error, stackTrace) => GlassPickerField(
        key: const ValueKey('listingField-district'),
        label: l10n.listingEditorDistrictFieldLabel,
        value: null,
        placeholder: l10n.filterRegionsErrorPlaceholder,
        errorText: fields.districtError,
        enabled: false,
      ),
      data: (regions) {
        final currentCity = fields.city.text.trim().isEmpty
            ? null
            : fields.city.text;
        final currentDistrict = fields.district.text.trim().isEmpty
            ? null
            : fields.district.text;
        final selectedRegion = currentCity == null
            ? null
            : regions.regions.where((r) => r.name == currentCity).firstOrNull;
        final districtEnabled = currentCity != null;
        // See this file's own doc comment for why an unmatched City
        // (`selectedRegion == null` despite non-empty text) falls back
        // to the full district list rather than disabling the field.
        final districtOptions = !districtEnabled
            ? const <String>[]
            : selectedRegion != null
            ? regions.districts
                  .where((d) => d.regionId == selectedRegion.id)
                  .map((d) => d.name)
                  .toList()
            : regions.districts.map((d) => d.name).toList();

        return GlassPickerField(
          key: const ValueKey('listingField-district'),
          label: l10n.listingEditorDistrictFieldLabel,
          value: currentDistrict,
          placeholder: districtEnabled
              ? ''
              : l10n.listingEditorDistrictDisabledHint,
          errorText: fields.districtError,
          enabled: districtEnabled,
          onTap: districtEnabled
              ? () async {
                  final selected = await showGlassOptionPicker(
                    context,
                    title: l10n.filterDistrictPickerTitle,
                    options: districtOptions,
                    current: currentDistrict,
                  );
                  if (selected == currentDistrict) return;
                  fields.district.text = selected!;
                  _handleChanged(l10n);
                }
              : null,
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingTextField(
          key: const ValueKey('listingField-title'),
          label: l10n.listingEditorTitleFieldLabel,
          controller: fields.title,
          errorText: fields.titleError,
          textCapitalization: TextCapitalization.sentences,
          onChanged: () => _handleChanged(l10n),
        ),
        const SizedBox(height: AppSpacing.lg),
        // `.two{display:grid;grid-template-columns:1fr 1fr;gap:11px}` — the
        // mockup pairs City and District on one line (the same shape
        // `details_step.dart` uses for Rooms/Area). Top-aligned so one
        // field's error line doesn't drag the other's control down.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cityField),
            const SizedBox(width: kListingFieldPairGap),
            Expanded(child: districtField),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-address'),
          label: l10n.listingEditorAddressFieldLabel,
          controller: fields.address,
          errorText: fields.addressError,
          onChanged: () => _handleChanged(l10n),
        ),
        const SizedBox(height: AppSpacing.lg),
        ListingTextField(
          key: const ValueKey('listingField-reference'),
          label: l10n.listingEditorReferenceFieldLabel,
          controller: fields.reference,
          errorText: fields.referenceError,
          hintText: l10n.listingEditorReferenceHint,
          onChanged: () => _handleChanged(l10n),
        ),
      ],
    );
  }
}
