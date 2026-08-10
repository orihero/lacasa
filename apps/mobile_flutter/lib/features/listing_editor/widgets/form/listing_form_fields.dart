/// The mutable field bag shared by `create-listing` (§26) and
/// `edit-listing` (§27) — both screens render (nearly) the same Basics +
/// Details field set (SCREENS.md §26's own text: "Same fields as
/// create-listing steps 1–2"), so one class owns the
/// [TextEditingController]s/enum selections/dynamic lists and both
/// screens' `State`s hold one instance rather than each re-declaring
/// twelve controllers by hand.
///
/// **Required-field errors are quoted verbatim from §26** — this is the
/// one place those six strings live, so `create-listing`'s stepwise
/// validation and `edit-listing`'s single-shot validation can never drift
/// apart on copy.
library;

import 'package:flutter/material.dart';

import '../../../../api/api.dart';
import '../../../../shared/shared.dart';

/// One row of the Additional Info key/value list (§26's "dynamic key/value
/// rows"). Plain mutable holder, not a model class from `lib/api/` — the
/// wire shape (`{key, value}`, `optionList`'s untyped passthrough) only
/// exists as a `Map` at the write boundary; this is the editable form-side
/// representation.
class AdditionalInfoRow {
  AdditionalInfoRow({this.key = '', this.value = ''}) : id = _nextId++;

  static int _nextId = 0;

  /// Stable per-row identity, independent of list position — the widget
  /// keys off this (not the row's index) so deleting a row in the middle of
  /// the list doesn't hand a surviving row's [TextFormField] a stale,
  /// position-matched [Key] and show the wrong text (see
  /// `additional_info_field.dart`'s own doc comment).
  final int id;

  String key;
  String value;
}

class ListingFormFields {
  ListingFormFields()
    : title = TextEditingController(),
      city = TextEditingController(),
      district = TextEditingController(),
      address = TextEditingController(),
      reference = TextEditingController(),
      hashtags = TextEditingController(),
      price = TextEditingController(),
      rooms = TextEditingController(),
      area = TextEditingController(),
      storey = TextEditingController(),
      floors = TextEditingController(),
      description = TextEditingController();

  final TextEditingController title;
  final TextEditingController city;
  final TextEditingController district;
  final TextEditingController address;
  final TextEditingController reference;
  final TextEditingController hashtags;
  final TextEditingController price;
  final TextEditingController rooms;
  final TextEditingController area;
  final TextEditingController storey;
  final TextEditingController floors;
  final TextEditingController description;

  // Every chip-select field states its own §26 default.
  AdType type = AdType.residential;
  AdCategory category = AdCategory.rent;
  Repairment repairment = Repairment.notRepaired;
  Furniture furniture = Furniture.withFurniture;

  // Ruling 7.12 — uzs, not console's usd.
  CurrencyCode priceType = CurrencyCode.uzs;
  AdStage stage = AdStage.active;

  List<String> nearPlaces = [];
  List<AdditionalInfoRow> additionalInfo = [];

  String? titleError;
  String? cityError;
  String? districtError;
  String? addressError;
  String? referenceError;
  String? descriptionError;

  bool get hasAnyError =>
      titleError != null ||
      cityError != null ||
      districtError != null ||
      addressError != null ||
      referenceError != null ||
      descriptionError != null;

  /// `edit-listing`'s prefill — every field seeded from the fetched [Ad],
  /// including its own free-standing enum defaults for a `null` on the
  /// wire (matching this class's own create-time defaults, since the form
  /// never renders an "unset" chip state).
  void seedFrom(Ad ad) {
    title.text = ad.title;
    city.text = ad.city;
    district.text = ad.district;
    address.text = ad.address ?? '';
    reference.text = ad.reference ?? '';
    hashtags.text = ad.hashtags ?? '';
    price.text = ad.price == 0 ? '' : Formatters.trimNum(ad.price);
    rooms.text = ad.rooms?.toString() ?? '';
    area.text = ad.area == null ? '' : Formatters.trimNum(ad.area!);
    storey.text = ad.storey?.toString() ?? '';
    floors.text = ad.floors?.toString() ?? '';
    description.text = ad.description ?? '';
    type = ad.type == AdType.unknown ? AdType.residential : ad.type;
    category = ad.category == AdCategory.unknown ? AdCategory.rent : ad.category;
    repairment = ad.repairment ?? Repairment.notRepaired;
    furniture = ad.furniture ?? Furniture.withFurniture;
    priceType = ad.priceType == CurrencyCode.unknown ? CurrencyCode.uzs : ad.priceType;
    stage = ad.stage == AdStage.unknown ? AdStage.active : ad.stage;
    nearPlaces = List.of(ad.nearPlacesList);
    additionalInfo = _parseOptionList(ad.optionList);
  }

