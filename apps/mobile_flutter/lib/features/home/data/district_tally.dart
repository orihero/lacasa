/// One district plus how many active listings the browse feed carries for
/// it — the model behind Home's Top Districts rail
/// (`widgets/top_districts_rail.dart`).
///
/// Deliberately **not** built on `packages/domain`'s `regions.json`
/// vocabulary. That file is a picker vocabulary (`{id, region_id, name}`,
/// no popularity, no ordering) and its spellings do not match what real ad
/// rows carry — the seeded corpus writes `Sirgali tumani`/`Bektemir
/// tumani`/`Mirzo Ulugʻbek tumani` where `regions.json` says `Sergeli
/// tumani`/`Bektimer tumani`/`M.Ulug'bek tumani`, and `GET /ads?district=`
/// matches on exact equality (`adService.js`). Joining the two would drop
/// roughly a third of the corpus and print counts of zero next to
/// districts that genuinely have listings. So [name] is the verbatim
/// `Ad.district` string, which is both what the feed reports and what the
/// search request can be filtered by.
library;

class DistrictTally {
  const DistrictTally({required this.name, required this.count});

  /// The verbatim `Ad.district` value — the exact string
  /// `GET /ads?district=` matches on. Free text server-side, so it is
  /// rendered as-is rather than localized; every other district rendering
  /// in the app (`compact_listing_card.dart`, `full_listing_card.dart`,
  /// `row_listing_card.dart`) already does the same.
  final String name;

  /// How many ads in the feed carry [name].
  final int count;
}
