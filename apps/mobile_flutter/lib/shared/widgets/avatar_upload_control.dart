/// The real avatar picker + uploader every "Change photo"/"Add photo"
/// control in this app renders — `edit-profile` (§3.18), `coworker-detail`
/// (§36), `add-coworker` (§37). Replaces each screen's own
/// `MediaUploadUnavailableNotice` stand-in now that `shared/platform/
/// media_picker.dart` and `shared/state/uploads_repository.dart` both
/// exist: tap → [showMediaSourceSheet] → `MediaPicker.pickImage` → size/
/// type check → `UploadsRepository.upload` with a progress ring over the
/// avatar → [onUploaded] with the resulting public URL.
///
/// **Not itself submitted anywhere.** This widget only gets bytes to a
/// public URL; a caller's own Save/Create decides whether/how that URL
/// reaches the server (immediately for `add-coworker`'s create-time
/// `avatar` field, only-if-changed for `edit-profile`/`coworker-detail`'s
/// patch semantics — see each screen's own `_hasChanges`/submit logic).
///
/// **No permission_handler call here, by design.** The `image_picker`
/// plugin raises its own OS permission prompt; a caller-side
/// `permission_handler` request first would double-prompt. A denied OS
/// permission instead surfaces as [MediaPickerException] with its own
/// user-facing message (`media_picker.dart`'s `_describe`, which already
/// points the user at Settings) and is shown via [onError] like any other
/// upload failure.
///
/// **[onUploadStateChanged] closes the Save-before-upload-finishes race.**
/// This widget used to expose no busy signal at all: pick a photo, tap Save
/// before the upload resolves, and the screen would pop on the *old*
/// avatar URL while [dispose] silently cancelled the in-flight upload —
/// the new photo vanished with nothing shown to the user, exactly what this
/// app's honesty rule exists to prevent. [onUploadStateChanged] fires
/// `true` the moment a pick turns into an upload and `false` once it
/// settles (success, failure, or a plain picker cancel never reaches
/// `true` at all), so every caller can track "is there a photo in flight"
/// in its own state and refuse to submit stale data — see each of the
/// three callers' own `_submit`, which block Save with a toast rather than
/// awaiting the upload: blocking matches `listing_form_fields.dart`'s
/// existing `hasPendingUploads` precedent for the exact same race on
/// listing photos, and is simpler to reason about than the alternative of
/// awaiting the in-flight handle inline (which would tangle Save's own
/// error handling with the upload's, and raise its own question of what
/// happens if the user backs out mid-await).
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import '../platform/media_picker.dart';
import '../state/uploads_repository.dart';
import '../state/uploads_repository_provider.dart';
import 'agent_avatar.dart';
import 'media_source_sheet.dart';

class AvatarUploadControl extends ConsumerStatefulWidget {
  const AvatarUploadControl({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    required this.onUploaded,
    required this.onError,
    required this.onUploadStateChanged,
    this.size = 84,
    this.semanticsLabel,
  });

  final String? avatarUrl;
  final String fullName;

  /// Called once the upload finishes successfully, with the new public URL.
  final ValueChanged<String> onUploaded;

  /// Called for any failure worth telling the user about — a denied
  /// permission, a file over [kMaxPhotoBytes], a network/server failure.
  /// Never called for a plain picker cancel (see this file's doc comment).
  final ValueChanged<String> onError;

  /// `true` once a picked photo starts uploading, `false` once that upload
  /// settles one way or another — see this file's doc comment. Required
  /// (not optional) so a future caller can't silently reintroduce the
  /// Save-before-upload-finishes race by forgetting to wire it.
  final ValueChanged<bool> onUploadStateChanged;

  final double size;

  /// Defaults to [AppLocalizations.sharedChangePhotoLabel] (`null` here
  /// rather than that string as a literal default) — a localized lookup
  /// needs a [BuildContext], which a `const` constructor's default
  /// parameter value cannot provide; the fallback is applied in [build]
  /// instead.
  final String? semanticsLabel;

  @override
  ConsumerState<AvatarUploadControl> createState() => _AvatarUploadControlState();
}

class _AvatarUploadControlState extends ConsumerState<AvatarUploadControl> {
  Uint8List? _localPreview;
  double? _progress;
  UploadHandle? _handle;

  @override
  void dispose() {
    // A still-running upload has nothing left to report to once this
    // widget is gone (its result would only ever reach `setState` on a
    // disposed State) — cancel rather than let it finish invisibly and
    // leak an unattached object into the "avatars" bucket for nothing.
    _handle?.cancel();
    super.dispose();
  }

  bool get _busy => _progress != null;

  Future<void> _pick() async {
    if (_busy) return;

    final source = await showMediaSourceSheet(
      context,
      title: AppLocalizations.of(context).sharedChangePhotoLabel,
    );
    if (source == null || !mounted) return;

    final PickedMedia? media;
    try {
      media = await ref.read(mediaPickerProvider).pickImage(source: source);
    } on MediaPickerException catch (e) {
      if (mounted) widget.onError(e.message);
      return;
    }
    if (media == null || !mounted) return; // user cancelled — not an error

    if (media.bytes.length > kMaxPhotoBytes) {
      widget.onError(describeUploadError(const MediaTooLarge(kMaxPhotoBytes)));
      return;
    }

    setState(() {
      _localPreview = media!.bytes;
      _progress = 0;
    });
    // Fires before the upload is even started, not after the first
    // progress tick — a caller's Save must be blocked from the instant
    // there is a photo with no settled URL yet, not just once bytes start
    // moving.
    widget.onUploadStateChanged(true);

    final handle = ref.read(uploadsRepositoryProvider).upload(
      media: media,
      scope: 'avatars',
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    _handle = handle;

    try {
      final url = await handle.result;
      if (!mounted) return;
      setState(() {
        _localPreview = null;
        _progress = null;
        _handle = null;
      });
      widget.onUploadStateChanged(false);
      widget.onUploaded(url);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localPreview = null;
        _progress = null;
        _handle = null;
      });
      widget.onUploadStateChanged(false);
      if (e is! UploadCancelled) widget.onError(describeUploadError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? AppLocalizations.of(context).sharedChangePhotoLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pick,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: _localPreview != null
                    ? Image.memory(
                        _localPreview!,
                        fit: BoxFit.cover,
                        // Matches `ListingPhoto`'s own "never show a
                        // broken-image glyph" rule.
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: colors.sunk),
                      )
                    : AgentAvatar(
                        avatarUrl: widget.avatarUrl,
                        fullName: widget.fullName,
                        size: widget.size,
                      ),
              ),
            ),
            if (_progress != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
                  child: Center(
                    child: SizedBox(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: _progress! > 0 ? _progress : null,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sunk,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.screen, width: 2),
                ),
                // Accent-colored now — see this file's doc comment; this
                // badge starts a real upload, unlike the muted badge the
                // stand-in it replaced used to render.
                child: const Icon(Icons.photo_camera_outlined, size: 14, color: AppAccent.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
