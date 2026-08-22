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

  /// Added alongside the Work build's `AdWriteInput`
  /// (`models/ad_write_input.dart`) — the first write path for this enum;
  /// every prior caller only ever read [Ad.priceType], never sent one back.
  String get wire => switch (this) {
    CurrencyCode.uzs => 'uzs',
    CurrencyCode.usd => 'usd',
    CurrencyCode.unknown => throw StateError(
      'CurrencyCode.unknown has no wire value',
    ),
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

/// `Lead.status` — fixed order (`LEAD_STATUS_ORDER` in
/// `packages/domain/src/enums/leads.ts`), also the Kanban column order
/// (SCREENS.md §31/§34, `apps/console/src/screens/kanban/*`). There is
/// deliberately **no** 6th "success/closed" member — `LeadStatus.SUCCESS`
/// does not exist in the Prisma schema; every console/web screen that might
/// want one flags the gap instead of fabricating it, and SCREENS.md never
/// asks for one either.
enum LeadStatus {
  newLead, // 'new' — `new` alone can't be a Dart identifier
  couldNotConnect,
  needToCallBack,
  rejected,
  accepted,
  unknown;

  static LeadStatus fromWire(String? value) => switch (value) {
    'new' => LeadStatus.newLead,
    'could_not_connect' => LeadStatus.couldNotConnect,
    'need_to_call_back' => LeadStatus.needToCallBack,
    'rejected' => LeadStatus.rejected,
    'accepted' => LeadStatus.accepted,
    _ => LeadStatus.unknown,
  };

  String get wire => switch (this) {
    LeadStatus.newLead => 'new',
    LeadStatus.couldNotConnect => 'could_not_connect',
    LeadStatus.needToCallBack => 'need_to_call_back',
    LeadStatus.rejected => 'rejected',
    LeadStatus.accepted => 'accepted',
    LeadStatus.unknown => throw StateError(
      'LeadStatus.unknown has no wire value',
    ),
  };

  /// `LEAD_STATUS_ORDER` — the fixed left-to-right Kanban column order
  /// (SCREENS.md §31: New → Could Not Connect → Need To Call Back →
  /// Rejected → Accepted). [unknown] is deliberately absent: a lead the
  /// server sends with a status this client doesn't recognize should never
  /// silently claim a Kanban column.
  static const List<LeadStatus> kanbanOrder = [
    LeadStatus.newLead,
    LeadStatus.couldNotConnect,
    LeadStatus.needToCallBack,
    LeadStatus.rejected,
    LeadStatus.accepted,
  ];
}

/// Publish channel — `AdPublication.channel` / `ALL_CHANNELS`
/// (`apps/api/src/routes/publish.js`). Wire values are the raw upper-case
/// Postgres enum, NOT lowercased like every other enum in this file — kept
/// verbatim rather than normalized, since `[wire]` round-trips it straight
/// into query strings/bodies unchanged.
///
/// **This enum holds two different kinds of member, and confusing them is
/// the one expensive mistake available here.** The first four —
/// [telegram], [instagram], [youtube], [olx] — are *wire*
/// members: the server's `Channel` Postgres enum, one-for-one. The four
/// after them — [threads], [facebookMarketplace], [x], [linkedin] — are
/// *display-only* members: channels the product surfaces name and shows in
/// their visibly-disabled state (WORK_TAB_CONTRACT.md ruling 7.13, the same
/// treatment ruling 7.10 gave YouTube), for which `apps/api` has no route,
/// no enum value and no publish call in this build. They exist so the
/// publish surfaces can render an honest, localized "why not" line for each
/// one instead of pretending the channel doesn't exist; they must never
/// reach the network. [fromWire] cannot produce one, [wire] throws for one,
/// and [allChannels] does not contain one — see each member below for the
/// reasoning behind those three decisions.
enum Channel {
  telegram,
  instagram,
  youtube,
  olx,
  // ---- display-only from here down (no server representation) ----------
  // Deliberately placed AFTER the wire members and BEFORE [unknown], and
  // `unknown` stays last, which is the shape every enum in this file has.
  threads,
  facebookMarketplace,
  x,
  linkedin,
  unknown;

  /// Deliberately gains **no** cases for the four display-only members.
  /// The server's `Channel` enum has no `THREADS`/`FACEBOOK_MARKETPLACE`/
  /// `X`/`LINKEDIN` value, so those strings can never arrive; adding arms
  /// for them would document a wire contract `apps/api` does not have, and
  /// would make a display-only channel reachable from decoded JSON — which
  /// is precisely what keeps a permanently-PENDING publish-status row from
  /// being possible. Anything unrecognized keeps falling through to
  /// [unknown], the same forward-compatibility default every enum here has.
  static Channel fromWire(String? value) => switch (value) {
    'TELEGRAM' => Channel.telegram,
    'INSTAGRAM' => Channel.instagram,
    'YOUTUBE' => Channel.youtube,
    'OLX' => Channel.olx,
    _ => Channel.unknown,
  };

  /// Invariant across this whole file: `wire` returns a string the live API
  /// understands. The four display-only members have no such string, so
  /// they throw rather than invent one — following [unknown]'s own
  /// precedent below. Returning `'THREADS'` instead would quietly break the
  /// invariant and ship a request the API 400s on; throwing keeps the type
  /// honest, and because this switch is exhaustive the compiler forces any
  /// future caller to confront the arm rather than discover it in prod.
  /// Blast radius today is nil: nothing calls `wire` on a display-only
  /// channel, and nothing can, since [fromWire] can never produce one.
  String get wire => switch (this) {
    Channel.telegram => 'TELEGRAM',
    Channel.instagram => 'INSTAGRAM',
    Channel.youtube => 'YOUTUBE',
    Channel.olx => 'OLX',
    Channel.threads => throw StateError(
      'Channel.threads is display-only — no server publish endpoint exists '
      'for it in this build',
    ),
    Channel.facebookMarketplace => throw StateError(
      'Channel.facebookMarketplace is display-only — no server publish '
      'endpoint exists for it in this build',
    ),
    Channel.x => throw StateError(
      'Channel.x is display-only — no server publish endpoint exists for it '
      'in this build',
    ),
    Channel.linkedin => throw StateError(
      'Channel.linkedin is display-only — no server publish endpoint exists '
      'for it in this build',
    ),
    Channel.unknown => throw StateError('Channel.unknown has no wire value'),
  };

  /// `GET /publish/ads/:adId/status`'s fixed response order
  /// (`ALL_CHANNELS`) — always exactly these 4, in this order, synthesizing
  /// a PENDING placeholder for any channel with no publish attempt yet.
  ///
  /// Do not append app-only display channels here — see
  /// [publishSurfaceChannels]. This list is a description of *someone
  /// else's* response, not of our UI: every entry in it becomes a row on
  /// `publish-status`, and the server synthesizes that row as PENDING when
  /// no attempt exists. A channel with no publish endpoint would therefore
  /// grow a PENDING row on every ad forever, one that no action in the app
  /// could ever clear. The guard test `test/api/channel_display_list_test
  /// .dart` pins this list at exactly these 4 in exactly this order.
  static const List<Channel> allChannels = [
    Channel.telegram,
    Channel.instagram,
    Channel.youtube,
    Channel.olx,
  ];

  /// App-side display order for the publish surfaces. **NOT a wire contract
  /// and NOT a superset of [allChannels] — never feed this list to anything
  /// that builds publish-status rows, or every ad grows a permanently-
  /// PENDING row per app-only channel.**
  ///
  /// The two lists answer two different questions. [allChannels] answers
  /// "what does `GET /publish/ads/:adId/status` return?" — the server owns
  /// it and we only mirror it. This one answers "which channels does the
  /// app *show* a publish row for, top to bottom?" — we own it outright,
  /// and it is allowed to name channels the API has never heard of, because
  /// each of those rows is rendered visibly disabled with its own honest
  /// reason (ruling 7.13) rather than as a control that would 404.
  ///
  /// Order matches `publish_section.dart`'s shipped row order, with the
  /// four display-only channels appended after [olx]. [unknown] is
  /// deliberately absent: it is a decode fallback, never a surface.
  static const List<Channel> publishSurfaceChannels = [
    Channel.instagram,
    Channel.telegram,
    Channel.youtube,
    Channel.olx,
    Channel.threads,
    Channel.facebookMarketplace,
    Channel.x,
    Channel.linkedin,
  ];

  /// The two channels `PublishResource` has a real server-to-server publish
  /// call for (`publishInstagram`/`publishTelegram`, i.e. `POST
  /// /publish/instagram` and `POST /publish/telegram`). This is the
  /// predicate the publish
  /// surfaces branch on for enabled-vs-visibly-disabled, so that "is this
  /// button live?" reads as a documented fact about the API rather than as
  /// a hardcoded `enabled: false` repeated once per row.
  ///
  /// [youtube] is false because `POST /publish/youtube` is report-back
  /// only — there is no server-side upload to trigger from a button; [olx]
  /// because cross-posting runs from the desktop extension; the four
  /// display-only members because nothing exists behind them at all;
  /// [unknown] because it is a fallback.
  ///
  /// Note this is **not** the same question `publish_status_screen.dart`'s
  /// `_isRetryableChannel` asks, even though the two happen to list the
  /// same members today: a retryable row additionally needs a *stored*
  /// original request server-side. Don't collapse them.
  bool get hasServerPublishPath => switch (this) {
    Channel.telegram => true,
    Channel.instagram => true,
    Channel.youtube => false,
    Channel.olx => false,
    Channel.threads => false,
    Channel.facebookMarketplace => false,
    Channel.x => false,
    Channel.linkedin => false,
    Channel.unknown => false,
  };
}

/// `AdPublication.status` — also the raw upper-case Postgres enum, same
/// verbatim-wire convention as [Channel].
enum PublishStatus {
  pending,
  draftedAwaitingReview,
  published,
  failed,
  unknown;

  static PublishStatus fromWire(String? value) => switch (value) {
    'PENDING' => PublishStatus.pending,
    'DRAFTED_AWAITING_REVIEW' => PublishStatus.draftedAwaitingReview,
    'PUBLISHED' => PublishStatus.published,
    'FAILED' => PublishStatus.failed,
    _ => PublishStatus.unknown,
  };

  String get wire => switch (this) {
    PublishStatus.pending => 'PENDING',
    PublishStatus.draftedAwaitingReview => 'DRAFTED_AWAITING_REVIEW',
    PublishStatus.published => 'PUBLISHED',
    PublishStatus.failed => 'FAILED',
    PublishStatus.unknown => throw StateError(
      'PublishStatus.unknown has no wire value',
    ),
  };
}

/// `CoworkerStatisticEvent.stage` (`GET /statistics/coworkers`) — a numeric
/// `EVENT_STAGE` code, NOT the same value space as [AdStage]'s "1"/"2"/"3"
/// despite the overlapping digits. Named `ActivityEventStage` (not
/// `EventStage`) to keep that distinction visible at every call site.
enum ActivityEventStage {
  adCreated, // 1
  adSold, // 2
  adDraftUpdated, // 3
  leadCreated, // 4
  leadStatusChanged, // 5
  unknown;

  static ActivityEventStage fromWire(int? value) => switch (value) {
    1 => ActivityEventStage.adCreated,
    2 => ActivityEventStage.adSold,
    3 => ActivityEventStage.adDraftUpdated,
    4 => ActivityEventStage.leadCreated,
    5 => ActivityEventStage.leadStatusChanged,
    _ => ActivityEventStage.unknown,
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
