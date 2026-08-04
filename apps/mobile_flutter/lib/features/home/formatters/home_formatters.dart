/// Price formatting for the Home feed's listing cards — the literal rule
/// from SCREENS.md's top-of-file "Formatting conventions" block (ahead of
/// §1, not part of §4's seed data): `$ {price}` for a sale, `$ {price}/month`
/// for a rent, both with thousands separators and no decimals.
///
/// Scoped to `lib/features/home/` for this build (per its ownership),
/// exactly like the build spec's own note that `Formatters.date()`/
/// `Formatters.phone()` belong to whichever later screen actually needs
/// them — nothing on `home-feed` renders a date or a phone number.
library;

import '../../../api/api.dart';

abstract final class HomeFormatters {
  /// The grouped-integer body of the price, with no `$` and no `/month`
  /// suffix — e.g. `78,000`. [PricePill] (`widgets/price_pill.dart`) is
  /// responsible for the `$` prefix and styling the `/month` suffix
  /// smaller/lighter; this stays a plain string so it's trivially testable.
  static String groupedPrice(Ad ad) => _groupInteger(ad.price);

  static String _groupInteger(num value) {
    // Seed data has no decimals; defensively round if the API ever returns
    // one (not documented either way — a reasonable default, per the build
    // spec's own note on this point).
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return rounded < 0 ? '-$buffer' : buffer.toString();
  }
}
