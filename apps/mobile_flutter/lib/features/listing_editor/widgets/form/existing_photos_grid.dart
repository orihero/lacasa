/// `edit-listing`'s "Existing photos shown in a gallery grid with
/// per-photo delete 'X', separate from the new-upload picker" (§27). Unlike
/// `photos_step.dart`'s picker, this one is genuinely buildable — the
/// photos are already-uploaded URLs on the fetched [Ad], and "delete" is
/// just removing a string from the list this widget hands back through
/// [onChanged]; the caller folds that into the `photos` field of its next
/// Save.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'photos_step.dart';

class ExistingPhotosGrid extends StatelessWidget {
  const ExistingPhotosGrid({
    super.key,
    required this.photos,
    required this.onChanged,
  });

  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    if (photos.isEmpty) {
      return Text(
        AppLocalizations.of(context).listingEditorNoExistingPhotosMessage,
        style: type.bodySmall.copyWith(color: colors.faint),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kListingPhotoGridColumns,
        crossAxisSpacing: kListingPhotoGridGap,
        mainAxisSpacing: kListingPhotoGridGap,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Stack(
          key: ValueKey('existingPhoto-$index'),
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: ColoredBox(
                  color: colors.sunk,
                  child: ListingPhoto(url: photos[index]),
                ),
              ),
            ),
            ListingPhotoRemoveBadge(
              badgeKey: ValueKey('existingPhoto-remove-$index'),
              onTap: () {
                final next = List.of(photos)..removeAt(index);
                onChanged(next);
              },
            ),
          ],
        );
      },
    );
  }
}
