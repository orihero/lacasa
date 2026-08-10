/// The Work-tab seed data — SCREENS.md §4 (property listings, leads,
/// agents/coworkers, notifications, dashboard stats, dashboard chart
/// series), transcribed once here so every one of the six Work features'
/// own `fixture_<feature>_repository.dart` reads the same underlying rows
/// instead of six independently-typed copies drifting apart. Each feature
/// still owns its own `FixtureXRepository` class (per this app's
/// convention — see `WORK_TAB_CONTRACT.md`'s conventions digest) and
/// decides its own slicing/filtering of these lists; only the raw data
/// lives here.
///
/// **Id scheme, and one deliberate divergence from `features/home/data/
/// home_feed_fixtures.dart` worth knowing before cross-referencing the
/// two:** that file's `ad-1006`/`ad-1008` use `agentId: 'agent-sardor'`/
/// `'agent-kamola'` — a documented simplification, because `GET /agents`
/// only ever returns real AGENT rows, so Home's fixture treats the two
/// coworkers as if they were their own pseudo-agent for that one screen's
/// purposes. The Work tab is coworker-*aware* (My Ads/Leads/Coworkers all
/// distinguish agent vs. coworker), so **this file does not follow that
/// simplification**: [workAdsFixtures]' `ad-1006`/`ad-1008` carry the real
/// wire pairing instead — `agentId: 'agent-javlon'`/`'agent-shahnoza'`
/// (the owning agent) plus `coworkerId: 'coworker-sardor'`/
/// `'coworker-kamola'` (who actually created the listing) — matching
/// `Ad.coworkerId`'s real contract. `agent-javlon`/`agent-shahnoza`/
/// `agent-otabek` themselves are unchanged from Home's ids, so an ad
/// authored by one of the three real agents resolves against either
/// fixture set identically.
///
/// **Notification/dashboard-chart shapes have no wire contract at all** —
/// see the API contract survey's explicit answer #1 (no `notifications`
/// endpoint exists anywhere) and §2 (no bucketed daily series endpoint
/// exists either). [WorkNotificationFixture] and [WorkDashboardChartPoint]
/// are therefore NOT modeled in `lib/api/models/` (which mirrors real wire
/// shapes only) — they live here, fixture-only, so nothing about their
/// shape is mistaken for a real server contract. A feature that eventually
/// synthesizes notifications from live data (per the survey's suggestion:
/// fold `GET /leads` + `GET /publish/status` + `GET /my/ads` +
/// `GET /statistics/coworkers`) will need its own live-mode type for that —
/// this file only has to satisfy the fixture/offline default every screen
/// must render sensibly with no network at all.
library;

import '../../api/api.dart';

// ---------------------------------------------------------------------
// §4.1 — Property listings (8)
// ---------------------------------------------------------------------

Map<String, dynamic> _ad({
  required String id,
  required String title,
  required String district,
  required String category, // 'sale' | 'rent'
  required String type, // 'residential' | 'nonresidential'
  required num price,
  required int rooms,
  required num area,
  required int storey,
  required int floors,
  required String stage, // '1' active | '2' sold | '3' draft
  required String agentId,
  String coworkerId = '',
  required int createdAtSeconds,
}) {
  return {
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': district,
    'address': null,
    'reference': null,
    'type': type,
    'category': category,
    'repairment': null,
    'rooms': rooms,
    'area': area,
    'storey': storey,
    'floors': floors,
    'furniture': null,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': stage,
    'description': null,
    'nearPlacesList': const <String>[],
    'optionList': const <Map<String, dynamic>>[],
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': agentId,
    'coworkerId': coworkerId,
    'photos': const <String>[],
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
  };
}

