/// A small single-select bottom sheet list — backs both halves of
/// [FilterCityDistrictSection]'s Region → District cascade. Visual language
/// mirrors `features/language/widgets/language_sheet.dart`'s radio rows
/// (flat-glass row, filled circle for the selected option) since both are
/// "pick exactly one from a short list" sheets; unlike that one, this sheet
/// is opened from *inside* another bottom sheet (`filter-sheet` itself), so
/// it always includes a leading "Any …" row (there is no separate "clear"
/// affordance once you're this deep in a nested sheet) and an explicit
/// close "X" (swipe-to-dismiss still works too, matching `filter-sheet`'s
/// own convention).
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Opens the picker and resolves to the caller's next value for the field:
///  - [current] again, unchanged, if the sheet was dismissed without an
///    explicit pick (swipe-down, back gesture, tapping the close "X") —
///    the caller doesn't need to special-case "nothing happened" itself,
///    just always pass this call's result to its `onChanged` callback.
///  - `null` if "Any …" was tapped (clears the field).
///  - the tapped option's exact string otherwise.
Future<String?> showFilterOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String? current,
  required String anyLabel,
}) async {
  final result = await showModalBottomSheet<_PickedOption>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => _FilterOptionPickerSheet(
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
/// whole result is `null`, never this type) — two states a bare
/// `Future<String?>` from `showModalBottomSheet` itself couldn't tell apart.
class _PickedOption {
  const _PickedOption(this.value);
  final String? value;
}

class _FilterOptionPickerSheet extends StatelessWidget {
  const _FilterOptionPickerSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.anyLabel,
  });

  final String title;
  final List<String> options;
  final String? current;
  final String anyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: AppRadii.pill,
                ),
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
                      child: Text(
                        title,
                        style: type.sheetTitle.copyWith(color: colors.ink),
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('filterOptionPicker-close'),
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.ink2,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                      vertical: AppSpacing.base,
                    ),
                    itemCount: options.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _OptionRow(
                          key: const ValueKey('filterOption-any'),
                          label: anyLabel,
                          selected: current == null,
                          onTap: () =>
                              Navigator.of(context).pop(const _PickedOption(null)),
                        );
                      }
                      final option = options[index - 1];
                      return _OptionRow(
                        key: ValueKey('filterOption-$option'),
                        label: option,
                        selected: option == current,
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_PickedOption(option)),
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
  const _OptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
            Expanded(
              child: Text(label, style: type.rowTitle.copyWith(color: colors.ink)),
            ),
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppAccent.color : colors.line,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppAccent.color,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