  /// [Ad.optionList] is raw, unvalidated `Json` passthrough (see that
  /// field's own doc comment) — a malformed shape here degrades to an
  /// empty editable list rather than throwing, matching `listing-detail`'s
  /// own "malformed optionList drops the section" honesty rule rather than
  /// crashing the whole edit form over one bad row.
  static List<AdditionalInfoRow> _parseOptionList(Object? raw) {
    if (raw is! List) return [];
    final rows = <AdditionalInfoRow>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final key = entry['key'];
      final value = entry['value'];
      rows.add(
        AdditionalInfoRow(
          key: key is String ? key : '',
          value: value is String ? value : (value?.toString() ?? ''),
        ),
      );
    }
    return rows;
  }

  /// Step 1's five required fields (§26). Sets every error field (not just
  /// the first failing one) so a user fixing one mistake isn't surprised by
  /// a second the next time they tap Next/Save.
  bool validateBasics() {
    titleError = title.text.trim().isEmpty ? 'Title is required' : null;
    cityError = city.text.trim().isEmpty ? 'City is required' : null;
    districtError = district.text.trim().isEmpty ? 'District is required' : null;
    addressError = address.text.trim().isEmpty ? 'Address is required' : null;
    referenceError = reference.text.trim().isEmpty ? 'Reference is required' : null;
    return titleError == null &&
        cityError == null &&
        districtError == null &&
        addressError == null &&
        referenceError == null;
  }

  /// Step 2's one required field (§26).
  bool validateDescription() {
    descriptionError = description.text.trim().isEmpty
        ? 'Description is required'
        : null;
    return descriptionError == null;
  }

  /// `edit-listing`'s single-shot validation — both groups, and
  /// deliberately `&` (not `&&`) so both always run and set their own
  /// error fields even once the first has already failed.
  bool validateAll() => validateBasics() & validateDescription();

  /// Builds the write body both screens submit. [includeHashtags] is
  /// `false` for `edit-listing` — §27: "Same fields ... (no Hashtags
  /// field)". [photos] is supplied by the caller rather than owned here:
  /// `create-listing` has none to give (§26/§5.2 — no picker exists yet);
  /// `edit-listing` passes its existing-photo grid's current state
  /// (post-delete) so a removed photo's `X` actually persists on Save.
  AdWriteInput toWriteInput({
    required bool includeHashtags,
    List<String>? photos,
  }) {
    return AdWriteInput(
      title: OptionalField(title.text.trim()),
      city: OptionalField(city.text.trim()),
      district: OptionalField(district.text.trim()),
      address: OptionalField(_orNull(address.text)),
      reference: OptionalField(_orNull(reference.text)),
      type: OptionalField(type),
      category: OptionalField(category),
      repairment: OptionalField(repairment),
      rooms: OptionalField(int.tryParse(rooms.text.trim())),
      area: OptionalField(double.tryParse(area.text.trim())),
      storey: OptionalField(int.tryParse(storey.text.trim())),
      floors: OptionalField(int.tryParse(floors.text.trim())),
      furniture: OptionalField(furniture),
      hashtags: includeHashtags ? OptionalField(_orNull(hashtags.text)) : null,
      price: OptionalField(double.tryParse(price.text.trim()) ?? 0),
      priceType: OptionalField(priceType),
      stage: OptionalField(stage),
      description: OptionalField(_orNull(description.text)),
      nearPlacesList: OptionalField(List.of(nearPlaces)),
      optionList: OptionalField([
        for (final row in additionalInfo) {'key': row.key, 'value': row.value},
      ]),
      photos: photos == null ? null : OptionalField(photos),
    );
  }

  String? _orNull(String text) => text.trim().isEmpty ? null : text.trim();

  void dispose() {
    title.dispose();
    city.dispose();
    district.dispose();
    address.dispose();
    reference.dispose();
    hashtags.dispose();
    price.dispose();
    rooms.dispose();
    area.dispose();
    storey.dispose();
    floors.dispose();
    description.dispose();
  }
}
