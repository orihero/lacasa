/// The seam between anything that needs a photo or video from the device
/// and the `image_picker` plugin that actually reaches the camera or photo
/// library.
///
/// ## Why this is a seam and not a direct `image_picker` call
///
/// Same argument as `permission_gateway.dart` and `link_launcher.dart`:
/// every platform capability in this app is reached through an interface
/// with a provider a test can override, never called directly from a
/// widget. Four screens need exactly this (`create-listing`/`edit-listing`
/// photos and video, `add-coworker`/`coworker-detail` avatars) and would
/// otherwise each grow their own slightly different `ImagePicker()` call
/// site. `MediaUploadUnavailableNotice`
/// (`shared/widgets/media_upload_unavailable_notice.dart`) was the honest
/// stand-in while there was no plugin and no `Info.plist`/manifest
/// declarations to back it; both now exist, so this is that seam's real
/// implementation.
///
/// ## The shape of [PickedMedia]
///
/// Carries exactly what `UploadsResource.presign`/`putBytes` need and
/// nothing else — `fileName` and `contentType` (`presign`'s
/// `fileName`/`contentType` body fields) and `bytes` (`putBytes`'s raw PUT
/// body). A caller does not need to touch `dart:io`/`File` at all, which
/// also keeps this working on web where there is no filesystem path to
/// hand around.
///
/// ## `null` means cancelled, not error
///
/// [MediaPicker.pickImage]/[MediaPicker.pickVideo] return `null` when the
/// user backs out of the OS picker UI — expected, silent, not something a
/// caller should show an error for. A **denied OS permission**, a missing
/// camera, or any other plugin failure is a different outcome and is
/// surfaced by throwing [MediaPickerException] instead, so a caller can
/// tell "you changed your mind" apart from "this genuinely didn't work"
/// and, per this project's honesty rule, say the latter out loud rather
/// than swallow it into the same silent `null`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;

/// Where [MediaPicker] should read the image/video from.
enum ImageSourceKind { camera, gallery }

/// One picked file, shaped for `UploadsResource.presign`/`putBytes` — see
/// this file's doc comment.
class PickedMedia {
  const PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;

  /// Matches `UploadsResource.presign`'s `^(image|video)/` requirement.
  final String mimeType;
}

/// A plugin call failed for a reason that is not "the user cancelled" —
/// see this file's doc comment on the `null`-vs-throw contract. [message]
/// is written to be shown to the user as-is.
class MediaPickerException implements Exception {
  const MediaPickerException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class MediaPicker {
  /// Opens the camera or photo library per [source] and returns the chosen
  /// image, or `null` if the user cancelled. Throws [MediaPickerException]
  /// for any other failure (permission denied, no camera hardware, ...).
  Future<PickedMedia?> pickImage({required ImageSourceKind source});

  /// Same contract as [pickImage], for video.
  Future<PickedMedia?> pickVideo({required ImageSourceKind source});
}

/// The real, `image_picker`-backed implementation — see this file's doc
/// comment.
class ImagePickerMediaPicker implements MediaPicker {
  const ImagePickerMediaPicker();

  static const _fallbackImageMimeType = 'image/jpeg';
  static const _fallbackVideoMimeType = 'video/mp4';

  @override
  Future<PickedMedia?> pickImage({required ImageSourceKind source}) {
    return _pick(
      source: source,
      fallbackMimeType: _fallbackImageMimeType,
      pick: (picker, imageSource) => picker.pickImage(source: imageSource),
    );
  }

  @override
  Future<PickedMedia?> pickVideo({required ImageSourceKind source}) {
    return _pick(
      source: source,
      fallbackMimeType: _fallbackVideoMimeType,
      pick: (picker, imageSource) => picker.pickVideo(source: imageSource),
    );
  }

  Future<PickedMedia?> _pick({
    required ImageSourceKind source,
    required String fallbackMimeType,
    required Future<image_picker.XFile?> Function(
      image_picker.ImagePicker picker,
      image_picker.ImageSource imageSource,
    ) pick,
  }) async {
    final image_picker.ImageSource imageSource = switch (source) {
      ImageSourceKind.camera => image_picker.ImageSource.camera,
      ImageSourceKind.gallery => image_picker.ImageSource.gallery,
    };

    final image_picker.XFile? file;
    try {
      file = await pick(image_picker.ImagePicker(), imageSource);
    } on Exception catch (e) {
      // `image_picker` throws (rather than returning null) for everything
      // that isn't a plain cancel — a denied OS permission surfaces here
      // as a `PlatformException`. Re-thrown as our own type so a caller
      // can display it without depending on a plugin-specific exception
      // shape.
      throw MediaPickerException(_describe(e));
    }
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return PickedMedia(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType ?? fallbackMimeType,
    );
  }

  String _describe(Exception e) {
    final message = e.toString();
    if (message.contains('camera_access_denied') ||
        message.contains('photo_access_denied')) {
      return "La Casa doesn't have permission to use the camera or photo "
          'library. Allow it in system settings, then try again.';
    }
    return "Couldn't open the picker. Please try again.";
  }
}

/// Supplies the [MediaPicker] every photo/video/avatar control reads
/// through. A test overrides this with a fake that returns a fixed
/// [PickedMedia] or `null` instead of touching the OS.
final mediaPickerProvider = Provider<MediaPicker>((ref) {
  return const ImagePickerMediaPicker();
});
