/// `GET /api/saved-ads`'s row shape: literally `{ ...Ad, saved: true }` —
/// the full [Ad] shape (`apps/api/src/lib/adsSerializer.js#serializeAd`)
/// plus one extra field. Modeled as composition rather than inheritance so
/// [Ad]'s fromJson logic (the omitted-key/timestamp/enum-fallback handling)
/// isn't duplicated — the wire object is a strict superset of `Ad`, so
/// `Ad.fromJson` on the same map just ignores the extra `saved` key.
library;

import 'ad.dart';

class SavedAd {
  final Ad ad;

  /// Always `true` on the wire — every entry in this list is, by
  /// definition, saved. Kept as a real field (rather than assumed) so a
  /// server bug that ever sent `false` would be visible instead of silently
  /// papered over.
  final bool saved;

  const SavedAd({required this.ad, required this.saved});

  factory SavedAd.fromJson(Map<String, dynamic> json) {
    return SavedAd(
      ad: Ad.fromJson(json),
      saved: json['saved'] as bool? ?? true,
    );
  }
}
