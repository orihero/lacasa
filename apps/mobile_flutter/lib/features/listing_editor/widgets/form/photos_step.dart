/// Step 3 "Photos" (§26) — "photo picker, up to 5 images / 5MB each;
/// optional single video up to 70MB." Also `edit-listing`'s (§27) "new-
/// upload picker", embedded next to [ExistingPhotosGrid] rather than a step
/// of its own — same widget, [existingPhotoCount] just tells it how many of
/// the 5-photo cap the existing grid has already spent.
///
/// **The flow**: tap "Add photos"/"Add video" → [showMediaSourceSheet]
/// (camera/gallery) → `MediaPicker.pickImage`/`pickVideo` → a client-side
/// size check (§26's 5MB/70MB — `UploadsResource`'s own doc comment: there
/// is nothing server-side to catch this) → `UploadsRepository.upload`,
/// showing real per-chunk progress on the tile → the resulting URL lands in
/// [ListingFormFields.media], which `create_listing_screen.dart`/
/// `edit_listing_screen.dart` fold into the `photos[]` write body via
/// [ListingFormFields.uploadedMediaUrls].
///
/// **Video shares the ad's one `photos[]` field — there is no separate
/// video field on the wire.** `packages/domain/src/schemas/ad.ts`'s own
/// comment is explicit: "no CRM upload flow produces a video AdPhoto row
/// yet... lets the AdPhoto.mediaType column default to PHOTO." A picked
/// video's URL goes into the exact same list a picked photo's does; the
/// distinction this step draws between an "Add photos" tile (up to 5) and
/// an "Add video" tile (up to 1) is UI-only bookkeeping matching §26's own
/// text, not a wire-level split this client can create where the server
/// doesn't have one.
///
/// **A user cancelling the OS picker is not an error** — `MediaPicker`'s own
/// contract (`null`, not a throw); this step shows nothing for it. A picker
/// failure (denied permission, no camera), an over-size file, or an upload
/// failure all render inline on the tile, per this app's honesty rule.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../api/api.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/platform/media_picker.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'listing_form_fields.dart';

class PhotosStep extends ConsumerWidget {
  const PhotosStep({
    super.key,
    required this.fields,
    required this.onChanged,
    this.existingPhotoCount = 0,
  });

  final ListingFormFields fields;
  final VoidCallback onChanged;

  /// How many of §26's 5-photo cap `edit-listing`'s own
  /// [ExistingPhotosGrid] has already spent — 0 for `create-listing`,
  /// which has nothing pre-existing.
  final int existingPhotoCount;