/// All 8 rows of §4.1, **every stage included** — `ad-1005` (Sold) and
/// `ad-1007` (Draft) are present here even though `features/home/`'s own
/// fixture omits them (that screen mirrors the public feed's
/// `stage: "ACTIVE"` scoping; `my-listings` must show every stage, so this
/// list doesn't apply that filter).
final List<Ad> workAdsFixtures = [
  _ad(
    id: 'ad-1001',
    title: 'Bright 3-room apartment in Chilonzor',
    district: 'Chilonzor',
    category: 'sale',
    type: 'residential',
    price: 78000,
    rooms: 3,
    area: 65,
    storey: 4,
    floors: 9,
    stage: '1',
    agentId: 'agent-javlon',
    createdAtSeconds: 1700000800,
  ),
  _ad(
    id: 'ad-1002',
    title: 'Renovated studio near Yunusobod metro',
    district: 'Yunusobod',
    category: 'rent',
    type: 'residential',
    price: 350,
    rooms: 1,
    area: 32,
    storey: 2,
    floors: 5,
    stage: '1',
    agentId: 'agent-shahnoza',
    createdAtSeconds: 1700000700,
  ),
  _ad(
    id: 'ad-1003',
    title: 'Family house with garden in Sergeli',
    district: 'Sergeli',
    category: 'sale',
    type: 'residential',
    price: 120000,
    rooms: 5,
    area: 140,
    storey: 1,
    floors: 2,
    stage: '1',
    agentId: 'agent-javlon',
    createdAtSeconds: 1700000600,
  ),
  _ad(
    id: 'ad-1004',
    title: 'Office space on Amir Temur avenue',
    district: 'Mirzo Ulugbek',
    category: 'rent',
    type: 'nonresidential',
    price: 900,
    rooms: 4,
    area: 110,
    storey: 6,
    floors: 12,
    stage: '1',
    agentId: 'agent-otabek',
    createdAtSeconds: 1700000500,
  ),
  _ad(
    id: 'ad-1005',
    title: 'Two-room flat in Mirobod',
    district: 'Mirobod',
    category: 'sale',
    type: 'residential',
    price: 62500,
    rooms: 2,
    area: 54,
    storey: 7,
    floors: 16,
    stage: '2',
    agentId: 'agent-shahnoza',
    createdAtSeconds: 1700000400,
  ),
  _ad(
    id: 'ad-1006',
    title: 'Retail space near Chorsu bazaar',
    district: 'Shayxontohur',
    category: 'rent',
    type: 'nonresidential',
    price: 1200,
    rooms: 2,
    area: 48,
    storey: 1,
    floors: 1,
    stage: '1',
    agentId: 'agent-javlon',
    coworkerId: 'coworker-sardor',
    createdAtSeconds: 1700000300,
  ),
  _ad(
    id: 'ad-1007',
    title: 'New-build 4-room in Yashnobod',
    district: 'Yashnobod',
    category: 'sale',
    type: 'residential',
    price: 95000,
    rooms: 4,
    area: 88,
    storey: 12,
    floors: 17,
    stage: '3',
    agentId: 'agent-otabek',
    createdAtSeconds: 1700000200,
  ),
  _ad(
    id: 'ad-1008',
    title: 'Renovated 1-room near Yakkasaroy park',
    district: 'Yakkasaroy',
    category: 'rent',
    type: 'residential',
    price: 400,
    rooms: 1,
    area: 38,
    storey: 3,
    floors: 5,
    stage: '1',
    agentId: 'agent-shahnoza',
    coworkerId: 'coworker-kamola',
    createdAtSeconds: 1700000100,
  ),
].map(Ad.fromJson).toList(growable: false);

// ---------------------------------------------------------------------
// §4.2 — Leads (6)
// ---------------------------------------------------------------------

Map<String, dynamic> _lead({
  required String id,
  required String fullName,
  required String phone,
  required double budget,
  required String comment,
  required String status,
  required String agentId,
  String? callbackIso,
  String? conversationComment,
  required int createdAtSeconds,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'phone': phone,
    'email': null,
    'budget': budget,
    'comment': comment,
    'conversationComment': conversationComment,
    'status': status,
    'source': null,
    'callbackDate': callbackIso,
    'active': true,
    'agentId': agentId,
    'coworkerId': '',
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
  };
}

