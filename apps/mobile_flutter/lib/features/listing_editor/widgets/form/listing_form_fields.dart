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

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../api/api.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/shared.dart';

enum MediaUploadStatus { uploading, done, failed }

/// One photo/video the user picked in this session, tracked from the
/// moment the picker returns bytes through however the upload resolves —
/// see `photos_step.dart`'s doc comment for the full flow. Lives on
/// [ListingFormFields] itself (not `PhotosStep`'s own widget state) so an
/// in-flight upload survives `create-listing`'s Back/Next tearing down and
/// rebuilding that step's widget subtree.
class ListingMediaUpload {
  ListingMediaUpload({
    required this.id,
    required this.isVideo,
    required this.previewBytes,
    this.fileName,
  });

  final String id;
  final bool isVideo;
  final Uint8List previewBytes;
  final String? fileName;

  MediaUploadStatus status = MediaUploadStatus.uploading;

  /// Ticks on every chunk `UploadsResource.putBytes` reports — a
  /// [ValueNotifier] rather than a plain field so the tile showing it can
  /// rebuild on its own via [ValueListenableBuilder] instead of forcing a
  /// full-step [ListingFormFields]-owning-screen rebuild per chunk (a 70MB
  /// video is hundreds of chunks — see `uploads_resource.dart`'s
  /// `_uploadChunkBytes`).
  final ValueNotifier<double> progress = ValueNotifier(0);

  /// Set once [status] is [MediaUploadStatus.done].
  String? url;

  /// Set once [status] is [MediaUploadStatus.failed] — already run through
  /// `describeUploadError`, ready to show as-is.
  String? errorMessage;

  /// Lets a "remove" tap on a still-uploading tile actually cancel the
  /// in-flight PUT rather than let it finish invisibly — see
  /// `UploadHandle`'s own doc comment.
  UploadHandle? handle;

  void dispose() {
    handle?.cancel();
    progress.dispose();
  }
}

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

  /// Every photo/video picked this session — see [ListingMediaUpload]'s own
  /// doc comment. Newest last, matching `additionalInfo`'s own append order.
  final List<ListingMediaUpload> media = [];

  int get photoUploadCount => media.where((m) => !m.isVideo).length;
  int get videoUploadCount => media.where((m) => m.isVideo).length;

  /// The public URLs of every successful upload this session — what a
  /// caller actually sends on `photos[]` (folded in with any pre-existing
  /// URLs `edit-listing`'s own grid already tracks). A still-uploading or
  /// failed item contributes nothing here; it is not lost, just not ready
  /// to submit yet — `hasPendingUploads` tells a caller whether to wait.
  List<String> get uploadedMediaUrls => [
    for (final m in media)
      if (m.status == MediaUploadStatus.done && m.url != null) m.url!,
  ];

  bool get hasPendingUploads =>
      media.any((m) => m.status == MediaUploadStatus.uploading);

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
    category = ad.category == AdCategory.unknown
        ? AdCategory.rent
        : ad.category;
    repairment = ad.repairment ?? Repairment.notRepaired;
    furniture = ad.furniture ?? Furniture.withFurniture;
    priceType = ad.priceType == CurrencyCode.unknown
        ? CurrencyCode.uzs
        : ad.priceType;
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
  ///
  /// Takes [l10n] rather than a [BuildContext] — this class is a plain Dart
  /// field bag, not a widget, so it has no context of its own; the caller
  /// (a `State`'s own method, which does have one) resolves
  /// `AppLocalizations.of(context)` once and passes it in, per
  /// `lib/l10n/README.md`'s "passing AppLocalizations into a pure function"
  /// guidance for non-widget files.
  bool validateBasics(AppLocalizations l10n) {
    titleError = title.text.trim().isEmpty
        ? l10n.listingEditorTitleRequiredError
        : null;
    cityError = city.text.trim().isEmpty
        ? l10n.listingEditorCityRequiredError
        : null;
    districtError = district.text.trim().isEmpty
        ? l10n.listingEditorDistrictRequiredError
        : null;
    addressError = address.text.trim().isEmpty
        ? l10n.listingEditorAddressRequiredError
        : null;
    referenceError = reference.text.trim().isEmpty
        ? l10n.listingEditorReferenceRequiredError
        : null;
    return titleError == null &&
        cityError == null &&
        districtError == null &&
        addressError == null &&
        referenceError == null;
  }

  /// Step 2's one required field (§26). See [validateBasics] for why this
  /// takes [l10n] rather than a [BuildContext].
  bool validateDescription(AppLocalizations l10n) {
    descriptionError = description.text.trim().isEmpty
        ? l10n.listingEditorDescriptionRequiredError
        : null;
    return descriptionError == null;
  }

  /// `edit-listing`'s single-shot validation — both groups, and
  /// deliberately `&` (not `&&`) so both always run and set their own
  /// error fields even once the first has already failed.
  bool validateAll(AppLocalizations l10n) =>
      validateBasics(l10n) & validateDescription(l10n);

  /// Builds the write body both screens submit. [includeHashtags] is
  /// `false` for `edit-listing` — §27: "Same fields ... (no Hashtags
  /// field)". [photos] is supplied by the caller rather than owned here:
  /// `create-listing` passes this session's own [uploadedMediaUrls] (it has
  /// no pre-existing photos of its own to fold in); `edit-listing` passes
  /// its existing-photo grid's current state (post-delete) with
  /// [uploadedMediaUrls] already folded in, so a removed photo's `X` and a
  /// freshly-uploaded photo/video both persist on Save.
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
    for (final m in media) {
      m.dispose();
    }
  }
}
