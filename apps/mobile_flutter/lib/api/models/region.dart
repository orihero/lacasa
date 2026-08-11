/// `GET /api/regions`'s vocabulary shapes — Uzbekistan's 14 regions and 203
/// districts, static reference data served over HTTP from
/// `@lacasa/domain/data/regions` (see `packages/domain/src/data/regions.ts`
/// for why this exists as a route at all — apps/web and apps/api import the
/// same data directly at build time; this client is the one consumer that
/// can't). Read-only: nothing under `lib/api/` writes a region/district
/// back — the vocabulary is fixed reference data, not user content.
library;

class Region {
  final int id;
  final String name;

  const Region({required this.id, required this.name});

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class District {
  final int id;

  /// The wire key is `region_id` (snake_case, unlike every other field this
  /// client decodes) — `regions.json`'s own shape, passed through
  /// unmodified by `routes/regions.js` rather than remapped to camelCase.
  final int regionId;
  final String name;

  const District({
    required this.id,
    required this.regionId,
    required this.name,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: (json['id'] as num?)?.toInt() ?? 0,
      regionId: (json['region_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// The whole `{ regions, districts }` envelope — the same shape whether or
/// not [RegionsResource.fetch]'s `regionId` narrowed it (see that method's
/// doc comment), so this is the one parser for both cases.
class RegionsData {
  final List<Region> regions;
  final List<District> districts;

  const RegionsData({required this.regions, required this.districts});

  factory RegionsData.fromJson(Map<String, dynamic> json) {
    return RegionsData(
      regions: (json['regions'] as List<dynamic>? ?? const [])
          .map((e) => Region.fromJson(e as Map<String, dynamic>))
          .toList(),
      districts: (json['districts'] as List<dynamic>? ?? const [])
          .map((e) => District.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
