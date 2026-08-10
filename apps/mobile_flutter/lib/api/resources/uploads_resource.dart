/// `/api/uploads/presign` — the two-step upload flow behind every photo/
/// video/avatar field in the Work build (`create-listing`, `edit-listing`,
/// `add-coworker`, `coworker-detail`). See the API contract survey's
/// "End-to-end flow" for the full picture; summarized:
///
/// 1. [presign] — authenticated (any signed-in role, no `loadCurrentUser`
///    role check), returns a MinIO presigned PUT URL valid 10 minutes.
/// 2. [putBytes] — an **unauthenticated raw HTTP PUT** of the file bytes to
///    that URL. This is deliberately NOT routed through [ApiClient]/
///    [Transport]: those always attach a `Bearer` token (wrong here — auth
///    is baked into the presigned URL's own signature) and always decode
///    the response as JSON (wrong here — MinIO's PUT response body is
///    empty). A second, bare `Dio` instance is used instead, scoped to
///    exactly this one call.
/// 3. The caller then sends the presign response's `publicUrl` (not
///    `uploadUrl`) back to the API as the `photos[]`/`avatar` string on a
///    subsequent `POST`/`PATCH` — `objectKey` is server bookkeeping only,
///    never sent back by this client.
///
/// **No client-side size cap is enforced anywhere server-side** — the "5MB
/// photo / 70MB video" rule in SCREENS.md §26 is a UI-only guard this
/// client does not implement; a caller that wants it must check
/// `bytes.length` itself before calling [putBytes].
library;

import 'package:dio/dio.dart';

import '../api_client.dart';
import '../api_exception.dart';
import '../models/api_error_body.dart';
import '../models/upload.dart';

class UploadsResource {
  final ApiClient _client;

  const UploadsResource(this._client);

  /// `POST /uploads/presign`. [contentType] must match `^(image|video)/`
  /// (400 `validation` otherwise); [scope] is `"ads"` or `"avatars"`.
  Future<PresignResult> presign({
    required String fileName,
    required String contentType,
    required String scope,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/uploads/presign',
      body: {
        'fileName': fileName,
        'contentType': contentType,
        'scope': scope,
      },
    );
    return PresignResult.fromJson(json as Map<String, dynamic>);
  }

  /// Raw `PUT <uploadUrl>` of [bytes] — the second half of the presign
  /// flow, see this file's doc comment. [contentType] should match what
  /// was declared to [presign] (the server does not re-verify it against
  /// the actual PUT, but MinIO itself may reject a mismatch depending on
  /// bucket policy). Throws [NetworkException] for a connection failure;
  /// a non-2xx response from MinIO throws [ApiErrorException] with
  /// `code: unknown` (MinIO's own error body isn't this API's `{error:
  /// {code,message}}` envelope, so it can't decode into a more specific
  /// code) and the real MinIO status code.
  Future<void> putBytes({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
  }) async {
    final dio = Dio()
      ..options.validateStatus = (_) => true;
    final Response<dynamic> response;
    try {
      response = await dio.putUri<dynamic>(
        Uri.parse(uploadUrl),
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            Headers.contentLengthHeader: bytes.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw NetworkException('Could not upload the file', cause: e);
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiErrorException(
        body: ApiErrorBody(
          code: ApiErrorCode.unknown,
          message: 'Upload failed ($statusCode)',
        ),
        statusCode: statusCode,
      );
    }
  }
}
