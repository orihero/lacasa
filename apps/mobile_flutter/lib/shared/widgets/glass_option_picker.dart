/// A tap-to-pick, single-select field + bottom sheet — the shared glass
/// styling behind `filter-sheet`'s City/District cascade
/// (`features/filter/widgets/filter_city_district_section.dart`'s
/// `_PickerField`/`showFilterOptionPicker`), promoted here so a second
/// caller (`create-listing`/`edit-listing`'s own City/District — finding
/// M6) doesn't have to either duplicate that ~150-line sheet from scratch
/// or reach into `features/filter/` for it (feature folders don't import
/// each other's widgets in this codebase).
///
/// **Not a drop-in replacement for the filter version** — filter's fields
/// are optional (every pick includes a leading "Any …" row that clears the
/// filter), while a Basics field here is *required* (§26: "City select
/// (required ...)"), so [showGlassOptionPicker]'s `anyLabel` is nullable:
/// omit it and the sheet has no "Any" row and always resolves to a real
/// option (or the caller's unchanged `current` on dismiss). [GlassPickerField]
/// also grows an [errorText] line — `ListingTextField`'s own per-field
/// error row — since a required picker can fail the same §26 validation a
/// required text field can.
///
/// `features/filter/widgets/filter_option_picker_sheet.dart`'s own
/// `showFilterOptionPicker`/`_FilterOptionPickerSheet` are NOT rewritten to
/// delegate here — that file is owned by a different concurrent change in
/// this build; consolidating the two is a follow-up once that's safe to
/// touch (see this build's own findings tracker).
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'field_label.dart';

/// Opens the picker and resolves to the caller's next value for the field:
///  - [current] again, unchanged, if the sheet was dismissed without an
///    explicit pick (swipe-down, back gesture, the close "X").
///  - `null` only if [anyLabel] was supplied and its row was tapped.
///  - the tapped option's exact string otherwise.
///
/// Mirrors `showFilterOptionPicker`'s own contract verbatim (same
/// swipe/back/"X" dismissal semantics) — see that function's doc comment.
Future<String?> showGlassOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String? current,
  String? anyLabel,
}) async {
  final result = await showModalBottomSheet<_PickedOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    // Mounts above the floating tab bar, matching `showFilterOptionPicker`'s
    // own reasoning — both `create-listing` and `edit-listing` are
    // root-navigator-hosted modals/routes, but the flag is set explicitly
    // here too rather than relying on that transitively.
    useRootNavigator: true,
    builder: (context) => _GlassOptionPickerSheet(
      title: title,
      options: options,
      current: current,
      anyLabel: anyLabel,
    ),
  );
  if (result == null) return current;
  return result.value;
}

/// Wraps the picked value so "Any was tapped" (`value: null`) is
/// distinguishable from "the sheet was dismissed with no pick at all" (the
/// whole result is `null`, never this type).
class _PickedOption {
  const _PickedOption(this.value);
  final String? value;
}

class _GlassOptionPickerSheet extends StatelessWidget {
  const _GlassOptionPickerSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.anyLabel,
  });

  final String title;
  final List<String> options;
  final String? current;
  final String? anyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final anyRowCount = anyLabel == null ? 0 : 1;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadii.sheet),
              topRight: Radius.circular(AppRadii.sheet),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: colors.line, borderRadius: AppRadii.pill),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  AppSpacing.lg,
                  AppSpacing.base,
                  AppSpacing.base,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: type.sheetTitle.copyWith(color: colors.ink)),
                    ),
                    GestureDetector(
                      key: const ValueKey('glassOptionPicker-close'),
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close_rounded, color: colors.ink2, size: 22),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                      vertical: AppSpacing.base,
                    ),
                    itemCount: options.length + anyRowCount,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (anyLabel != null && index == 0) {
                        return _OptionRow(
                          key: const ValueKey('glassOption-any'),
                          label: anyLabel!,
                          selected: current == null,
                          onTap: () => Navigator.of(context).pop(const _PickedOption(null)),
                        );
                      }
                      final option = options[index - anyRowCount];
                      return _OptionRow(
                        key: ValueKey('glassOption-$option'),
                        label: option,
                        selected: option == current,
                        onTap: () => Navigator.of(context).pop(_PickedOption(option)),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassSurface(
        variant: GlassVariant.flatForm,
        borderRadius: BorderRadius.circular(AppRadii.card),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: type.rowTitle.copyWith(color: colors.ink))),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppAccent.color : colors.line, width: 1.5),
              ),
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppAccent.color),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled, tappable `GlassVariant.flatForm` field that opens
/// [showGlassOptionPicker] — the picker counterpart to
/// `features/listing_editor/widgets/form/listing_text_field.dart`'s
/// `ListingTextField` (same label/box/error-line shape, a chevron
/// replacing the text cursor as the "this opens something" affordance,
/// matching `filter_city_district_section.dart`'s own `_PickerField`).
///
/// [onRetry], when set, replaces [onTap] as the field's tap handler and
/// swaps the trailing chevron for a refresh icon — the "regions fetch
/// failed" state both this and the filter picker need (§ `filter-sheet`'s
/// own inline retry row for a failed live-count/vocabulary fetch).
class GlassPickerField extends StatelessWidget {
  const GlassPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    this.required = false,
    this.enabled = true,
    this.errorText,
    this.onTap,
    this.onRetry,
  });

  final String label;
  final String? value;
  final String placeholder;
  final bool required;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

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
          child: GestureDetector(
            // Matches `filter_city_district_section.dart`'s own
            // `_PickerField`: [onRetry] fires precisely when [enabled] is
            // `false` (the "regions fetch failed" state, where this field
            // is dimmed but still tappable-to-retry), never alongside a
            // real [onTap].
            onTap: enabled ? onTap : onRetry,
            child: GlassSurface(
              variant: GlassVariant.flatForm,
              borderRadius: BorderRadius.circular(AppRadii.control),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      overflow: TextOverflow.ellipsis,
                      style: type.body.copyWith(color: value == null ? colors.faint : colors.ink),
                    ),
                  ),
                  Icon(
                    onRetry != null ? Icons.refresh_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: colors.muted,
                  ),
                ],
              ),
            ),
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
