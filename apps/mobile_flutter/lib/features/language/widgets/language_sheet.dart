/// `language-sheet` (SCREENS.md §3.20) — "Language", a bottom sheet, not a
/// route. SCREENS.md §1 buckets it under "Bottom sheet (swipe-to-dismiss,
/// partial height)", same as `filter-sheet` and `contact-sheet`, so the
/// entry point is [showLanguageSheet] rather than anything in
/// `app_router.dart`. Reached from `profile-signed-out`, `profile-buyer`,
/// `profile-agent` and `settings` (§3.17/3.18/3.19/3.19 — none of those four
/// screens are built by this task; whoever builds them wires their
/// **"Language"** row to `showLanguageSheet(context)`).
///
/// The spec's entire text for this screen: 'Sheet title "Language". Radio
/// options: "En" / "Uz" / "Ru". Selecting applies immediately and closes.'
/// That is exactly what this file does and nothing more — no Apply button,
/// no confirmation step. Row order and radio labels ("En"/"Uz"/"Ru", not
/// "English"/"Uzbek"/"Russian") are quoted character for character.
///
/// **Selecting a row now does exactly what SCREENS.md says: applies
/// immediately.** `app.dart` watches [languageProvider] and drives
/// `MaterialApp.locale` from it, so [LanguageNotifier.select]'s synchronous
/// state update (see that method's doc comment) is visible the same frame
/// the sheet closes, no restart required — the honest "nothing else moves
/// yet" disclaimer this file used to print under the radio options
/// (`_LocalisationNote`, see git history) is gone because it is no longer
/// true for any string that has been through `flutter gen-l10n` (see
/// `lib/l10n/README.md`). A screen whose strings have not been extracted
/// yet simply keeps rendering its hardcoded English, same as any other
/// not-yet-migrated screen — no per-screen flag needed for that.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../data/app_language.dart';
import '../state/language_provider.dart';

/// Opens the sheet. Resolves when it closes; callers don't need the result
/// because every screen that opens this reads the current language back out
/// of [languageProvider] itself rather than out of this call's return value.
Future<void> showLanguageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);
    final languageAsync = ref.watch(languageProvider);
    // While the storage read is in flight, or if it fails, the selected row
    // reads as English — the same default `SecureLanguageRepository.load`
    // itself falls back to, so there is no visible flash to a different row
    // once the read resolves.
    final selected = languageAsync.value ?? AppLanguage.en;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.base,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabHandle(colors),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.languageSheetTitle,
                    style: type.sheetTitle.copyWith(color: colors.ink),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.languageSheetCloseLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colors.ink2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            for (final language in AppLanguage.values) ...[
              _LanguageRow(
                language: language,
                selected: language == selected,
                // The notifier itself no-ops nothing special for a re-tap
                // of the already-selected row — it just re-saves the same
                // value, which is harmless and keeps this row identical to
                // its siblings rather than special-cased.
                onTap: () async {
                  await ref.read(languageProvider.notifier).select(language);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
              if (language != AppLanguage.values.last)
                const SizedBox(height: AppSpacing.base),
            ],
          ],
        ),
      ),
    );
  }

  Widget _grabHandle(LaCasaColors colors) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.line,
          borderRadius: AppRadii.pill,
        ),
      ),
    );
  }
}

/// One `.lrow glf` radio row — the mockup's exact material (flat glass, see
/// `mockup-e-liquid-glass.html`'s `language-sheet` section) and corner
/// radius ([AppRadii.card], the token documented for `.lrow`).
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      selected: selected,
      label: language.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.card),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.label,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
              ),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.radio` / `.radio.on` — an outlined circle that fills with the accent
/// color when selected, per the mockup's `box-shadow: inset 0 0 0 7px
/// var(--accent)` treatment on a 22px circle.
class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Container(
      width: 22,
      height: 22,
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
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppAccent.color,
              ),
            )
          : null,
    );
  }
}
