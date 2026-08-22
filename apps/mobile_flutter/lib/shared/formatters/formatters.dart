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
import '../../l10n/generated/app_localizations.dart';

abstract final class Formatters {
  /// The grouped-integer body of a price, with no `$` and no per-month
  /// suffix — e.g. `78,000`. Kept separate from [price] because
  /// `PricePill` (`shared/widgets/price_pill.dart`) needs the bare number
  /// to style the per-month suffix smaller/lighter than the rest of the
  /// string; this stays a plain string so both call sites — and this
  /// file's own tests — stay trivial.
  static String groupedPrice(Ad ad) => groupedNumber(ad.price);

  /// [groupedPrice]'s rule applied to a bare number, for the figures that
  /// need the identical thousands grouping without being an [Ad]'s own
  /// price — currently `listing-detail`'s price-per-m² footer. Exposed as
  /// its own entry point rather than having such callers fake an [Ad]:
  /// grouping digits was never an ad-shaped operation, [groupedPrice] just
  /// happened to be the first caller.
  static String groupedNumber(num value) => _groupInteger(value);

  /// The full price string per SCREENS.md's rule: `$ {price}` for a sale
  /// ad, `$ {price}` + the localized per-month suffix for a rent ad,
  /// thousands grouped, no decimals —
  /// but that literal rule only ever covered USD. SCREENS.md's preamble
  /// says the `$` prefix "consolidates the web app's three inconsistent
  /// formats — `$`, `y.e`, `{priceType}` — into one rule for mobile"; it
  /// was never a claim that every ad is USD, just that mobile shouldn't
  /// pick its symbol per-screen the way web did. The live API returns
  /// `priceType: "uzs"` for a real fraction of ads (7 of 37 seeded), and a
  /// `$` prefix on those misstates the price by roughly 13x (800,000 so'm
  /// read as $800,000) — that's the bug this branches on [Ad.priceType] to
  /// fix. USD keeps the spec's `$ {price}` prefix unchanged; UZS uses the
  /// suffix convention the listing-editor's own live price preview already
  /// established (`listingEditorPriceTypeUzsOption` = "so'm",
  /// `{amount} {currency}` — see `_PricePreview` in
  /// `features/listing_editor/widgets/form/details_step.dart`) rather than
  /// inventing a second one. [CurrencyCode.unknown] falls back to the `$`
  /// prefix, matching this method's pre-fix behaviour for every ad — a
  /// currency the wire didn't say is not grounds to guess "so'm" over the
  /// previous always-USD assumption.
  ///
  /// Use this wherever a price is needed as plain text with no glass
  /// styling (a share-sheet body, a static price row) — `PricePill` does
  /// not call this, since it needs the per-month suffix as a separately
  /// styled [TextSpan], and builds the same USD/UZS branch itself so it can
  /// pass a real [l10n] (it always has a [BuildContext]).
  ///
  /// **[l10n] now carries two strings, not one.** The rental suffix used to
  /// be a hardcoded English `'/month'` glued on below, so every ru/uz rental
  /// price in the app read `800 000 so'm/month` — the currency word resolved
  /// through [AppLocalizations] on the line directly above while the period
  /// beside it stayed English, mixing two scripts inside one price. It now
  /// reads `sharedPricePerMonthSuffix` (`/мес`, `/oyiga`) on exactly the
  /// same optional-with-fallback terms the UZS branch already used.
  ///
  /// [l10n] stays optional for the same reason [rooms]'s is: this method is
  /// called from six widgets across `map_view/` and `listing_detail/`, all
  /// of them directories a single change cannot own, so a *required*
  /// parameter would be a flag-day edit across feature boundaries. Omitting
  /// it is a real regression now rather than a cosmetic one, though — the
  /// fallback is English on both halves — so every call site that *can*
  /// reach a [BuildContext] should pass it. Verified against the current
  /// tree: all six sites sit inside a `build(BuildContext context)` and can,
  /// which is why the older note here about call sites with "no
  /// BuildContext on hand" no longer describes this file's callers.
  static String price(Ad ad, {AppLocalizations? l10n}) {
    final body = switch (ad.priceType) {
      CurrencyCode.uzs =>
        '${groupedPrice(ad)} ${l10n?.listingEditorPriceTypeUzsOption ?? "so'm"}',
      CurrencyCode.usd || CurrencyCode.unknown => '\$${groupedPrice(ad)}',
    };
    if (ad.category != AdCategory.rent) return body;
    // No separator: the suffix is the abbreviated classifieds form in all
    // three locales and glues straight onto the digits — `$900/month`,
    // `800,000 so'm/мес`. See `lib/l10n/GLOSSARY.md`'s "per month" row.
    return '$body${l10n?.sharedPricePerMonthSuffix ?? '/month'}';
  }

