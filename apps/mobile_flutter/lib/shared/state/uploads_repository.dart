/// Data-access seam between "I have picked bytes" ([PickedMedia], from
/// `shared/platform/media_picker.dart`) and "I have a public URL" — the
/// presign-then-PUT round trip `lib/api/resources/uploads_resource.dart`
/// implements, wrapped here so every picker-backed control (listing
/// photos/video, edit-profile/coworker avatars) drives the same interface
/// instead of each reaching into `UploadsResource` and re-deriving its own
/// progress/cancel/error handling.
///
/// **No fixture/live switch, unlike every other repository in this app.**
/// Every other feature's `*_mode.dart` defaults to a bundled fixture so the
/// screen renders with no network — but [MediaPicker] itself has no fixture
/// half either (see its own doc comment: "Real from day one"); the moment a
/// user taps a picker control, the app is already reaching the real OS
/// camera/gallery, so there is nothing left to protect by faking the
/// upload that follows it. A fixture here could only ever do one of two
/// dishonest things: claim success for bytes that went nowhere, or require
/// a mock server just to demo a working build — neither serves "renders
/// sensibly with no network" the way the other fixtures do. If the network
/// really is down, [upload] surfaces that as a real, typed failure (see
/// [describeUploadError]) instead of pretending.
library;

import '../../api/api.dart';
import '../platform/media_picker.dart';

/// Handle to an in-flight [UploadsRepository.upload] call. [result]
/// resolves to the uploaded file's public URL, or rejects — with
/// `UploadCancelled` (`lib/api/resources/uploads_resource.dart`) if
/// [cancel] was called before it settled, or with the same
/// [ApiException]/[NetworkException] types every other repository in this
/// app throws otherwise. Calling [cancel] after [result] has already
/// settled is a harmless no-op.
class UploadHandle {
  const UploadHandle({required this.result, required this.cancel});

  final Future<String> result;
  final void Function() cancel;
}

abstract class UploadsRepository {
  /// Starts uploading [media] under [scope] (`"ads"` or `"avatars"`, see
  /// `UploadsResource.presign`) and returns immediately with a handle —
  /// callers that want progress pass [onProgress], called with a 0..1
  /// fraction as bytes go out; a caller with no progress UI (an avatar
  /// control showing only a spinner) can leave it `null`.
  UploadHandle upload({
    required PickedMedia media,
    required String scope,
    void Function(double progress)? onProgress,
  });
}

/// SCREENS.md §26's UI-only picker limits — see
/// `UploadsResource.presign`'s own doc comment for why the server enforces
/// neither. No avatar-specific figure exists anywhere in SCREENS.md, so
/// avatar controls reuse [kMaxPhotoBytes] rather than inventing a new
/// number.
const int kMaxPhotoBytes = 5 * 1024 * 1024;
const int kMaxVideoBytes = 70 * 1024 * 1024;

/// A picked file too big for [kMaxPhotoBytes]/[kMaxVideoBytes] — checked
/// client-side, before ever calling [UploadsRepository.upload], since
/// there is nothing server-side to catch it (see `UploadsResource`'s own
/// doc comment) and spending a presign round trip on a file that will
/// never be let through is pure waste.
class MediaTooLarge implements Exception {
  const MediaTooLarge(this.maxBytes);

  final int maxBytes;
}

/// Maps whatever [UploadsRepository.upload] (or the [MediaTooLarge] check
/// ahead of it) rejected with onto one sentence a caller can show as-is —
/// the same "typed failure in, one honest sentence out" shape every other
/// screen's own `_messageFor` follows, pulled out here once because four
/// call sites (listing photos/video, two avatar controls) need the exact
/// same mapping rather than four near-copies. [MediaPickerException] (the
/// OS picker itself failed — denied permission, no camera) already carries
/// its own user-facing message; a caller should show that directly rather
/// than routing it through this function.
///
/// **Deliberately left un-localized by this pass, and why.** Every other
/// string in this file's owning group (`shared/`) got an [AppLocalizations]
/// lookup; this one didn't, because `lib/features/listing_editor/widgets/
/// form/photos_step.dart` — outside this pass's ownership — calls this
/// function positionally with one argument
/// (`describeUploadError(MediaTooLarge(maxBytes))`). Adding a required
/// [AppLocalizations] parameter (the pattern every other non-widget helper
/// in this group uses, e.g. `Formatters.rooms`'s *optional* one doesn't
/// apply here since there is no meaningful un-localized fallback shape
/// that isn't just... this) would either break that call site outright, or
/// force a second, forked copy of the same four sentences under a new name
/// with no way to guarantee the two never drift. Whichever group extracts
/// `listing_editor/` should migrate this function's signature and its own
/// call site together in one change — see this run's report for the full
/// reasoning.
String describeUploadError(Object error) {
  if (error is MediaTooLarge) {
    final mb = (error.maxBytes / (1024 * 1024)).round();
    return 'That file is too large. The limit is ${mb}MB.';
  }
  if (error is ApiErrorException) {
    if (error.code == ApiErrorCode.validation) {
      return "That file type isn't supported.";
    }
    return error.message;
  }
  if (error is NetworkException) {
    return 'No connection. Check your network and try again.';
  }
  return "Couldn't upload. Please try again.";
}
