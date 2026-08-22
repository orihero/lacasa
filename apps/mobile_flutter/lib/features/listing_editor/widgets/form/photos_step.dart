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
///
/// **A failed upload is retryable in place** (was: remove-and-re-add only).
/// [ListingMediaUpload] retains the whole [PickedMedia] it was created from
/// — see that field's own doc comment for why that costs nothing — so
/// [PhotosStep._retryUpload] can re-fire the identical
/// `UploadsRepository.upload` call without sending the user back through
/// the OS picker. Both tiles expose it: the photo tile as a tappable
/// refresh glyph at the **bottom** of the thumbnail (a 73dp square has no
/// room for a labelled button, so the label is carried in [Semantics]; the
/// top-right corner is spoken for — see [_StatusOverlay]), the video row as
/// visible text. Removing a failed tile still works too, unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../api/api.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/platform/media_picker.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'listing_form_fields.dart';

/// `.phos{display:grid;grid-template-columns:repeat(4,1fr);gap:9px}` —
/// shared by this step's own new-upload grid and `edit-listing`'s
/// [ExistingPhotosGrid], which the mockup draws as one continuous
/// four-across gallery.
const int kListingPhotoGridColumns = 4;
const double kListingPhotoGridGap = 9;

/// `.pho__x` — the per-photo remove control: a 22px dark translucent
/// circle sitting *inside* the tile's top-right corner (5px in on both
/// axes), not a light badge hanging outside it. The visible circle stays
/// 22dp while the tap target is padded out around it, since a 22dp target
/// alone is below the touch-size guideline.
///
/// Returns a [Positioned], so it must be a direct child of the tile's
/// [Stack].
///
/// **The tap target is 32×32 and it owns the tile's whole top-right
/// corner** — 10dp wider and taller than the circle it draws. A [Stack]
/// hit-tests its children back-to-front, and this badge is the tile's last
/// child, so it wins every pointer inside that 32×32 square no matter what
/// is painted under it. Nothing else interactive may be drawn there; see
/// [_StatusOverlay], which learned that the hard way.
class ListingPhotoRemoveBadge extends StatelessWidget {
  const ListingPhotoRemoveBadge({
    super.key,
    required this.badgeKey,
    required this.onTap,
  });

  /// Key on the tap target itself (the widget tests tap this).
  final Key badgeKey;
  final VoidCallback onTap;