  /// A price abbreviated to fit somewhere there is no room for the grouped
  /// form — `$78k`, `$1.2k`, `$350` — with **no** per-month suffix and no
  /// currency word for UZS. `map-view`'s pins are the caller this exists
  /// for (`.map__pin` is 30px tall with `0 11px` of padding; the full
  /// `$1,200,000/month` does not fit and the mockup's pins read `$120k`).
  ///
  /// Deliberately not a variant of [price]: that method is the honest,
  /// complete string (share text, detail hero, pin semantics label) and
  /// must stay lossless. This one rounds — 1,250,000 renders `$1.2M`, not
  /// the exact figure — so it belongs only where the exact figure is one
  /// tap away. Callers that need both (map pins: abbreviated label,
  /// full-price semantics) should use [price] for the accessible string.
  ///
  /// Branches on [Ad.priceType] for the same reason [price] does — a `$`
  /// in front of an 800,000 so'm ad misstates it by ~13x — so a UZS ad
  /// abbreviates to `800k so'm`, keeping the suffix convention [price]
  /// established. [l10n] is optional on the same terms as [price]'s.
  static String abbreviatedPrice(Ad ad, {AppLocalizations? l10n}) {
    final value = ad.price.abs().round();
    final sign = ad.price < 0 ? '-' : '';
    final String magnitude;
    if (value >= 1000000) {
      magnitude = '${_trimTenth(value / 1000000)}M';
    } else if (value >= 1000) {
      magnitude = '${_trimTenth(value / 1000)}k';
    } else {
      magnitude = '$value';
    }
    return switch (ad.priceType) {
      CurrencyCode.uzs =>
        '$sign$magnitude ${l10n?.listingEditorPriceTypeUzsOption ?? "so'm"}',
      CurrencyCode.usd || CurrencyCode.unknown => '$sign\$$magnitude',
    };
  }

  /// One decimal place, with a whole value's `.0` dropped — `1.2`, `78`.
  static String _trimTenth(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
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

  // ---- Size/stat rules -------------------------------------------------
  //
  // SCREENS.md writes these as `{rooms} room`, `{area} m²`,
  // `{storey}/{floors}` in three separate places (the shared listing card
  // §2's preamble, `map-view`'s pin preview, and `listing-detail`'s Sizes
  // section). They started as private helpers duplicated in
  // `FullListingCard` and `CompactListingCard`; `listing-detail` needed the
  // identical strings, and a third copy is where a rule stops being a rule.
  //
  // One deliberate divergence from the spec's literal text, carried
  // forward from those cards rather than introduced here: the spec's
  // `{rooms} room` is pluralized ("3 rooms", not "3 room"). Rendering
  // "3 room" would read as a typo to every user; the spec is writing a
  // template, not fixing English.

  /// `3 rooms` / `1 room`, or `null` when the ad states no room count —
  /// `null` rather than `0 rooms`, so a caller can omit the segment
  /// entirely instead of asserting something the wire never said.
  ///
  /// **[l10n], and why it's optional.** This is the single most-called
  /// pluralized string in the app (every listing card's spec line, several
  /// screens' Sizes sections) — call sites span all six feature groups this
  /// codebase was built in, most of which don't have a [BuildContext] to
  /// hand at the point they call this. Threading a *required*
  /// [AppLocalizations] through would mean changing this method's signature
  /// and every one of those call sites in the same change, across features
  /// this pass does not own. So [l10n] is optional: pass it (from
  /// `AppLocalizations.of(context)`) wherever a context is available — see
  /// [FullListingCard]/[CompactListingCard] — for a correctly localized,
  /// ICU-pluralized result (`AppLocalizations.sharedRoomsCount`); omit it
  /// and this falls back to the original English-only concatenation, which
  /// callers not yet passing a context still get byte-identically. Every
  /// caller migrating to pass [l10n] closes this gap one feature at a time
  /// without a single flag-day rewrite across six ownership boundaries.
  static String? rooms(int? rooms, {AppLocalizations? l10n}) {
    if (rooms == null) return null;
    if (l10n != null) return l10n.sharedRoomsCount(rooms);
    return '$rooms room${rooms == 1 ? '' : 's'}';
  }

  /// `65 m²`, or `null` when the ad states no area. Trailing `.0` is
  /// trimmed — the wire carries area as a double, and "65.0 m²" is noise.
  static String? area(double? area) {
    if (area == null) return null;
    return '${trimNum(area)} m²';
  }

  /// `4/9`, or `null` unless the ad states **both** storey and floors —
  /// "4/" or "/9" is worse than saying nothing.
  static String? floor(int? storey, int? floors) {
    if (storey == null || floors == null) return null;
    return '$storey/$floors';
  }

  /// The `·`-joined stat line under a listing card's title —
  /// `3 rooms · 65 m² · 4/9`. Whichever parts the ad doesn't state are
  /// dropped, separators included, so a sparse ad never renders a dangling
  /// `·`. Pass [includeFloor] as `false` for the compact card, which has no
  /// room for it (see `CompactListingCard`'s own doc comment). [l10n] is
  /// forwarded to [rooms] unchanged — see that method's doc comment for why
  /// it's optional.
  static String statLine(
    Ad ad, {
    bool includeFloor = true,
    AppLocalizations? l10n,
  }) {
    return [
      rooms(ad.rooms, l10n: l10n),
      area(ad.area),
      if (includeFloor) floor(ad.storey, ad.floors),
    ].whereType<String>().join(' · ');
  }

  /// Renders a whole-valued double without its `.0`. Public because
  /// `listing-detail`'s Sizes rows need the bare number in a context
  /// [area] already suffixes.
  static String trimNum(double value) {
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }
}
