/// The camera-vs-gallery choice every real picker control in this app
/// offers before calling `MediaPicker.pickImage`/`pickVideo`
/// (`shared/platform/media_picker.dart`) — one shared sheet so
/// `create-listing`/`edit-listing`'s photo/video tiles and every avatar
/// control (`edit-profile`, `coworker-detail`, `add-coworker`) present the
/// identical choice rather than four near-copies. Same bottom-sheet idiom
/// as `contact_sheet.dart`/`language_sheet.dart` — grab handle, title row
/// with a close "X", `GlassSurface(variant: flatForm)` rows.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../platform/media_picker.dart';

/// Opens the sheet and resolves with the row the user tapped, or `null` if
/// they dismissed it without choosing — the same "null means cancelled, not
/// an error" contract [MediaPicker] itself uses, so a caller can treat both
/// dismissals identically.
Future<ImageSourceKind?> showMediaSourceSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<ImageSourceKind>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => _MediaSourceSheet(title: title),
  );
}

class _MediaSourceSheet extends StatelessWidget {
  const _MediaSourceSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
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
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(color: colors.line, borderRadius: AppRadii.pill),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(title, style: type.sheetTitle.copyWith(color: colors.ink)),
                ),
                Semantics(
                  button: true,
                  label: AppLocalizations.of(context).sharedMediaSourceCloseLabel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close_rounded, size: 20, color: colors.ink2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            _SourceRow(
              icon: Icons.photo_camera_outlined,
              label: AppLocalizations.of(context).sharedMediaSourceCameraLabel,
              onTap: () => Navigator.of(context).pop(ImageSourceKind.camera),
            ),
            const SizedBox(height: AppSpacing.base),
            _SourceRow(
              icon: Icons.photo_library_outlined,
              label: AppLocalizations.of(context).sharedMediaSourceGalleryLabel,
              onTap: () => Navigator.of(context).pop(ImageSourceKind.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: label,
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
              Icon(icon, size: 20, color: colors.ink2),
              const SizedBox(width: AppSpacing.base),
              Expanded(child: Text(label, style: type.rowTitle.copyWith(color: colors.ink))),
            ],
          ),
        ),
      ),
    );
  }
}
