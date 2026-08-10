/// `POST /api/uploads/presign` response — see `resources/uploads_resource.dart`
/// for the full presign-then-PUT flow this is one half of.
library;

class PresignResult {
  final String uploadUrl;
  final String objectKey;
  final String publicUrl;

  const PresignResult({
    required this.uploadUrl,
    required this.objectKey,
    required this.publicUrl,
  });

  factory PresignResult.fromJson(Map<String, dynamic> json) {
    return PresignResult(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      objectKey: json['objectKey'] as String? ?? '',
      publicUrl: json['publicUrl'] as String? ?? '',
    );
  }
}
