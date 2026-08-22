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
    // Mounts above the floating tab bar — see tab_shell_scaffold.dart's doc
    // comment. Without this, the third radio row ("Ru") never renders above
    // the bar at all, since the sheet is clipped underneath it.
    useRootNavigator: true,
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
      // `.sh{position:absolute;left:8px;right:8px;bottom:8px}` — the panel
      // floats clear of the screen edges rather than sitting flush against
      // them, which is what lets all four of its corners round.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(AppRadii.sheet),
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
                  _CloseButton(
                    label: l10n.languageSheetCloseLabel,
                    onTap: () => Navigator.of(context).pop(),
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

/// `.sh__h .rnd` — the sheet header's close control: a 34px round `--sunk`
/// chip, not a bare glyph. Sized inside a 44px box so the tap target clears
/// the platform minimum even though the chip itself is smaller.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.sunk,
              ),
              child: Icon(Icons.close_rounded, size: 16, color: colors.ink),
            ),
          ),
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
              // `.lrow__sp` — the abbreviation SCREENS.md §3.20 quotes as
              // the row's title, with the language's own name for itself
              // underneath (the mockup's `.lrow__s` second line).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language.label,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.nativeName,
                      style: type.bodySmall.copyWith(color: colors.muted),
                    ),
                  ],
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

    // `inset 0 0 0 7px var(--accent)` is a single 7px-thick accent ring on
    // the 22px circle — one solid donut with an 8px hole, not a thin outline
    // with a separate dot floating inside it.
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: AppAccent.color, width: 7)
            : Border.all(color: colors.line, width: 1.5),
      ),
    );
  }
}
