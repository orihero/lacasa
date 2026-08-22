/// Pure, unit-tested formatting for `photo-gallery`'s on-screen counter.
/// Not part of `lib/shared/formatters/formatters.dart` — that file is
/// scoped to SCREENS.md's global preamble rules (price/date/phone/id
/// badge); the `{n}/{total}` page counter is specific to this one screen.
library;

abstract final class GalleryFormatters {
  /// `{n}/{total}` counter, 1-indexed per SCREENS.md §3.8 — e.g. index `0`
  /// of a 5-slide gallery reads `"1/5"`. `total <= 0` (the empty-gallery
  /// case) returns `"0/0"` rather than dividing by a count that doesn't
  /// exist; `PhotoGalleryScreen` doesn't actually render this widget when
  /// the gallery is empty, but the formatter stays total-safe regardless.
  static String pageCounter({required int index, required int total}) {
    if (total <= 0) return '0/0';
    return '${index + 1}/$total';
  }
}
