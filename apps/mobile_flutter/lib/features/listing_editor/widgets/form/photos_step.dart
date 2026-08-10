/// Step 3 "Photos" (§26) — "photo picker, up to 5 images / 5MB each;
/// optional single video up to 70MB." **No image/video picker exists in
/// this build** (contract ruling 5.2/7.4's Photos note) — there is no
/// `image_picker` dependency and none may be added here. Rather than draw
/// a picker UI that does nothing when tapped, this step shows
/// [MediaUploadUnavailableNotice] and routes any tap through
/// [showMediaUploadUnavailableToast], the same honest seam
/// `edit-profile`'s avatar control uses. `UploadsResource` is real and
/// correct (`lib/api/resources/uploads_resource.dart`) — it simply has no
/// bytes to hand it in this build.
library;

import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';

class PhotosStep extends StatelessWidget {
  const PhotosStep({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Add photos — $kMediaUploadUnavailableMessage',
          child: GestureDetector(
            key: const ValueKey('createListing-addPhotos'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showMediaUploadUnavailableToast(context, label: 'Photo upload'),
            child: DottedPlaceholder(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Add photos',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const MediaUploadUnavailableNotice(label: 'Photo upload'),
        const SizedBox(height: AppSpacing.section),
        Text(
          'Up to 5 images (5MB each). An optional single video up to 70MB.',
          style: type.bodySmall.copyWith(color: colors.faint),
        ),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          button: true,
          label: 'Add video — $kMediaUploadUnavailableMessage',
          child: GestureDetector(
            key: const ValueKey('createListing-addVideo'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showMediaUploadUnavailableToast(context, label: 'Video upload'),
            child: DottedPlaceholder(
              icon: Icons.videocam_outlined,
              label: 'Add video',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const MediaUploadUnavailableNotice(label: 'Video upload'),
      ],
    );
  }
}

/// A dashed-look empty-slot box, shared by the photo and video tap targets
/// above — visually communicates "tap to add" without claiming a working
/// picker sits behind it (the caption underneath is what makes that
/// honest).
class DottedPlaceholder extends StatelessWidget {
  const DottedPlaceholder({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: colors.faint),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: type.bodySmall.copyWith(color: colors.muted)),
        ],
      ),
    );
  }
}