final List<Lead> workLeadsFixtures =
    [
      _lead(
        id: 'lead-2001',
        fullName: 'Dilnoza Yusupova',
        phone: '+998901234501',
        budget: 50000,
        comment: '2–3 room apartment, Chilonzor or Yunusobod',
        status: 'new',
        agentId: 'agent-javlon',
        createdAtSeconds: 1700100600,
      ),
      _lead(
        id: 'lead-2002',
        fullName: 'Aziz Karimov',
        phone: '+998933456712',
        budget: 80000,
        comment: 'Family house, Sergeli',
        status: 'need_to_call_back',
        agentId: 'agent-javlon',
        // "Callback reminder — Call Aziz Karimov today at 15:00" (§4.4 #3).
        callbackIso: '2026-08-10T15:00:00.000Z',
        createdAtSeconds: 1700100500,
      ),
      _lead(
        id: 'lead-2003',
        fullName: 'Malika Tosheva',
        phone: '+998977654321',
        budget: 1000,
        comment: 'Office rental, city center',
        status: 'could_not_connect',
        agentId: 'agent-shahnoza',
        createdAtSeconds: 1700100400,
      ),
      _lead(
        id: 'lead-2004',
        fullName: 'Bekzod Nazarov',
        phone: '+998912345678',
        budget: 60000,
        comment: '2-room flat, Mirobod',
        status: 'accepted',
        agentId: 'agent-shahnoza',
        conversationComment:
            'Agreed on price, signing paperwork next week.',
        createdAtSeconds: 1700100300,
      ),
      _lead(
        id: 'lead-2005',
        fullName: 'Ravshan Ismoilov',
        phone: '+998995551122',
        budget: 100000,
        comment: '4-room new build, Yashnobod',
        status: 'rejected',
        agentId: 'agent-javlon',
        conversationComment: 'Went with another agency, budget mismatch.',
        createdAtSeconds: 1700100200,
      ),
      _lead(
        id: 'lead-2006',
        fullName: 'Nodira Ergasheva',
        phone: '+998911223344',
        budget: 400,
        comment: '1-room studio near metro',
        status: 'new',
        agentId: 'agent-shahnoza',
        createdAtSeconds: 1700100100,
      ),
    ].map(Lead.fromJson).toList(growable: false);

// ---------------------------------------------------------------------
// §4.3 — Agents / coworkers (5)
// ---------------------------------------------------------------------

Map<String, dynamic> _agentDetail({
  required String id,
  required String fullName,
  required int adsCount,
  required int dealsClosedCount,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': '${id.replaceFirst('agent-', '')}@lacasa.uz',
    'phoneNumber': null,
    'avatar': null,
    'adsCount': adsCount,
    'dealsClosedCount': dealsClosedCount,
  };
}

/// The 3 real AGENT rows (`GET /agents` would only ever return these three
/// — see `home_feed_fixtures.dart`'s identical note). [AgentDetail] (not
/// [AgentSummary]) so `dealsClosedCount` is available for any Work screen
/// wanting it (e.g. a Dashboard/coworker-detail "deals closed" figure) —
/// [AgentSummary] alone doesn't carry it.
final List<AgentDetail> workAgentsFixtures =
    [
      _agentDetail(
        id: 'agent-javlon',
        fullName: 'Javlon Rustamov',
        adsCount: 24,
        dealsClosedCount: 9,
      ),
      _agentDetail(
        id: 'agent-shahnoza',
        fullName: 'Shahnoza Yoldosheva',
        adsCount: 18,
        dealsClosedCount: 6,
      ),
      _agentDetail(
        id: 'agent-otabek',
        fullName: 'Otabek Yusupov',
        adsCount: 31,
        dealsClosedCount: 14,
      ),
    ].map(AgentDetail.fromJson).toList(growable: false);

Map<String, dynamic> _coworker({
  required String id,
  required String fullName,
  required String agentId,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': '${id.replaceFirst('coworker-', '')}@lacasa.uz',
    'phoneNumber': null,
    'avatar': null,
    'agentId': agentId,
  };
}

/// The 2 COWORKER rows. `Coworker` (`api/models/coworker.dart`) has no
/// `listingsCount`/`dealsClosedCount` field — matching the real
/// `GET /coworkers` response exactly (see that model's own doc comment for
/// why) — a screen wanting those derives them from [workAdsFixtures]'
/// `coworkerId` / [workStatisticsCoworkersFixture] itself, the same way
/// `apps/console`'s own Coworkers table does.
final List<Coworker> workCoworkersFixtures =
    [
      _coworker(
        id: 'coworker-sardor',
        fullName: 'Sardor Abdullayev',
        agentId: 'agent-javlon',
      ),
      _coworker(
        id: 'coworker-kamola',
        fullName: 'Kamola Rashidova',
        agentId: 'agent-shahnoza',
      ),
    ].map(Coworker.fromJson).toList(growable: false);