  static const Color _scrim = Color(0x99100E1A);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: GestureDetector(
        key: badgeKey,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: SizedBox(
            width: 22,
            height: 22,
            child: DecoratedBox(
              decoration: BoxDecoration(color: _scrim, shape: BoxShape.circle),
              child: Center(
                child: Icon(Icons.close_rounded, size: 11, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

  /// `UploadsResource.presign`'s scope for everything this step uploads —
  /// a photo and a video both land on the ad's own `photos[]` (see this
  /// file's doc comment), so there is one value, named once, rather than a
  /// parameter three call sites would each have to pass identically.
  static const String _uploadScope = 'ads';

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
        // `<p class="hint" style="margin:0 0 12px">Up to 5 images, 5 MB
        // each. One optional video, up to 70 MB.</p>` — the limits copy is
        // the *first* child of step 3's body, above `.phos`, so the step
        // opens by saying what fits rather than with a bare picker.
        Text(
          l10n.listingEditorMediaLimitsHint,
          style: type.bodySmall.copyWith(color: colors.faint),
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty || photoSlotsLeft > 0)
          _MediaGrid(
            items: photos,
            onRemove: (m) => _remove(m),
            onRetry: (m) => _retryUpload(ref, m),
            onAdd: photoSlotsLeft > 0 ? () => _addPhoto(context, ref) : null,
          ),
        for (final m in videos) ...[
          const SizedBox(height: 14),
          _VideoTile(
            item: m,
            onRemove: () => _remove(m),
            onRetry: () => _retryUpload(ref, m),
          ),
        ],
        if (videoSlotsLeft > 0) ...[
          // `<button class="lrow glf" style="margin-top:14px">` — the video
          // control is a list row, not a second picker box.
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: l10n.listingEditorAddVideoButtonLabel,
            child: GestureDetector(
              key: const ValueKey('createListing-addVideo'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _addVideo(context, ref),
              child: const _AddVideoRow(),
            ),
          ),
        ],
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
    );
  }

  void _startUpload(
    BuildContext context,
    WidgetRef ref, {
    required PickedMedia media,
    required bool isVideo,
    required int maxBytes,
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
      source: media,
    );
    fields.media.add(item);
    onChanged();

    _fireUpload(ref, item);
  }

  /// Re-runs the upload for a tile that ended in [MediaUploadStatus.failed]
  /// — the real retry the failed overlay used to lack (it was a status
  /// glyph with no tap handler, and the only way out was removing the tile
  /// and walking the OS picker again).
  ///
  /// Resets the tile to `uploading` **before** firing so the overlay swaps
  /// straight back to its progress ring: a tap that left a red error tile
  /// sitting there while a second request was genuinely in flight would
  /// read as "the retry didn't work either". The stale [errorMessage] and
  /// the old progress fraction are cleared for the same reason.
  ///
  /// A no-op unless the item actually failed — a double tap, or a tap
  /// landing on a frame where the first retry already succeeded, must not
  /// start a second upload of the same bytes.
  void _retryUpload(WidgetRef ref, ListingMediaUpload item) {
    if (item.status != MediaUploadStatus.failed) return;
    item
      ..status = MediaUploadStatus.uploading
      ..errorMessage = null
      ..url = null
      ..progress.value = 0;
    onChanged();
    _fireUpload(ref, item);
  }

  /// The single `UploadsRepository.upload` call site — shared by the first
  /// attempt ([_startUpload]) and every [_retryUpload] after it, so a retry
  /// can never drift into a subtly different request than the one it is
  /// replaying.
  void _fireUpload(WidgetRef ref, ListingMediaUpload item) {
    final handle = ref
        .read(uploadsRepositoryProvider)
        .upload(
          media: item.source,
          scope: _uploadScope,
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

/// `.pho--add{display:flex;flex-direction:column;align-items:center;
/// justify-content:center;gap:4px;font-size:9px;font-weight:600;
/// color:var(--muted)}` on a `.pho` square — the "add photo" control is the
/// last **cell of the `.phos` grid itself**, so it stays square and
/// four-across with the thumbnails rather than a full-width box beneath
/// them. Built by [_MediaGrid] when a photo slot is still free.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: l10n.listingEditorAddPhotosButtonLabel,
      child: GestureDetector(
        key: const ValueKey('createListing-addPhotos'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.md),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // `.pho--add .i{font-size:18px;color:var(--ink-2)}`
              Icon(Icons.add_rounded, size: 18, color: colors.ink2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.listingEditorAddPhotosButtonLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: type.caption.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The `.lrow glf` "Add a video" row — a `.lrow__ic` icon tile, a
/// title/subtitle pair and a trailing `.lrow__go` caret, the same shape
/// every other list row on this screen family uses.
class _AddVideoRow extends StatelessWidget {
  const _AddVideoRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // `.lrow{display:flex;align-items:center;gap:12px;border-radius:20px;
    // padding:13px 15px}`
    return GlassSurface(
      variant: GlassVariant.flatForm,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          // `.lrow__ic{width:36px;height:36px;border-radius:12px;
          // color:var(--ink);background:var(--sunk)}`
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sunk,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(Icons.videocam_rounded, size: 17, color: colors.ink),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.listingEditorAddVideoButtonLabel,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.listingEditorAddVideoOptionalHint,
                  style: type.specMeta.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(Icons.chevron_right_rounded, size: 18, color: colors.faint),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.items,
    required this.onRemove,
    required this.onRetry,
    required this.onAdd,
  });

  final List<ListingMediaUpload> items;
  final ValueChanged<ListingMediaUpload> onRemove;

  /// Re-fires one failed tile's upload — see [PhotosStep._retryUpload].
  final ValueChanged<ListingMediaUpload> onRetry;

  /// Non-null while a photo slot is still free — the grid then closes with
  /// an [_AddPhotoTile] cell. `null` once the 5-photo cap is spent, which
  /// simply drops the cell.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final add = onAdd;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length + (add == null ? 0 : 1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kListingPhotoGridColumns,
        crossAxisSpacing: kListingPhotoGridGap,
        mainAxisSpacing: kListingPhotoGridGap,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index == items.length) return _AddPhotoTile(onTap: add!);
        final item = items[index];
        return _PhotoTile(
          key: ValueKey('newPhoto-${item.id}'),
          item: item,
          onRemove: () => onRemove(item),
          onRetry: () => onRetry(item),
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onRetry,
  });

  final ListingMediaUpload item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: ColoredBox(
              color: colors.sunk,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    item.previewBytes,
                    fit: BoxFit.cover,
                    // Matches `ListingPhoto`'s own "never show a
                    // broken-image glyph" rule — undecodable bytes (or a
                    // test's placeholder fixture) fall back to a themed box
                    // instead of throwing.
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: colors.sunk),
                  ),
                  _StatusOverlay(item: item, onRetry: onRetry),
                ],
              ),
            ),
          ),
        ),
        ListingPhotoRemoveBadge(
          badgeKey: ValueKey('newPhoto-remove-${item.id}'),
          onTap: onRemove,
        ),
      ],
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.item,
    required this.onRemove,
    required this.onRetry,
  });

  final ListingMediaUpload item;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

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
                // The video row is full-width, so unlike the photo tile it
                // has room to spell the action out rather than lean on a
                // glyph plus a Semantics label.
                if (item.status == MediaUploadStatus.failed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  GestureDetector(
                    key: ValueKey('newVideo-retry-${item.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onRetry,
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).listingEditorRetryUploadLabel,
                      style: type.caption.copyWith(color: AppAccent.color),
                    ),
                  ),
                ],
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