  static const int _maxPhotos = 5;
  static const int _maxVideos = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final photos = [
      for (final m in fields.media)
        if (!m.isVideo) m,
    ];
    final videos = [
      for (final m in fields.media)
        if (m.isVideo) m,
    ];
    final photoSlotsLeft = _maxPhotos - existingPhotoCount - photos.length;
    final videoSlotsLeft = _maxVideos - videos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isNotEmpty) ...[
          _MediaGrid(items: photos, onRemove: (m) => _remove(m)),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (photoSlotsLeft > 0)
          Semantics(
            button: true,
            label: l10n.listingEditorAddPhotosButtonLabel,
            child: GestureDetector(
              key: const ValueKey('createListing-addPhotos'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _addPhoto(context, ref),
              child: DottedPlaceholder(
                icon: Icons.add_photo_alternate_outlined,
                label: l10n.listingEditorAddPhotosButtonLabel,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.listingEditorMediaLimitsHint,
          style: type.bodySmall.copyWith(color: colors.faint),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (videos.isNotEmpty) ...[
          for (final m in videos) ...[
            _VideoTile(item: m, onRemove: () => _remove(m)),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        if (videoSlotsLeft > 0)
          Semantics(
            button: true,
            label: l10n.listingEditorAddVideoButtonLabel,
            child: GestureDetector(
              key: const ValueKey('createListing-addVideo'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _addVideo(context, ref),
              child: DottedPlaceholder(
                icon: Icons.videocam_outlined,
                label: l10n.listingEditorAddVideoButtonLabel,
              ),
            ),
          ),
      ],
    );
  }

  void _remove(ListingMediaUpload item) {
    item.dispose();
    fields.media.remove(item);
    onChanged();
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await showMediaSourceSheet(
      context,
      title: AppLocalizations.of(context).listingEditorAddPhotoSheetTitle,
    );
    if (source == null || !context.mounted) return;

    final PickedMedia? media;
    try {
      media = await ref.read(mediaPickerProvider).pickImage(source: source);
    } on MediaPickerException catch (e) {
      if (context.mounted) LaCasaToast.showError(context, e.message);
      return;
    }
    if (media == null || !context.mounted) return; // cancelled — not an error

    _startUpload(
      context,
      ref,
      media: media,
      isVideo: false,
      maxBytes: kMaxPhotoBytes,
      scope: 'ads',
    );
  }

  Future<void> _addVideo(BuildContext context, WidgetRef ref) async {
    final source = await showMediaSourceSheet(
      context,
      title: AppLocalizations.of(context).listingEditorAddVideoSheetTitle,
    );
    if (source == null || !context.mounted) return;

    final PickedMedia? media;
    try {
      media = await ref.read(mediaPickerProvider).pickVideo(source: source);
    } on MediaPickerException catch (e) {
      if (context.mounted) LaCasaToast.showError(context, e.message);
      return;
    }
    if (media == null || !context.mounted) return; // cancelled — not an error

    _startUpload(
      context,
      ref,
      media: media,
      isVideo: true,
      maxBytes: kMaxVideoBytes,
      scope: 'ads',
    );
  }

  void _startUpload(
    BuildContext context,
    WidgetRef ref, {
    required PickedMedia media,
    required bool isVideo,
    required int maxBytes,
    required String scope,
  }) {
    if (media.bytes.length > maxBytes) {
      if (context.mounted) {
        LaCasaToast.showError(
          context,
          describeUploadError(MediaTooLarge(maxBytes)),
        );
      }
      return;
    }

    final item = ListingMediaUpload(
      id: '${DateTime.now().microsecondsSinceEpoch}-${fields.media.length}',
      isVideo: isVideo,
      previewBytes: media.bytes,
      fileName: media.fileName,
    );
    fields.media.add(item);
    onChanged();

    final handle = ref
        .read(uploadsRepositoryProvider)
        .upload(
          media: media,
          scope: scope,
          onProgress: (p) => item.progress.value = p,
        );
    item.handle = handle;

    handle.result
        .then((url) {
          item
            ..status = MediaUploadStatus.done
            ..url = url;
          onChanged();
        })
        .catchError((Object e) {
          if (e is UploadCancelled) return; // removed on purpose, not a failure
          item
            ..status = MediaUploadStatus.failed
            ..errorMessage = describeUploadError(e);
          onChanged();
        });
  }
}

/// A dashed-look empty-slot box, the tap target for both "Add photos" and
/// "Add video" — visually communicates "tap to add" the same way it always
/// has; only what tapping it now *does* changed.
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

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.items, required this.onRemove});

  final List<ListingMediaUpload> items;
  final ValueChanged<ListingMediaUpload> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _PhotoTile(
          key: ValueKey('newPhoto-${item.id}'),
          item: item,
          onRemove: () => onRemove(item),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({super.key, required this.item, required this.onRemove});

  final ListingMediaUpload item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                item.previewBytes,
                fit: BoxFit.cover,
                // Matches `ListingPhoto`'s own "never show a broken-image
                // glyph" rule — undecodable bytes (or a test's placeholder
                // fixture) fall back to a themed box instead of throwing.
                errorBuilder: (context, error, stackTrace) =>
                    ColoredBox(color: colors.sunk),
              ),
              _StatusOverlay(item: item),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            key: ValueKey('newPhoto-remove-${item.id}'),
            onTap: onRemove,
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
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.item, required this.onRemove});

  final ListingMediaUpload item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      key: ValueKey('newVideo-${item.id}'),
      decoration: BoxDecoration(
        color: colors.sunk,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.line, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Icon(Icons.videocam_rounded, size: 22, color: colors.ink2),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName ??
                      AppLocalizations.of(
                        context,
                      ).listingEditorVideoFallbackFileName,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.xs),
                _StatusLine(item: item),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            key: ValueKey('newVideo-remove-${item.id}'),
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 18, color: colors.ink2),
          ),
        ],
      ),
    );
  }
}

/// Sits over [_PhotoTile]'s thumbnail — a progress ring while uploading, a
/// dark wash + error icon on failure, nothing once done (the thumbnail
/// speaks for itself). The error icon is not a retry button — it has no tap
/// handler, purely a status glyph. Recovery from a failed tile is
/// remove-and-re-add via [_PhotoTile]'s own corner "x" (always present,
/// any status), not a per-tile retry of the same upload.
class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.item});

  final ListingMediaUpload item;

  @override
  Widget build(BuildContext context) {
    if (item.status == MediaUploadStatus.failed) {
      return const ColoredBox(
        color: Colors.black45,
        child: Center(
          child: Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      );
    }
    if (item.status == MediaUploadStatus.done) return const SizedBox.shrink();

    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: ValueListenableBuilder<double>(
          valueListenable: item.progress,
          builder: (context, value, _) {
            return SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                value: value > 0 ? value : null,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// [_VideoTile]'s inline status text — a percentage while uploading, the
/// error sentence on failure, "Uploaded" once done.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.item});

  final ListingMediaUpload item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    if (item.status == MediaUploadStatus.failed) {
      return Text(
        item.errorMessage ?? l10n.listingEditorUploadFailedFallbackMessage,
        style: type.caption.copyWith(color: AppStatusColors.errorText),
      );
    }
    if (item.status == MediaUploadStatus.done) {
      return Text(
        l10n.listingEditorUploadedStatusLabel,
        style: type.caption.copyWith(color: AppStatusColors.successText),
      );
    }
    return ValueListenableBuilder<double>(
      valueListenable: item.progress,
      builder: (context, value, _) {
        return Text(
          l10n.listingEditorUploadingProgressLabel((value * 100).round()),
          style: type.caption,
        );
      },
    );
  }
}
