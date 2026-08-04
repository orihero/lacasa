/// The `Ad` wire shape (`apps/api/src/lib/adsSerializer.js#serializeAd`) —
/// the truth for every ad-returning endpoint: `GET /ads`, `GET /ads/:id`,
/// `GET /my/ads`, and (spread, plus `saved: true`) each row of
/// `GET /saved-ads`. Read-only: this client only lists/reads ads, so there
/// is no `toJson` — nothing under `lib/api/` posts an `Ad` back.
library;

import 'enums.dart';
import 'wire_timestamp.dart';

/// One entry of `Ad.media` — the full ordered photo/video set. `Ad.photos`
/// stays a flat `List<String>` of image URLs only (unchanged, still what
/// every list/grid screen renders); `media` is additive, for a future
/// carousel that needs to tell photos and video apart.
class AdMedia {
  final String url;
  final AdMediaType mediaType;
  final int position;

  const AdMedia({
    required this.url,
    required this.mediaType,
    required this.position,
  });

  factory AdMedia.fromJson(Map<String, dynamic> json) {
    return AdMedia(
      url: json['url'] as String? ?? '',
      mediaType: AdMediaType.fromWire(json['mediaType'] as String?),
      position: _toInt(json['position']) ?? 0,
    );
  }
}

/// Ports `packages/domain/src/ads/pricePerSqm.ts#computePricePerSqm` field
/// for field, rounding rule included, so this client's figure never
/// disagrees with web's. `pricePerSqm` is NOT a wire field — see [Ad.pricePerSqm].
int? computePricePerSqm(num price, num? area) {
  if (area == null) return null;
  if (!area.isFinite || !price.isFinite) return null;
  if (area <= 0) return null;
  return (price / area).round();
}

class Ad {
  final String id;
  final String title;
  final String city;
  final String district;
  final String? address;
  final String? reference;
  final AdType type;
  final AdCategory category;

  /// Absent (not `null`) on the wire when the ad has no repair state —
  /// modeled as a true `null` here whether the key was omitted or sent
  /// explicitly as JSON `null`.
  final Repairment? repairment;
  final int? rooms;
  final double? area;
  final int? storey;
  final int? floors;

  /// Same key-omission caveat as [repairment].
  final Furniture? furniture;
  final String? hashtags;
  final double price;
  final CurrencyCode priceType;
  final AdStage stage;
  final String? description;
  final List<String> nearPlacesList;

  /// Raw `Json` passthrough of `Ad.options` — write-side shape is
  /// `{id?, key?, value?}[]` but this is read-side passthrough, not
  /// re-validated, so it stays untyped here too.
  final Object? optionList;
  final bool active;

  /// Listing-detail map pin. Always present on the wire (never omitted),
  /// both-null or both-non-null (enforced server-side) — `lat != null &&
  /// lng != null` is the reliable "has a pin" check. A pin at latitude 0 is
  /// falsy-looking but valid; don't test truthiness.
  final double? lat;
  final double? lng;

  /// Guaranteed absolute http(s) on write, but NOT re-validated on read.
  final String? tour3dLink;
  final String agentId;

  /// Empty string (not `null`) when the ad has no coworker.
  final String coworkerId;

  /// Flat photo URLs only, filtered server-side to `mediaType === "PHOTO"`.
  final List<String> photos;
  final List<AdMedia> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ad({
    required this.id,
    required this.title,
    required this.city,
    required this.district,
    required this.address,
    required this.reference,
    required this.type,
    required this.category,
    required this.repairment,
    required this.rooms,
    required this.area,
    required this.storey,
    required this.floors,
    required this.furniture,
    required this.hashtags,
    required this.price,
    required this.priceType,
    required this.stage,
    required this.description,
    required this.nearPlacesList,
    required this.optionList,
    required this.active,
    required this.lat,
    required this.lng,
    required this.tour3dLink,
    required this.agentId,
    required this.coworkerId,
    required this.photos,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Price per square metre for the listing-detail fact rail. NOT a wire
  /// field — computed here the same way web computes it, so the two never
  /// disagree. `null` whenever [area] is `null` or non-positive.
  int? get pricePerSqm => computePricePerSqm(price, area);

  /// The reliable "has a map pin" check — see [lat]'s doc comment.
  bool get hasPin => lat != null && lng != null;

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      address: json['address'] as String?,
      reference: json['reference'] as String?,
      type: AdType.fromWire(json['type'] as String?),
      category: AdCategory.fromWire(json['category'] as String?),
      repairment: _optionalEnum(json, 'repairment', Repairment.fromWire),
      rooms: _toInt(json['rooms']),
      area: _toDouble(json['area']),
      storey: _toInt(json['storey']),
      floors: _toInt(json['floors']),
      furniture: _optionalEnum(json, 'furniture', Furniture.fromWire),
      hashtags: json['hashtags'] as String?,
      price: _toDouble(json['price']) ?? 0,
      priceType: CurrencyCode.fromWire(json['priceType'] as String?),
      stage: AdStage.fromWire(json['stage'] as String?),
      description: json['description'] as String?,
      nearPlacesList:
          (json['nearPlacesList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      optionList: json['optionList'],
      active: json['active'] as bool? ?? false,
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      tour3dLink: json['tour3dLink'] as String?,
      agentId: json['agentId'] as String? ?? '',
      coworkerId: json['coworkerId'] as String? ?? '',
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      media:
          (json['media'] as List<dynamic>?)
              ?.map((e) => AdMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['createdAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: json['updatedAt'] is Map<String, dynamic>
          ? dateTimeFromWireTimestamp(json['updatedAt'] as Map<String, dynamic>)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// Reads an optional enum field that the server omits entirely (not sends
/// as `null`) when unset — `null` either way the key is absent or explicitly
/// `null`, so a strict codec never trips over the omission.
T? _optionalEnum<T>(
  Map<String, dynamic> json,
  String key,
  T Function(String?) fromWire,
) {
  if (!json.containsKey(key) || json[key] == null) return null;
  return fromWire(json[key] as String?);
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