/// `GET /statistics/coworkers`-shaped raw events backing the two
/// coworkers' "11"/"8" listings and "3"/"2" deals-closed figures from §4.3
/// — a Work screen deriving those columns the way `apps/console` does
/// (fold [ActivityEvent] by [ActivityEvent.coworkerId]) can use this
/// directly instead of inventing its own event history. Counts line up
/// with §4.3: Sardor gets 11 `adCreated` + 3 `adSold` events, Kamola gets 8
/// `adCreated` + 2 `adSold`, all under their respective agent's `agentId`.
final List<ActivityEvent> workStatisticsCoworkersFixture = [
  for (var i = 0; i < 11; i++)
    ActivityEvent.fromJson({
      'id': 'evt-sardor-created-$i',
      'agentId': 'agent-javlon',
      'coworkerId': 'coworker-sardor',
      'adId': 'ad-1006',
      'leadId': '',
      'stage': 1, // AD_CREATED
      'createdAt': {'seconds': 1700000000 + i * 1000},
    }),
  for (var i = 0; i < 3; i++)
    ActivityEvent.fromJson({
      'id': 'evt-sardor-sold-$i',
      'agentId': 'agent-javlon',
      'coworkerId': 'coworker-sardor',
      'adId': 'ad-1006',
      'leadId': '',
      'stage': 2, // AD_SOLD
      'createdAt': {'seconds': 1700020000 + i * 1000},
    }),
  for (var i = 0; i < 8; i++)
    ActivityEvent.fromJson({
      'id': 'evt-kamola-created-$i',
      'agentId': 'agent-shahnoza',
      'coworkerId': 'coworker-kamola',
      'adId': 'ad-1008',
      'leadId': '',
      'stage': 1,
      'createdAt': {'seconds': 1700030000 + i * 1000},
    }),
  for (var i = 0; i < 2; i++)
    ActivityEvent.fromJson({
      'id': 'evt-kamola-sold-$i',
      'agentId': 'agent-shahnoza',
      'coworkerId': 'coworker-kamola',
      'adId': 'ad-1008',
      'leadId': '',
      'stage': 2,
      'createdAt': {'seconds': 1700040000 + i * 1000},
    }),
];

// ---------------------------------------------------------------------
// §4.4 — Notifications (5)
// ---------------------------------------------------------------------

/// What a notification row routes to on tap — SCREENS.md §22's tap-through
/// table. [leadDetail] targets a bottom sheet (`lead-detail`, §32), not a
/// route — see `WORK_TAB_CONTRACT.md`'s routing table for the exact
/// function signature the `notifications` screen should call for that one
/// case; the other three are plain `context.push` targets.
enum WorkNotificationKind { lead, publish, sold, coworkerActivity }

/// One row of `notifications` (§22) — fixture/client-only shape, see this
/// file's doc comment for why it isn't in `lib/api/models/`.
class WorkNotificationFixture {
  final String id;
  final WorkNotificationKind kind;
  final String title;

  /// Display-ready relative-time string straight from SCREENS.md §4.4
  /// ("2 min ago", "Yesterday", ...) rather than a [DateTime] a screen
  /// would have to re-derive the same string from — this is fixture data
  /// frozen at a point in the past relative to "today" in the spec's own
  /// worked example (§4.6: "Today is Day 12 of the current month"), so a
  /// live [DateTime] would drift from that string the moment real time
  /// moves on. A live-mode notifications source is free to use real
  /// [DateTime]s; this fixture just isn't trying to be one.
  final String relativeTime;
  final bool unread;

  /// The id this notification's tap-through target needs — a lead id, an
  /// ad id, or a coworker id, depending on [kind]. `null` for a kind with
  /// no natural target id (none of the 5 seed rows hit that case, but a
  /// future notification kind might).
  final String? targetId;

  const WorkNotificationFixture({
    required this.id,
    required this.kind,
    required this.title,
    required this.relativeTime,
    required this.unread,
    required this.targetId,
  });
}

