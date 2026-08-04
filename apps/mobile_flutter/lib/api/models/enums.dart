/// Wire enums shared by every model in `lib/api/`.
///
/// Every enum carries an `unknown` member and a `fromWire` factory that
/// falls back to it instead of throwing. The live API is the source of
/// truth for these values (see the Milestone-2 API contract this package
/// was built against); a server adding a new enum member tomorrow must
/// never crash an app already installed on someone's phone. `unknown` is
/// never sent back to the server (`toWire()` has nothing to return for it
/// where a caller would need one — callers that write enums back should
/// guard against `unknown` explicitly).
library;

/// `User.role`, lowercased by `serializeUser.js`.
enum UserRole {
  user,
  agent,
  coworker,
  unknown;

  static UserRole fromWire(String? value) => switch (value) {
    'user' => UserRole.user,
    'agent' => UserRole.agent,
    'coworker' => UserRole.coworker,
    _ => UserRole.unknown,
  };
}

enum AdType {
  residential,
  nonresidential,
  unknown;

  static AdType fromWire(String? value) => switch (value) {
    'residential' => AdType.residential,
    'nonresidential' => AdType.nonresidential,
    _ => AdType.unknown,
  };

  String get wire => switch (this) {
    AdType.residential => 'residential',
    AdType.nonresidential => 'nonresidential',
    AdType.unknown => throw StateError('AdType.unknown has no wire value'),
  };
}

enum AdCategory {
  rent,
  sale,
  unknown;

  static AdCategory fromWire(String? value) => switch (value) {
    'rent' => AdCategory.rent,
    'sale' => AdCategory.sale,
    _ => AdCategory.unknown,
  };

  String get wire => switch (this) {
    AdCategory.rent => 'rent',
    AdCategory.sale => 'sale',
    AdCategory.unknown => throw StateError(
      'AdCategory.unknown has no wire value',
    ),
  };
}

/// Nullable on `Ad` — but when the key IS present, this is the enum for it.
enum Repairment {
  notRepaired,
  normal,
  good,
  excellent,
  unknown;

  static Repairment fromWire(String? value) => switch (value) {
    'notRepaired' => Repairment.notRepaired,
    'normal' => Repairment.normal,
    'good' => Repairment.good,
    'excellent' => Repairment.excellent,
    _ => Repairment.unknown,
  };

  String get wire => switch (this) {
    Repairment.notRepaired => 'notRepaired',
    Repairment.normal => 'normal',
    Repairment.good => 'good',
    Repairment.excellent => 'excellent',
    Repairment.unknown => throw StateError(
      'Repairment.unknown has no wire value',
    ),
  };
}

/// Nullable on `Ad` — same key-omission caveat as [Repairment].
enum Furniture {
  withFurniture,
  withoutFurniture,
  unknown;

  static Furniture fromWire(String? value) => switch (value) {
    'withFurniture' => Furniture.withFurniture,
    'withoutFurniture' => Furniture.withoutFurniture,
    _ => Furniture.unknown,
  };

  String get wire => switch (this) {
    Furniture.withFurniture => 'withFurniture',
    Furniture.withoutFurniture => 'withoutFurniture',
    Furniture.unknown => throw StateError(
      'Furniture.unknown has no wire value',
    ),
  };
}

/// Literal numeric-string keys on the wire ("1"/"2"/"3"), not word enums.
enum AdStage {
  active, // "1"
  sold, // "2"
  draft, // "3"
  unknown;

  static AdStage fromWire(String? value) => switch (value) {
    '1' => AdStage.active,
    '2' => AdStage.sold,
    '3' => AdStage.draft,
    _ => AdStage.unknown,
  };

  String get wire => switch (this) {
    AdStage.active => '1',
    AdStage.sold => '2',
    AdStage.draft => '3',
    AdStage.unknown => throw StateError('AdStage.unknown has no wire value'),
  };
}

enum CurrencyCode {
  uzs,
  usd,
  unknown;

  static CurrencyCode fromWire(String? value) => switch (value) {
    'uzs' => CurrencyCode.uzs,
    'usd' => CurrencyCode.usd,
    _ => CurrencyCode.unknown,
  };
}

/// `media[].mediaType`.
enum AdMediaType {
  photo,
  video,
  unknown;

  static AdMediaType fromWire(String? value) => switch (value) {
    'photo' => AdMediaType.photo,
    'video' => AdMediaType.video,
    _ => AdMediaType.unknown,
  };
}

enum RealtorKind {
  solo,
  agency,
  unknown;

  static RealtorKind fromWire(String? value) => switch (value) {
    'solo' => RealtorKind.solo,
    'agency' => RealtorKind.agency,
    _ => RealtorKind.unknown,
  };

  String get wire => switch (this) {
    RealtorKind.solo => 'solo',
    RealtorKind.agency => 'agency',
    RealtorKind.unknown => throw StateError(
      'RealtorKind.unknown has no wire value',
    ),
  };
}

enum RealtorStatus {
  none,
  pending,
  approved,
  rejected,
  unknown;

  static RealtorStatus fromWire(String? value) => switch (value) {
    'none' => RealtorStatus.none,
    'pending' => RealtorStatus.pending,
    'approved' => RealtorStatus.approved,
    'rejected' => RealtorStatus.rejected,
    _ => RealtorStatus.unknown,
  };
}

enum TeamSize {
  justMe, // "just_me"
  twoToFive, // "two_to_five"
  sixToFifteen, // "six_to_fifteen"
  sixteenPlus, // "sixteen_plus"
  unknown;

  static TeamSize fromWire(String? value) => switch (value) {
    'just_me' => TeamSize.justMe,
    'two_to_five' => TeamSize.twoToFive,
    'six_to_fifteen' => TeamSize.sixToFifteen,
    'sixteen_plus' => TeamSize.sixteenPlus,
    _ => TeamSize.unknown,
  };

  String get wire => switch (this) {
    TeamSize.justMe => 'just_me',
    TeamSize.twoToFive => 'two_to_five',
    TeamSize.sixToFifteen => 'six_to_fifteen',
    TeamSize.sixteenPlus => 'sixteen_plus',
    TeamSize.unknown => throw StateError('TeamSize.unknown has no wire value'),
  };
}
