/// The honest "this build can't actually pick a file" seam for every photo/
/// video/avatar control in the Work build — `create-listing` (§26) and
/// `edit-listing` (§27)'s photo pickers, `add-coworker` (§37) and
/// `coworker-detail` (§36)'s avatar uploaders.
///
/// **Why this exists instead of `image_picker`.** There is no
/// `image_picker` (or `file_picker`) dependency in this app, and this
/// foundation task deliberately does not add one — see
/// `WORK_TAB_CONTRACT.md`'s dependency-decision log for the full reasoning.
/// Short version: the exact same call was already made for `edit-profile`'s
/// avatar control (`features/edit_profile/widgets/edit_profile_screen.dart`,
/// see its doc comment) and for camera/photo-library permissions
/// (`features/permissions/data/permission_gateway.dart`'s
/// [UnavailablePermissionGateway]) — adding a real picker without the
/// native `Info.plist`/`AndroidManifest.xml` declarations it needs is worse
/// than not shipping it, and this build has neither. This file is that same
/// decision, promoted to `shared/` because four Work screens need it rather
/// than one.
///
/// [kMediaUploadUnavailableMessage] intentionally repeats `edit-profile`'s
/// own wording verbatim rather than drifting to a Work-specific phrasing —
/// one honest sentence, used everywhere a picker would have opened.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// The one sentence this build can honestly say about any file picker —
/// see this file's doc comment. Shared by every caption/toast that needs
/// it so none of them drift from `edit-profile`'s original wording.
const String kMediaUploadUnavailableMessage =
    "Photo upload isn't available in this build yet.";

/// A small caption + icon, meant to sit directly under a photo/avatar
/// control that cannot open a real picker. [label] lets a caller say
/// "Video upload"/"Avatar upload" instead of the default "Photo upload" —
/// the rest of the sentence stays fixed.
class MediaUploadUnavailableNotice extends StatelessWidget {
  const MediaUploadUnavailableNotice({super.key, this.label = 'Photo upload'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: colors.faint),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            "$label isn't available in this build yet.",
            style: type.caption.copyWith(color: colors.faint),
          ),
        ),
      ],
    );
  }
}

/// The tap-triggered half of the same seam — a caller wires this to
/// whatever tap target would have opened a real picker (an "Add photo"
/// tile, the avatar itself), so tapping produces an honest answer instead
/// of silence, matching `edit-profile`'s own tap behavior.
void showMediaUploadUnavailableToast(BuildContext context, {String label = 'Photo upload'}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text("$label isn't available in this build yet.")),
    );
}
