/// Decodes the legacy Firestore-shaped timestamp La Casa's API still sends
/// for `Ad.createdAt`/`Ad.updatedAt`: `{ "seconds": number }`, NOT an
/// ISO-8601 string. Calling `DateTime.parse` on one of these fields is a
/// silent-looking bug (it throws a [FormatException] at runtime) — go
/// through this helper instead.
library;

DateTime dateTimeFromWireTimestamp(Map<String, dynamic> json) {
  final seconds = json['seconds'];
  final secondsNum = switch (seconds) {
    num n => n,
    String s => num.tryParse(s) ?? 0,
    _ => 0,
  };
  return DateTime.fromMillisecondsSinceEpoch(
    (secondsNum * 1000).round(),
    isUtc: true,
  );
}
