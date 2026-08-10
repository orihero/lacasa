/// `edit-listing`'s "Existing photos shown in a gallery grid with
/// per-photo delete 'X', separate from the new-upload picker" (§27). Unlike
/// `photos_step.dart`'s picker, this one is genuinely buildable — the
/// photos are already-uploaded URLs on the fetched [Ad], and "delete" is
/// just removing a string from the list this widget hands back through
/// [onChanged]; the caller folds that into the `photos` field of its next
/// Save.
library;

import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';

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
        'No photos on this listing yet.',
        style: type.bodySmall.copyWith(color: colors.faint),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Stack(
          key: ValueKey('existingPhoto-$index'),
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: ListingPhoto(url: photos[index]),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                key: ValueKey('existingPhoto-remove-$index'),
                onTap: () {
                  final next = List.of(photos)..removeAt(index);
                  onChanged(next);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.card,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card,
                  ),
                  child: Icon(Icons.close_rounded, size: 15, color: colors.ink),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
