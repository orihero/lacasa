/// Minimal `Ad`/`Lead` builders for `work_dashboard` widget tests — mirrors
/// `lib/shared/fixtures/work_seed_data.dart`'s own private `_ad`/`_lead`
/// JSON-map helpers, kept local to this test directory rather than reusing
/// the bundled fixtures (this suite must not depend on their exact values
/// staying unchanged).
library;

import 'package:lacasa_mobile/api/api.dart';

Ad testAd({
  required String id,
  String coworkerId = '',
  String stage = '1',
  String agentId = 'agent-1',
}) {
  return Ad.fromJson({
    'id': id,
    'title': 'Test listing $id',
    'city': 'Tashkent',
    'district': 'Chilonzor',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'repairment': null,
    'rooms': 3,
    'area': 60,
    'storey': 2,
    'floors': 9,
    'furniture': null,
    'hashtags': null,
    'price': 100000,
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
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}

/// [createdAt] defaults to *now*, not to a frozen constant, because
/// `coworkerStatRowsProvider` filters these events through
/// [isWithinTimeRange] against the dashboard's selected range — which
/// defaults to "This month". A fixed epoch (this used to be
/// `1700000000`, i.e. November 2023) falls outside every range but "All"
/// once wall-clock time moves past it, so every count the coworker
/// statistics section renders would silently collapse to 0 and the tests
/// asserting real counts would fail for a reason that has nothing to do with
/// what they are testing.
///
/// **`now`, not `now - 1h`.** The subtraction was the same class of mistake
/// the constant was, just rarer: run the suite at 00:30 local on the 1st and
/// every defaulted event lands at 23:30 on the last day of the *previous*
/// month, outside the default "This month" range — turning
/// `dashboard_screen_test.dart`'s "real Ads/Lead counts" case red once a
/// month, for half an hour, on whichever machine happened to be running.
/// Nothing about these events needs to be in the past, so nothing buys that
/// risk; [DateTime.now] is inside every range by construction. Same rule as
/// [testLead] below.
///
/// That filter used to be gated to live mode only — fixture mode skipped it
/// precisely so synthetic timestamps like the old constant would still show
/// up. The fixture repositories are gone and the gate with them (see
/// `dashboard_providers.dart`), so test data now has to carry timestamps
/// that are honestly recent instead of relying on the filter being skipped.
/// Pass [createdAt] explicitly to exercise a range boundary on purpose.
ActivityEvent testActivityEvent({
  required String id,
  required String coworkerId,
  int stage = 1, // adCreated
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.now();
  return ActivityEvent.fromJson({
    'id': id,
    'agentId': 'agent-1',
    'coworkerId': coworkerId,
    'adId': 'ad-x',
    'leadId': '',
    'stage': stage,
    'createdAt': {'seconds': at.millisecondsSinceEpoch ~/ 1000},
  });
}

/// [createdAt] defaults to *now*, for the same reason [testActivityEvent]'s
/// stopped being a frozen constant: `leadCount` in `coworkerStatRowsProvider`
/// now filters leads through `isWithinTimeRange` exactly like the Ads/Sales
/// columns beside it, so a frozen `1700000000` (November 2023) would fall
/// outside every range but "All" and collapse every Leads column to 0 for a
/// reason unrelated to what the test asserts. Pass [createdAt] explicitly to
/// exercise a range boundary on purpose.
///
/// **A real local `DateTime.now()`, deliberately.** This default was briefly
/// *noon UTC on today's local date* — a value chosen because it reads as the
/// same calendar day whether you look at its UTC fields or its local ones,
/// for every zone from UTC-12 to UTC+14. That was hedging against a real bug
/// in `isWithinTimeRange` (it compared the UTC fields of a
/// [dateTimeFromWireTimestamp]-decoded value against a *local* "now"), and
/// the hedge was worse than the bug: it made this whole suite structurally
/// incapable of noticing it, since no fixture could ever be built where the
/// two readings differed. The predicate now normalizes both sides with
/// `.toLocal()`, so an ordinary "now" is correct here, and the case the
/// hedge used to paper over is pinned on purpose by the early-morning /
/// late-evening tests in `dashboard_providers_test.dart`.
///
/// [active] is the server's archive/soft-delete flag and [status] the Kanban
/// outcome; `countActiveLeads` reads both, so a test proving the "Active
/// leads" tile excludes dead leads sets one or the other.
Lead testLead({
  required String id,
  String coworkerId = '',
  String status = 'new',
  String? callbackIso,
  bool active = true,
  DateTime? createdAt,
}) {
  final at = createdAt ?? DateTime.now();
  return Lead.fromJson({
    'id': id,
    'fullName': 'Test lead $id',
    'phone': '+998901234567',
    'email': null,
    'budget': 50000,
    'comment': 'Looking for a flat',
    'conversationComment': null,
    'status': status,
    'source': null,
    'callbackDate': callbackIso,
    'active': active,
    'agentId': 'agent-1',
    'coworkerId': coworkerId,
    'createdAt': {'seconds': at.millisecondsSinceEpoch ~/ 1000},
    'updatedAt': {'seconds': at.millisecondsSinceEpoch ~/ 1000},
  });
}

/// A signed-in agent whose [RealtorProfile.kind] is [realtorKind] — the one
/// thing `canManageCoworkersProvider` reads, and therefore the only thing
/// that decides whether `dashboard` renders its three coworker surfaces.
///
/// `setRole(UserRole.agent)` alone leaves `AuthSessionState.user` null, which
/// the predicate deliberately treats as "not known to be solo" (see its doc
/// comment) — so a test that wants the *solo* branch has to sign a real user
/// in. Built through [AuthUser.fromJson] rather than the constructor for the
/// same reason `coworker_test_data.dart`'s own builder is: the wire shape is
/// the thing this app actually receives, and a builder that skips it can
/// drift from it.
AuthUser dashboardAgent({
  RealtorKind? realtorKind,
  String id = 'agent-1',
  UserRole role = UserRole.agent,
}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': 'Javlon Rustamov',
    'email': 'javlon@lacasa.uz',
    'role': switch (role) {
      UserRole.agent => 'agent',
      UserRole.coworker => 'coworker',
      UserRole.user => 'user',
      UserRole.unknown => 'unknown',
    },
    'phoneNumber': null,
    'avatar': null,
    'agentId': role == UserRole.coworker ? 'agent-1' : null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': realtorKind == null
        ? null
        : {
            'kind': switch (realtorKind) {
              RealtorKind.solo => 'solo',
              RealtorKind.agency => 'agency',
              RealtorKind.unknown => 'unknown',
            },
            'status': 'approved',
            'agencyName': null,
            'officePhone': null,
            'teamSize': null,
            'appliedAt': null,
            'decidedAt': null,
          },
  });
}

/// Today at [hour]:[minute] in the **device's local zone** — for tests that
/// need a timestamp on a known local calendar day at a known local hour,
/// which is the only way to build a fixture whose UTC calendar day differs
/// from its local one on a machine in any zone but UTC.
///
/// `todayAtLocal(0, 30)` and `todayAtLocal(23, 30)` are the two ends worth
/// asserting: in any zone east of UTC the first crosses back over the date
/// line when encoded as UTC, and in any zone west of it the second crosses
/// forward, so a pair of assertions over both is zone-independent — one of
/// them exercises the mismatch wherever the suite runs, and in UTC itself
/// neither does, which is exactly right because there is nothing to
/// mismatch there. See `dashboard_providers_test.dart`'s "local calendar
/// day" group.
DateTime todayAtLocal(int hour, [int minute = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, hour, minute);
}
