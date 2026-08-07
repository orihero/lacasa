/// The binding formatting rules from SCREENS.md's "Formatting conventions"
/// preamble — the block that sits *ahead of* §1, because it applies to
/// every screen rather than to any one of them. Started life as
/// `features/home/formatters/home_formatters.dart` (price only, the one
/// rule Home itself needed); promoted here once a second feature needed
/// the identical price algorithm and the rest of the preamble (date,
/// phone, id badge) had no home yet at all. One algorithm per rule, tested
/// once here, is the whole point — a feature that needs one of these
/// should import it, never retype the rounding/padding/regex by hand.
library;

import '../../api/api.dart';

abstract final class Formatters {
  /// The grouped-integer body of a price, with no `$` and no `/month`
  /// suffix — e.g. `78,000`. Kept separate from [price] because
  /// `PricePill` (`shared/widgets/price_pill.dart`) needs the bare number
  /// to style the `/month` suffix smaller/lighter than the rest of the
  /// string; this stays a plain string so both call sites — and this
  /// file's own tests — stay trivial.
  static String groupedPrice(Ad ad) => _groupInteger(ad.price);

  /// The full price string per SCREENS.md's rule: `$ {price}` for a sale
  /// ad, `$ {price}/month` for a rent ad, thousands grouped, no decimals.
  /// Use this wherever a price is needed as plain text with no glass
  /// styling (a share-sheet body, a static price row) — `PricePill` does
  /// not call this, since it needs the `/month` suffix as a separately
  /// styled [TextSpan].
  static String price(Ad ad) {
    final body = '\$ ${groupedPrice(ad)}';
    return ad.category == AdCategory.rent ? '$body/month' : body;
  }

  static String _groupInteger(num value) {
    // Seed data has no decimals; defensively round if the API ever returns
    // one (not documented either way — a reasonable default, carried
    // forward from this rule's original home-only home).
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return rounded < 0 ? '-$buffer' : buffer.toString();
  }

  /// `DD.MM.YYYY | HH:MM` — SCREENS.md's date rule, matching web's own
  /// `formatCreatedAt` (en-GB day-month-year order, 24-hour clock). This
  /// only formats; it does not convert time zones — pass whatever
  /// [DateTime] (local or UTC) the caller wants displayed as-is. Ad
  /// timestamps come off the wire via `dateTimeFromWireTimestamp`
  /// (`lib/api/models/wire_timestamp.dart`), never `DateTime.parse` —
  /// that helper's own doc comment explains why.
  static String date(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString().padLeft(4, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy | $hh:$min';
  }

  static final RegExp _uzPhone = RegExp(r'^\+998\d{9}$');

  /// SCREENS.md's Uzbekistan-only phone validity rule: `^\+998\d{9}$`.
  /// Every phone *input* field on every screen should validate against
  /// exactly this pattern (nothing here formats a number for display —
  /// an agent's phone is shown as-received, unvalidated, per the recon
  /// note that display isn't the same contract as input).
  static bool isValidUzPhone(String phone) => _uzPhone.hasMatch(phone);

  /// `#` + the first 5 characters of an ad's id — SCREENS.md's id-badge
  /// rule (`my-listings` and any screen that shows a short listing
  /// reference). Falls back to the whole id if it's shorter than 5
  /// characters rather than throwing a range error — real ids are UUIDs
  /// and never this short, but a fixture/test id might be.
  static String adIdBadge(String id) =>
      '#${id.length <= 5 ? id : id.substring(0, 5)}';
}