/// §4.4's 5 rows, in the order the spec lists them (most-recent first —
/// the order `notifications` should render top-to-bottom).
final List<WorkNotificationFixture> workNotificationsFixture = [
  const WorkNotificationFixture(
    id: 'notif-1',
    kind: WorkNotificationKind.lead,
    title:
        'New lead: Dilnoza Yusupova is interested in your Chilonzor listing',
    relativeTime: '2 min ago',
    unread: true,
    targetId: 'lead-2001',
  ),
  const WorkNotificationFixture(
    id: 'notif-2',
    kind: WorkNotificationKind.publish,
    title:
        'Instagram post published — Bright 3-room apartment in Chilonzor is '
        'now live on Instagram',
    relativeTime: '1 h ago',
    unread: true,
    targetId: 'ad-1001',
  ),
  const WorkNotificationFixture(
    id: 'notif-3',
    kind: WorkNotificationKind.lead,
    title: 'Callback reminder — Call Aziz Karimov today at 15:00',
    relativeTime: '3 h ago',
    unread: true,
    targetId: 'lead-2002',
  ),
  const WorkNotificationFixture(
    id: 'notif-4',
    kind: WorkNotificationKind.sold,
    title: 'Listing sold — Two-room flat in Mirobod marked as Sold',
    relativeTime: 'Yesterday',
    unread: false,
    targetId: 'ad-1005',
  ),
  const WorkNotificationFixture(
    id: 'notif-5',
    kind: WorkNotificationKind.coworkerActivity,
    title:
        'Coworker added a new listing — Sardor Abdullayev created Retail '
        'space near Chorsu bazaar',
    relativeTime: '2 days ago',
    unread: false,
    targetId: 'coworker-sardor',
  ),
];

// ---------------------------------------------------------------------
// §4.5 — Dashboard stat metrics (4)
// ---------------------------------------------------------------------

/// §4.5's 4 stat-card figures — fixture-only shape, mirrors
/// [AdsStatistics] plus the two counts that endpoint doesn't cover
/// (active leads, coworkers), matching `dashboard`'s own tile set.
class WorkDashboardStatsFixture {
  final int adsCreatedThisMonth;
  final int adsSoldThisMonth;
  final int activeLeads;
  final int coworkers;

  const WorkDashboardStatsFixture({
    required this.adsCreatedThisMonth,
    required this.adsSoldThisMonth,
    required this.activeLeads,
    required this.coworkers,
  });
}

const workDashboardStatsFixture = WorkDashboardStatsFixture(
  adsCreatedThisMonth: 42,
  adsSoldThisMonth: 11,
  activeLeads: 27,
  coworkers: 4,
);

// ---------------------------------------------------------------------
// §4.6 — Dashboard chart, 12-point "This month" series
// ---------------------------------------------------------------------

/// One day of §4.6's series — fixture-only, see this file's doc comment
/// for why there is no server-backed equivalent to decode into instead.
class WorkDashboardChartPoint {
  final int day;
  final int created;
  final int sold;

  const WorkDashboardChartPoint({
    required this.day,
    required this.created,
    required this.sold,
  });
}

/// §4.6's 12 rows verbatim ("Today is Day 12 of the current month").
const List<WorkDashboardChartPoint> workDashboardChartFixture = [
  WorkDashboardChartPoint(day: 1, created: 2, sold: 0),
  WorkDashboardChartPoint(day: 2, created: 1, sold: 0),
  WorkDashboardChartPoint(day: 3, created: 3, sold: 1),
  WorkDashboardChartPoint(day: 4, created: 0, sold: 0),
  WorkDashboardChartPoint(day: 5, created: 2, sold: 1),
  WorkDashboardChartPoint(day: 6, created: 1, sold: 0),
  WorkDashboardChartPoint(day: 7, created: 4, sold: 2),
  WorkDashboardChartPoint(day: 8, created: 1, sold: 0),
  WorkDashboardChartPoint(day: 9, created: 2, sold: 1),
  WorkDashboardChartPoint(day: 10, created: 1, sold: 0),
  WorkDashboardChartPoint(day: 11, created: 3, sold: 1),
  WorkDashboardChartPoint(day: 12, created: 2, sold: 1),
];