/// Sits over [_PhotoTile]'s thumbnail — a progress ring while uploading,
/// nothing once done (the thumbnail speaks for itself), and on failure a
/// dark wash carrying **both** halves of the recovery this tile owes the
/// user: why it failed, and how to fix it.
///
/// **Both halves are new.** The overlay used to be a bare
/// `error_outline` glyph with no tap handler and no text, so a failed tile
/// said only "something about this one is wrong" — the reason
/// (`item.errorMessage`, already run through `describeUploadError`) was
/// computed and then never rendered anywhere, even though the video row's
/// own [_StatusLine] had been printing it all along. The glyph is now the
/// retry control itself: a 73dp square has no room for a labelled button
/// next to two lines of error text, so it is drawn as a refresh icon in a
/// scrim circle (which reads as pressable in a way a bare status glyph
/// does not) and carries [AppLocalizations.listingEditorRetryUploadLabel]
/// as its [Semantics] label for screen readers. Remove-and-re-add still
/// works via [_PhotoTile]'s own corner "x", which is present at any status.
///
/// **Why the retry glyph is the last row of this column, not the first.**
/// It was first, i.e. centred horizontally and sitting just under the
/// tile's top edge — which put roughly a third of its 24dp circle inside
/// [ListingPhotoRemoveBadge]'s 32×32 tap target. That badge is the tile
/// [Stack]'s last child, so it hit-tests first and swallowed every one of
/// those pointers: aiming at "retry my failed upload" and clipping the
/// corner *deleted the photo* instead. The two controls are not
/// symmetrical — a missed Retry costs a second tap, a missed Remove costs
/// the picked file — so the recoverable one yields the corner entirely.
/// Bottom-aligning this column parks the glyph in the tile's bottom
/// ~28dp (73dp tile − 4dp padding − 24dp glyph = a 45dp top edge), a full
/// 13dp clear of the badge's 32dp reach, and the gap only widens on wider
/// tiles. Keep it last; `photos_step_test.dart` asserts the two rects do
/// not intersect at 360dp.
///
/// **Bottom-aligning the column was not enough for the *text*.** The glyph
/// cleared the badge; the error sentence above it did not — its first line
/// landed inside the badge's circle and was painted over, hiding the one
/// thing this overlay exists to say. The text therefore carries an end
/// inset of [_badgeClearance] as well; see the comment on the [Text]
/// itself for the arithmetic and for what that costs.
class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.item, required this.onRetry});

  /// How much of the tile's trailing edge belongs to
  /// [ListingPhotoRemoveBadge] and must stay empty. The badge's whole
  /// reach is 32dp (a 22dp circle inset 5dp on both axes); this overlay
  /// already insets its own content by [AppSpacing.xs], so 32 − 4 = 28 is
  /// what the text has to give back on top of that.
  static const double _badgeClearance = 32 - AppSpacing.xs;

  final ListingMediaUpload item;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (item.status == MediaUploadStatus.failed) {
      final l10n = AppLocalizations.of(context);
      final type = Theme.of(context).extension<LaCasaTypography>()!;

      return ColoredBox(
        color: Colors.black54,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Column(
            // Bottom-aligned so the glyph below clears the remove badge's
            // corner — see this class's own doc comment.
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // **Two lines is the ceiling.** The narrowest grid cell this
              // app targets is 73.25dp square (360dp screen, four across,
              // 9dp gaps). Once the 4dp padding above *and* below, the
              // 24dp retry glyph and its 3dp gap are taken out, the text
              // budget is 73.25 − 4 − 4 − 24 − 3 = **38.25dp** — two
              // `caption` lines at 14.25dp fit (28.5) and a third does not
              // (42.75). (An earlier revision of this comment claimed
              // "~65dp"; that is what the 4dp padding alone leaves, and it
              // forgot the glyph the text is standing on. The two-line
              // conclusion was right for the wrong number.)
              //
              // **The trailing [_badgeClearance] is not ours to draw in.**
              // [ListingPhotoRemoveBadge] paints its 22dp circle 5dp in
              // from the tile's top-right corner and is the tile [Stack]'s
              // *last* child, so it paints over everything this column
              // draws. Bottom-aligning the column saves the glyph but not
              // the text: two lines start 13.75dp down (42.25 − 2 ×
              // 14.25), squarely inside the circle's [5, 27] band, and the
              // first line of the reason — the whole point of this
              // overlay — disappeared under the close button. Insetting
              // the *box* rather than nudging the baseline is what keeps
              // that true at a larger text scale or a taller line, since
              // no line of any height can reach into the reserved column.
              //
              // It costs width: ~37dp of line on a 360dp screen, so a long
              // `describeUploadError` sentence ellipsizes to a fragment
              // here. That is accepted rather than worked around — a
              // legible fragment of the real reason beats the whole
              // sentence painted under a close button, and it still says
              // more than the bare glyph this replaced. The untruncated
              // sentence has a full-width home on the video row's own
              // [_StatusLine], and every tile wider than 73dp (any screen
              // above 360dp, and every tablet) gets the extra width back.
              Padding(
                padding: const EdgeInsets.only(right: _badgeClearance),
                // Full width of what is left, not the text's intrinsic
                // width: this [Column] centres its children, so a *short*
                // message inside a right-padded box would otherwise be
                // pulled left of centre by half the inset. Filling makes
                // the text box the same rect at every message length,
                // which is also what the overlap test can assert against.
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    item.errorMessage ??
                        l10n.listingEditorUploadFailedFallbackMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Semantics(
                button: true,
                label: l10n.listingEditorRetryUploadLabel,
                child: GestureDetector(
                  key: ValueKey('newPhoto-retry-${item.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onRetry,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
