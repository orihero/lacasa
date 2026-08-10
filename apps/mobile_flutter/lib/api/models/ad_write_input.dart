/// The `POST /api/ads` / `PATCH /api/ads/:id` request body
/// (`adInputSchema`, `packages/domain/src/schemas/ad.ts`, plus the
/// lat/lng/tour3dLink rules `adService.js` enforces outside that schema —
/// see the API contract survey's "Ad create/update body fields" table for
/// the full field-by-field wire contract this mirrors).
///
/// One class serves both `create` and `update` — the server itself treats
/// every field as optional on both verbs (nothing is schema-required; a
/// screen's own "Title is required" style validation is a client-side UX
/// rule, not a server contract) — so there is no separate "CreateAdInput"/
/// "UpdateAdInput" pair to keep in sync. Every field is wrapped in
/// [OptionalField] (`optional_field.dart`) because `PATCH` is genuinely
/// partial: a field the caller doesn't mention must be **left out of the
/// JSON body**, not sent as `null`, or the server would wrongly clear it.
///
/// Deliberately a typed class rather than a raw `Map` built at the call
/// site (contrast `UsersResource.updateMe`'s call-site map, which works
/// because none of its fields need omit-vs-clear semantics): at ~25 fields
/// with real omit-vs-null semantics on more than half of them, a hand-built
/// map at every call site would re-derive the same sentinel logic five
/// times across the Work build's six features. This keeps it in one place.
library;

import 'enums.dart';
import 'optional_field.dart';

class AdWriteInput {
  final OptionalField<String>? title;
  final OptionalField<String>? city;
  final OptionalField<String>? district;

  /// `""` is normalized to `null` server-side — pass `OptionalField(null)`
  /// to clear, never `OptionalField('')`.
  final OptionalField<String?>? address;
  final OptionalField<String?>? reference;
  final OptionalField<AdType>? type;
  final OptionalField<AdCategory>? category;
  final OptionalField<Repairment?>? repairment;
  final OptionalField<int?>? rooms;
  final OptionalField<double?>? area;
  final OptionalField<int?>? storey;
  final OptionalField<int?>? floors;
  final OptionalField<Furniture?>? furniture;
  final OptionalField<String?>? hashtags;
  final OptionalField<double>? price;
  final OptionalField<CurrencyCode>? priceType;
  final OptionalField<AdStage>? stage;
  final OptionalField<String?>? description;
  final OptionalField<List<String>>? nearPlacesList;

  /// Raw passthrough, matching `Ad.optionList`'s own untyped read side —
  /// each entry `{id?, key?, value?}`.
  final OptionalField<List<Map<String, Object?>>>? optionList;
  final OptionalField<bool>? active;

  /// Server enforces "set together, or both left null" — see this file's
  /// doc comment. This client does not re-validate that pairing; a
  /// mismatched pair is a 400 the caller surfaces like any other
  /// [ApiErrorException] with `code: validation`.
  final OptionalField<double?>? lat;
  final OptionalField<double?>? lng;

  /// Must be an absolute `http(s)` URL when non-null — enforced
  /// server-side (400 `validation` otherwise), not re-validated here.
  final OptionalField<String?>? tour3dLink;

  /// Flat, already-uploaded URL strings — see `UploadsResource.presign`
  /// for how a photo/video gets a URL before it can go in this list. No
  /// server-side count/size limit; the "5 photos / 5MB / 70MB video" rule
  /// in SCREENS.md §26 is UI-only (see the API contract survey).
  final OptionalField<List<String>>? photos;

  const AdWriteInput({
    this.title,
    this.city,
    this.district,
    this.address,
    this.reference,
    this.type,
    this.category,
    this.repairment,
    this.rooms,
    this.area,
    this.storey,
    this.floors,
    this.furniture,
    this.hashtags,
    this.price,
    this.priceType,
    this.stage,
    this.description,
    this.nearPlacesList,
    this.optionList,
    this.active,
    this.lat,
    this.lng,
    this.tour3dLink,
    this.photos,
  });

  Map<String, Object?> toJson() => {
    ...optionalEntry('title', title),
    ...optionalEntry('city', city),
    ...optionalEntry('district', district),
    ...optionalEntry('address', address),
    ...optionalEntry('reference', reference),
    ...optionalEntry('type', _wireEnum(type, (v) => v.wire)),
    ...optionalEntry('category', _wireEnum(category, (v) => v.wire)),
    ...optionalEntry('repairment', _wireEnumOrNull(repairment, (v) => v.wire)),
    ...optionalEntry('rooms', rooms),
    ...optionalEntry('area', area),
    ...optionalEntry('storey', storey),
    ...optionalEntry('floors', floors),
    ...optionalEntry('furniture', _wireEnumOrNull(furniture, (v) => v.wire)),
    ...optionalEntry('hashtags', hashtags),
    ...optionalEntry('price', price),
    ...optionalEntry('priceType', _wireEnum(priceType, (v) => v.wire)),
    ...optionalEntry('stage', _wireEnum(stage, (v) => v.wire)),
    ...optionalEntry('description', description),
    ...optionalEntry('nearPlacesList', nearPlacesList),
    ...optionalEntry('optionList', optionList),
    ...optionalEntry('active', active),
    ...optionalEntry('lat', lat),
    ...optionalEntry('lng', lng),
    ...optionalEntry('tour3dLink', tour3dLink),
    ...optionalEntry('photos', photos),
  };
}

/// Re-wraps a non-nullable-enum [OptionalField] as its `.wire` string —
/// `null` (omit) stays `null`; a present field always has a value to
/// convert, so this never needs to handle a null inner value.
OptionalField<String>? _wireEnum<E>(
  OptionalField<E>? field,
  String Function(E) wire,
) {
  if (field == null) return null;
  return OptionalField(wire(field.value));
}

/// Same as [_wireEnum], but for a nullable-enum field (`repairment`,
/// `furniture`) — an omitted field stays omitted, an explicit-clear field
/// (`OptionalField(null)`) stays an explicit JSON `null`, and only a
/// present, non-null value is actually converted through [wire].
OptionalField<String?>? _wireEnumOrNull<E>(
  OptionalField<E?>? field,
  String Function(E) wire,
) {
  if (field == null) return null;
  final value = field.value;
  return OptionalField(value == null ? null : wire(value));
}
