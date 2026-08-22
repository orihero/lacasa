/// The real, `UploadsResource`-backed [UploadsRepository] — see that
/// interface's own doc comment for why there is no fixture counterpart.
library;

import 'package:dio/dio.dart';

import '../../api/api.dart';
import '../platform/media_picker.dart';
import 'uploads_repository.dart';

class LiveUploadsRepository implements UploadsRepository {
  const LiveUploadsRepository(this._uploads);

  final UploadsResource _uploads;

  @override
  UploadHandle upload({
    required PickedMedia media,
    required String scope,
    void Function(double progress)? onProgress,
  }) {
    // Owned entirely inside this call — never exposed on [UploadHandle]
    // itself, so [UploadsRepository]'s public shape stays free of a
    // dio-specific type (the same reason `link_launcher.dart`/
    // `media_picker.dart` never let a plugin type leak past their own
    // seam).
    final cancelToken = CancelToken();
    return UploadHandle(
      result: _run(media, scope, onProgress, cancelToken),
      cancel: cancelToken.cancel,
    );
  }

  Future<String> _run(
    PickedMedia media,
    String scope,
    void Function(double progress)? onProgress,
    CancelToken cancelToken,
  ) async {
    final presigned = await _uploads.presign(
      fileName: media.fileName,
      contentType: media.mimeType,
      scope: scope,
    );
    await _uploads.putBytes(
      uploadUrl: presigned.uploadUrl,
      bytes: media.bytes,
      contentType: media.mimeType,
      cancelToken: cancelToken,
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    return presigned.publicUrl;
  }
}
