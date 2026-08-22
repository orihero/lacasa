# Work Tab Build Contract

Foundation layer for SCREENS.md §21–§38 (the Work/CRM tab). Six feature agents build
against this document in parallel, each confined to their own `lib/features/<name>/`
directory. Everything shared already exists, compiles, and analyzes clean as of this
commit — you should not need to touch anything outside your own feature directory.

**Read this whole document before writing code.** It is the only coordination channel
between the six of you.

---

## 0. Hard rules

1. **Do not run** `flutter pub get`, `flutter test`, `flutter run`, or `flutter build`.
   Other agents are working in this package concurrently; those commands lock
   `.dart_tool/` and will corrupt concurrent work. `dart analyze <path>` is fine and
   expected before you consider your feature done.
2. **Do not edit** `lib/navigation/app_router.dart`, `lib/navigation/route_paths.dart`,
   `lib/navigation/placeholder_screen.dart`, anything under `lib/api/`, anything under
   `lib/theme/`, or `lib/shared/shared.dart`'s export list. These are foundation files;
   an integration pass (not you) flips each placeholder route to your real screen once
   you're done. If you find a genuine bug or gap in one of these, say so in your own
   return value — do not patch it yourself.
3. **One exception to rule 2**: `lib/features/filter/widgets/filter_sheet.dart` and its
   sibling files under `lib/features/filter/` are not one of the six feature
   directories below, but `my_listings` (feature B) is the one and only consumer of
   its already-documented, currently-unwired `isCrm` seam (Sort + Status fields for
   the CRM variant). Feature B may wire that seam inside `lib/features/filter/`. No
   other feature should touch `lib/features/filter/`.
4. **Do not add pubspec dependencies.** See §5 (Dependency decisions) for what was
   already decided and why — every picker/chart need in this build has a documented
   answer that adds nothing to `pubspec.yaml`.
5. Stay inside your own `lib/features/<name>/` and `test/features/<name>/` directories.
   If you need something another feature owns before it exists (there is exactly one
   such case — see §3.4, `showLeadDetailSheet`), write the import against the exact
   signature documented here and let it be a compile error until that feature lands;
   do not stub around it by copy-pasting their logic.
6. `dart analyze lib` must stay clean. `flutter_lints` only, no custom rules — `const`
   constructors and trailing commas everywhere, matching the rest of this codebase.
7. Every new widget needing test assertions carries a `ValueKey`, matching the rest of
   the app's convention (`find.text` alone is not enough for anything with dynamic or
   duplicable content).

---

## 1. Ownership map

| Feature dir | Owns | Screens (SCREENS.md §) |
|---|---|---|
| `lib/features/work_dashboard/` | Dashboard | 24 |
| `lib/features/my_listings/` | My Ads list (+ wiring `filter_sheet.dart`'s `isCrm` seam, see rule 3) | 25 |
| `lib/features/listing_editor/` | Create/Edit listing, publish-channels sheet, publish-status | 26, 27, 28, 29 |
| `lib/features/leads/` | Leads list, Kanban, lead-detail sheet, create-lead, kanban-move sheet | 30, 31, 32, 33, 34 |
| `lib/features/coworkers/` | Coworkers list, coworker-detail, add-coworker | 35, 36, 37 |
| `lib/features/work_misc/` | Connected accounts, notifications, messages | 21, 22, 23 |

Screen 38 (`delete-confirm`) is already built as a shared helper — `confirmDelete` in
`lib/shared/widgets/delete_confirm.dart` (§4 below). Nobody owns a "38" directory.

No file paths overlap between the six directories above. Each also gets a mirrored
`test/features/<name>/` directory, plus a `support/` subfolder for feature-local
fakes, per this app's existing test convention (see §6).

---

## 2. Screen-by-screen: file, class, constructor, how it's reached

Every screen widget goes in `lib/features/<owner>/widgets/`. The **exact class name**
matters — the integration pass wires these into `app_router.dart` mechanically by name,
it will not go hunting for a differently-named class.

| § | Screen id | Feature dir | File | Class | Constructor | Reached via |
|---|---|---|---|---|---|---|
| 21 | `connected-accounts` | `work_misc` | `widgets/connected_accounts_screen.dart` | `ConnectedAccountsScreen` | `const ConnectedAccountsScreen({super.key})` | `RoutePaths.workConnectedAccounts` **and** `RoutePaths.profileConnectedAccounts` (same widget, two routes — wired by the integration pass, not you) |
| 22 | `notifications` | `work_misc` | `widgets/notifications_screen.dart` | `NotificationsScreen` | `const NotificationsScreen({super.key})` | `RoutePaths.workNotifications` and (integration pass) `RoutePaths.homeNotifications` |
| 23 | `messages` | `work_misc` | `widgets/messages_screen.dart` | `MessagesScreen` | `const MessagesScreen({super.key})` | `RoutePaths.workMessages` and `RoutePaths.profileMessages` |
| 24 | `dashboard` | `work_dashboard` | `widgets/dashboard_screen.dart` | `DashboardScreen` | `const DashboardScreen({super.key})` | `RoutePaths.workDashboard` |
| 25 | `my-listings` | `my_listings` | `widgets/my_listings_screen.dart` | `MyListingsScreen` | `const MyListingsScreen({super.key})` | `RoutePaths.workMyListings` |
| 26 | `create-listing` | `listing_editor` | `widgets/create_listing_screen.dart` | `CreateListingScreen` | `const CreateListingScreen({super.key})` | `RoutePaths.createListing` (top-level modal, already declared) |
| 27 | `edit-listing` | `listing_editor` | `widgets/edit_listing_screen.dart` | `EditListingScreen` | `const EditListingScreen({super.key, required this.adId})` | `RoutePaths.workEditListing` (`:id` path param → `adId`) |
| 28 | `publish-channels-sheet` | `listing_editor` | `widgets/publish_channels_sheet.dart` | function `showPublishChannelsSheet` | `Future<void> showPublishChannelsSheet(BuildContext context, {required Ad ad})` | called from `create-listing`/`edit-listing`, **not a route** |
| 29 | `publish-status` | `listing_editor` | `widgets/publish_status_screen.dart` | `PublishStatusScreen` | `const PublishStatusScreen({super.key, required this.adId})` | `RoutePaths.workPublishStatus` (`:id` → `adId`) |
| 30 | `leads-list` | `leads` | `widgets/leads_list_screen.dart` | `LeadsListScreen` | `const LeadsListScreen({super.key})` | `RoutePaths.workLeads` |
| 31 | `leads-kanban` | `leads` | `widgets/leads_kanban_screen.dart` | `LeadsKanbanScreen` | `const LeadsKanbanScreen({super.key})` | `RoutePaths.workLeadsKanban` |
| 32 | `lead-detail` | `leads` | `widgets/lead_detail_sheet.dart` | function `showLeadDetailSheet` | `Future<void> showLeadDetailSheet(BuildContext context, {required String leadId})` | called from `leads-list`/`leads-kanban`/`notifications` (see §3.4), **not a route** |
| 33 | `create-lead` | `leads` | `widgets/create_lead_screen.dart` | `CreateLeadScreen` | `const CreateLeadScreen({super.key})` | `RoutePaths.workCreateLead` |
| 34 | `kanban-move-sheet` | `leads` | `widgets/kanban_move_sheet.dart` | function `showKanbanMoveSheet` | `Future<LeadWriteInput?> showKanbanMoveSheet(BuildContext context, {required LeadStatus destination})` | called from `leads-kanban`'s "Move to…" flow, **not a route** — see §3.4 for the exact return contract |
| 35 | `coworkers-list` | `coworkers` | `widgets/coworkers_list_screen.dart` | `CoworkersListScreen` | `const CoworkersListScreen({super.key})` | `RoutePaths.workCoworkers` |
| 36 | `coworker-detail` | `coworkers` | `widgets/coworker_detail_screen.dart` | `CoworkerDetailScreen` | `const CoworkerDetailScreen({super.key, required this.coworkerId})` | `RoutePaths.workCoworkerDetail` (`:id` → `coworkerId`) |
| 37 | `add-coworker` | `coworkers` | `widgets/add_coworker_screen.dart` | `AddCoworkerScreen` | `const AddCoworkerScreen({super.key})` | `RoutePaths.workAddCoworker` |
| 38 | `delete-confirm` | *(shared, already built)* | `lib/shared/widgets/delete_confirm.dart` | function `confirmDelete` | `Future<bool> confirmDelete(BuildContext context, {required String subject})` | call from any Delete button |

### 2.1 Routes added this pass (already wired to `PlaceholderScreen`, ready for you)

New `RoutePaths` constants (all under the Work branch unless noted), wired to
`_placeholder(...)` in `app_router.dart` when this pass was written — the integration
pass swapped each `builder:`/`pageBuilder:` line to the real class once each feature
landed, and every one of them now points at a real screen.

**The strings below are what `route_paths.dart` actually declares today** (re-read
against that file 2026-08-14), which for several of them is *not* what this pass
originally wrote. Every Work route is now nested under the branch root that owns it,
so a deep link — or a hardware Back — resolves to a stack with a real screen
underneath the top page instead of a lone page over a blank `/work`. Read paths from
the constants, never by retyping a literal.

```
RoutePaths.workCreateLead        = '/work/leads/create'
RoutePaths.workAddCoworker       = '/work/coworkers/create'
RoutePaths.workNotifications     = '/work/dashboard/notifications'  // reached from the
                                                          // header bell, and Dashboard
                                                          // is the branch that owns
                                                          // that header
RoutePaths.workMessages          = '/work/profile/messages'  // reached from
                                                          // profile-agent's row
RoutePaths.workListingDetail     = '/work/my-listings/listing/:id'  // my-listings' own
                                                          // listing-detail push target,
                                                          // this branch didn't have one
```

The constants themselves already existed for `work`, `workDashboard`, `workMyListings`,
`workLeads`, `workLeadsKanban`, `workCoworkers`, `workCoworkerDetail`, `workSettings`,
`workConnectedAccounts`, `workEditListing`, `workPublishStatus`, `createListing`
(top-level), `profileConnectedAccounts`, `profileMessages`, `homeNotifications` — but
several of *their* strings moved in the same re-parenting: `workSettings` is
`/work/profile/settings`, `workConnectedAccounts` is
`/work/profile/connected-accounts`, and `workEditListing`/`workPublishStatus` are
`/work/my-listings/edit-listing/:id` and `/work/my-listings/publish-status/:id`. `work`
itself (`/work`) is redirect-only and renders nothing: coworker → `workMyListings`,
agent → `workDashboard`.

> **Superseded since this pass was written:** `workEditListing` and `workPublishStatus`
> are no longer flat children of `/work`. Both are now declared under `my-listings` —
> `/work/my-listings/edit-listing/:id` and `/work/my-listings/publish-status/:id` — so
> the screen a Back press reveals is My Ads (filters and paged scroll position intact),
> not the blank `/work` placeholder that `_WorkPlaceholder` then bounced onward to
> Statistics. That placeholder widget is gone with it. Keep reading paths from the
> `RoutePaths` constants and nothing else has to change; the shape of the strings did.

**Sheets are never routes** — `lead-detail`, `kanban-move-sheet`, `publish-channels-sheet`,
`delete-confirm` are all `show...Sheet`/`show...Dialog` functions called directly from a
screen, exactly like the already-shipped `showFilterSheet` (`filter_sheet.dart`). Do not
invent a route path for any of these.

### 2.2 Cross-branch navigation rule (bell icon, Messages row)

`workNotifications`/`workMessages` are Work's own copies; `homeNotifications`/
`profileMessages` are Home's/Profile's. When a tap target is a Work-only concept
(`edit-listing`, `publish-status`, `coworker-detail` — all agent/coworker-only screens),
use `context.go(...)` to the absolute Work path, not `context.push`, regardless of which
branch you're pushing from — `push` only makes sense within one branch's own stack (see
every other branch's own `listing-detail`/`agent-profile` copies for the pattern this
follows). `notifications_screen.dart`'s `_handleTap` is the live example and stays on
`go`.

**Within a branch, `push` whenever the source screen has to still be there
underneath; `go` only for cross-branch entry by absolute path.** Nesting depth is not
the test — *what the user expects Back to reveal* is. `go` replaces the branch's whole
stack, so anything the source screen was holding goes with it, and it is never the
right call for a navigation the user will back out of.

Both of `my-listings`' children are that case and both **`push`**: the edit icon →
`workEditListing`, and `edit-listing`'s "Publish Status" link → `workPublishStatus`.
When those two were `go`n instead, (a) the very My Ads screen the user came from was
thrown away, filters and paging included, and (b) a *dirty* `edit-listing` form was
torn down with no "Discard changes?" prompt — `PopScope` is a pop-only hook and never
sees a replace. `dashboard`'s bell → `workNotifications` is the same shape one level
up and pushes for the same reason: the Dashboard is what a Back out of the bell should
reveal.

The one `go` in this branch's own code is the cross-branch case paragraph one
describes — `notifications_screen.dart`'s `_handleTap`, arriving from the Dashboard
branch at an absolute path in the My Ads or Coworkers branch. That is entry into a
different branch, not a step deeper into the current one, and it is why every Work
route is nested under its own branch root: the absolute path resolves to a real stack
(`[my-listings, edit-listing]`), so even a `go` — and a deep link, and a cold-start
restore — lands with a screen underneath it.

---

## 3. Cross-feature contracts (the parts you'll actually import from each other)

### 3.1 `filter_sheet.dart`'s `isCrm` seam (feature B only)

`showFilterSheet(context, initialFilters: ..., isCrm: true)` — already accepted and
threaded through `FilterSheet`, never yet branched on. My Ads (§25) needs the CRM
variant: the same fields as the buyer filter sheet, plus **Sort** (`newest` /
`highestPrice` / `lowestPrice`, matching `AdSort` in `agent_ads_resource.dart`) and
**Status** (`Active`/`Sold`/`Draft`, matching `AdStage`). Wire this inside
`lib/features/filter/widgets/filter_sheet.dart` (and any sibling section widget it
needs) — see rule 3 in §0.

### 3.2 `showPublishChannelsSheet` (feature C owns, feature C's own two screens call it)

Opened from both `create-listing` and `edit-listing`'s per-channel publish buttons.
Takes the `Ad` being published (needed for its photos/title/id to build the caption +
`imageUrls`). Internally should call `PublishResource.instagramAccounts()` (to decide
whether Instagram is offered / show the "no account connected" hint per §3.28) and, on
confirm, `PublishResource.publishInstagram`/`publishTelegram` per selected channel —
there is no multi-channel endpoint, see §7.3.

### 3.3 `showKanbanMoveSheet` (feature D owns, feature D's own kanban screen calls it)

```dart
Future<LeadWriteInput?> showKanbanMoveSheet(
  BuildContext context, {
  required LeadStatus destination,
})
```

Called only for `destination == LeadStatus.needToCallBack` or `.rejected`/`.accepted` —
`leads-kanban`'s move logic should skip this sheet entirely for `.newLead`/
`.couldNotConnect` (SCREENS.md §31/§34: those two moves are immediate). Returns:
- `null` if the user cancelled (card does not move).
- For `needToCallBack`: a `LeadWriteInput` with `status: OptionalField(destination)` and
  `callbackDate: OptionalField(pickedDateTime)` set — nothing else.
- For `rejected`/`accepted`: a `LeadWriteInput` with `status: OptionalField(destination)`
  and `conversationComment: OptionalField(theNoteText)` (≥10 trimmed chars — validate
  this inside the sheet before it can be submitted, per §34's own field rule) — nothing
  else.

The caller (`leads-kanban`) applies the optimistic-move + rollback-on-error dance itself
(see §7.5's ruling) and calls `LeadsResource.update(leadId, result)` with whatever this
returns.

### 3.4 `showLeadDetailSheet` (feature D owns; feature D's own two screens AND feature F's `notifications` screen call it)

```dart
Future<void> showLeadDetailSheet(BuildContext context, {required String leadId})
```

This is the **one** cross-feature dependency in this build that isn't a route. `leads`
(feature D) builds it; `work_misc`'s `NotificationsScreen` (feature F, §22's "lead
notification → lead-detail" tap target, SCREENS.md §22) needs to call it too, importing
`package:lacasa_mobile/features/leads/leads.dart`. If you are feature F and feature D
hasn't landed this file yet, this is a genuine, expected compile-time dependency — it is
not something to work around by duplicating the sheet's logic. Every other notification
tap target in §22 (sold → `edit-listing`, publish → `publish-status`, coworker activity
→ `coworker-detail`) is a **route** (`context.go` with a `RoutePaths` constant + the
target id), so this is the only place a direct cross-feature import is needed at all.

---

## 4. Full public API you're building against

### 4.1 API layer — `lib/api/api.dart` (barrel), already wired into `LaCasaApi`

```dart
class LaCasaApi {
  final ApiClient client;
  final AuthResource auth;
  final AdsResource ads;              // public buyer-facing GET /ads, GET /ads/:id only
  final SavedAdsResource savedAds;
  final AgentsResource agents;
  final ContactResource contact;
  final UsersResource users;

  // --- Work tab surface, added this pass ---
  final AgentAdsResource agentAds;     // my-ads list/stage-counts + ad create/update/delete
  final LeadsResource leads;
  final CoworkersResource coworkers;
  final StatisticsResource statistics;
  final PublishResource publish;
  final UploadsResource uploads;
  final InstagramAuthResource instagramAuth;
}
```

`import 'package:lacasa_mobile/api/api.dart';` exports every model and resource below —
you never need to import an individual `lib/api/models/*.dart`/`resources/*.dart` file
directly.

#### `AgentAdsResource` (`resources/agent_ads_resource.dart`)

```dart
enum AdSort { newest, highestPrice, lowestPrice }  // .wireOrNull for the query param

class AgentAdsResource {
  Future<List<Ad>> myList({AdFilters? filters, AdSort sort = AdSort.newest});
  Future<AdStageCounts> stageCounts();               // GET /my/ads/stage-counts
  Future<Ad> create(AdWriteInput input);             // POST /ads
  Future<Ad> update(String id, AdWriteInput input);   // PATCH /ads/:id
  Future<void> delete(String id);                     // DELETE /ads/:id, AGENT only
}
```
`AdFilters` is the existing buyer-facing filter class from `ads_resource.dart` — reused
as-is for `myList`'s query params (its own `agentId` field is ignored server-side on
this route). **No pagination exists** — `myList` always returns the complete list.

`AdStageCounts` (`models/ad_stage_counts.dart`): `{active, sold, draft}` ints, `.total`.

`AdWriteInput` (`models/ad_write_input.dart`) — the create/update body, ~25 fields, every
one wrapped in `OptionalField<T>` (`models/optional_field.dart`):
```dart
class OptionalField<T> {
  const OptionalField(T value);
}
```
- **Omit the named argument entirely** (Dart's own default, `null`) → key left out of
  the JSON body → server leaves that column untouched (only matters for `update`).
- **Pass `OptionalField(null)`** on a nullable field → key sent with JSON `null` →
  server clears it.
- **Pass `OptionalField(value)`** → key sent with that value.

`AdWriteInput` fields (all `OptionalField<T>?`, see the file for exact nullability per
field): `title, city, district, address, reference, type(AdType), category(AdCategory),
repairment(Repairment?), rooms, area, storey, floors, furniture(Furniture?), hashtags,
price, priceType(CurrencyCode), stage(AdStage), description, nearPlacesList(List<String>),
optionList(List<Map<String,Object?>>), active, lat, lng, tour3dLink, photos(List<String>)`.
Same class serves both `create` and `update` — nothing is server-required on either verb.
**`coworkerId` has no field on this class at all** — it cannot be set/reassigned via
write, matching the server (see `agent_ads_resource.dart`'s own doc comment).

#### `LeadsResource` (`resources/leads_resource.dart`)

```dart
class LeadsResource {
  Future<List<Lead>> list();                          // GET /leads, no pagination
  Future<Lead> getById(String id);
  Future<Lead> create(LeadWriteInput input);           // POST /leads
  Future<Lead> update(String id, LeadWriteInput input); // PATCH /leads/:id
  Future<void> delete(String id);                       // AGENT only
}
```
`LeadWriteInput` (`models/lead_write_input.dart`), same `OptionalField` convention:
`fullName, phone, email, budget, comment, conversationComment, status(LeadStatus),
source, callbackDate(DateTime?), active`. **Never pass `LeadStatus.unknown` to `status`**
— the server has no validation on this field and would silently store `"new"`.

`Lead` (`models/lead.dart`): `id, fullName, phone, email, budget, comment,
conversationComment, status(LeadStatus), source, callbackDate(DateTime?), active,
agentId, coworkerId(String, '' not null), createdAt, updatedAt`. Plus
`lead.isCallbackDueOrOverdue` (bool getter) — the shared "is this callback due today or
overdue" rule Dashboard and Kanban both need, already implemented, use it rather than
re-deriving.

**Timestamp trap**: `createdAt`/`updatedAt` are `{seconds}` (decoded automatically by
`Lead.fromJson`); `callbackDate` is a plain ISO string (also decoded automatically) —
you never need to touch `dateTimeFromWireTimestamp` yourself, `Lead.fromJson` already
picked the right decoder per field. Just know the two fields don't share a wire format
if you're ever debugging a raw response body by eye.

`LeadStatus` enum (`models/enums.dart`): `newLead, couldNotConnect, needToCallBack,
rejected, accepted, unknown` + `.wire`/`.fromWire` + `LeadStatus.kanbanOrder` (the fixed
5-element column order, [unknown] excluded).

#### `CoworkersResource` (`resources/coworkers_resource.dart`)

```dart
class CoworkersResource {
  Future<List<Coworker>> list();
  Future<Coworker> getById(String id);
  Future<Coworker> create({
    required String fullName, required String email, required String password,
    String? phoneNumber, String? avatar,
  });
  Future<Coworker> update(String id, {
    OptionalField<String>? fullName, OptionalField<String>? email,
    OptionalField<String?>? phoneNumber, OptionalField<String?>? avatar,
    OptionalField<String>? password,
  });
  Future<void> delete(String id);   // AGENT only
}
```
`Coworker` (`models/coworker.dart`): `id, fullName, email, phoneNumber, avatar, agentId`
— genuinely only these 5 fields, no `listingsCount`/`closed`/`lastActive` on this shape
itself; get those from `StatisticsResource.coworkersSummary()` instead (§7.6, superseded).

`create` 403s with `code: solo_realtor` for a SOLO agent — check
`AuthUser.realtor?.kind` (via `authSessionProvider`) to hide "+ Add new coworker"
entirely for a solo agent rather than let that 403 surface as a surprise.

#### `StatisticsResource` (`resources/statistics_resource.dart`)

```dart
enum StatisticsFilter { all, today, thisWeek, thisMonth }  // .wireOrNull

class StatisticsResource {
  Future<AdsStatistics> ads({StatisticsFilter filterType = StatisticsFilter.all});
  Future<AdsSeries> series({StatisticsFilter filterType, DateTime? from, DateTime? to});
  Future<List<ActivityEvent>> coworkers();   // ignores date range entirely, always all-time
  Future<List<CoworkerSummary>> coworkersSummary();   // ditto — always all-time
}
```
`AdsStatistics`: `{adsNewCount, adsSoldCount}` — a pair of totals for the whole selected
range, not a series. `AdsSeries`: `{granularity(hour|day), from, to, buckets}`, added this
run — see §7.1 (superseded), now the dashboard chart's real data source. `ActivityEvent`:
`{id, agentId, coworkerId, adId, leadId, stage(ActivityEventStage), createdAt}` — raw
rows, fold them yourself if you need something `coworkersSummary()` doesn't already give
you. `CoworkerSummary`: `{coworkerId, adsCreatedCount, adsSoldCount, leadsCreatedCount,
lastActiveAt(nullable)}`, added this run — see §7.6 (superseded).

#### `PublishResource` (`resources/publish_resource.dart`)

```dart
class PublishResource {
  Future<PublishAttemptResponse> publishInstagram({
    required String adId, required String caption, required List<String> imageUrls,
    List<String>? igUserIds,
  });
  Future<List<ConnectedInstagramAccount>> instagramAccounts();
  Future<DateTime?> instagramConsent();
  Future<PublishAttemptResponse> publishTelegram({
    required String adId, required String caption, required List<String> imageUrls,
    required List<String> chatIds,
  });
  Future<Publication> reportYoutube({
    required String adId, required PublishStatus status,
    String? externalId, String? externalUrl, String? errorMessage,
  });
  Future<AdPublishStatus> statusForAd(String adId);         // publish-status's data source
  Future<Map<String, List<ChannelStatus>>> statusForAds(List<String> adIds); // my-listings badges
}
```
`PublishAttemptResponse`: `{publication: Publication, results: List<PublishAttemptResult>}`
(`PublishAttemptResult`: `{target, ok, mediaOrMessageId, error}`). `AdPublishStatus`:
`{adId, channels: List<ChannelStatus>}`, always exactly 5 entries,
`Channel.allChannels` order, PENDING-synthesized. `statusForAds` does **not** synthesize
— an ad with zero attempts maps to `[]`, and each row there only has
`channel`/`status` populated (external url/id/timestamp/error are always `null` on that
one endpoint's response shape).

`Channel` enum: `telegram, instagram, youtube, olx, unknown` (`.wire` is the
raw upper-case string). `PublishStatus` enum: `pending, draftedAwaitingReview,
published, failed, unknown` (also raw upper-case on the wire).

#### `UploadsResource` (`resources/uploads_resource.dart`)

```dart
class UploadsResource {
  Future<PresignResult> presign({
    required String fileName, required String contentType, required String scope, // "ads"|"avatars"
  });
  Future<void> putBytes({
    required String uploadUrl, required List<int> bytes, required String contentType,
  });
}
```
`PresignResult`: `{uploadUrl, objectKey, publicUrl}`. Flow: `presign()` → `putBytes()`
with the returned `uploadUrl` → use `publicUrl` (not `uploadUrl`, not `objectKey`) as the
string you push into `AdWriteInput.photos`/`Coworker` avatar/etc. `putBytes` uses a bare
`Dio` instance internally (not `ApiClient`) — see the file's doc comment for why. **You
almost certainly cannot call this today** — see §5.2, there is no picker to get `bytes`
from in this build. The resource exists and is correct for when one lands.

#### `InstagramAuthResource` (`resources/instagram_auth_resource.dart`)

```dart
class InstagramAuthResource {
  Future<String> connectUrl();          // POST /auth/instagram/connect-url → the OAuth URL
  Future<void> disconnect(String igUserId);
}
```
See §5.3 for how to actually "open" that URL without `url_launcher`.

### 4.2 Shared widgets — `lib/shared/shared.dart` (barrel), new this pass

```dart
Future<bool> confirmDelete(BuildContext context, {required String subject});
// AlertDialog.adaptive, title "Delete $subject?" — pass "listing"/"lead"/"coworker".

Future<bool> confirmDiscardChanges(BuildContext context);
// AlertDialog.adaptive, "Discard changes?" / Cancel / Discard — call before popping any
// dirty form (create-listing, edit-listing, create-lead, add-coworker, coworker-detail).

class StatusPill extends StatelessWidget {
  const StatusPill({required String label, required StatusTone tone});
}
enum StatusTone { ok, info, warn, err, mute, accent }
class AdStagePill extends StatelessWidget { const AdStagePill({required AdStage stage}); }
class LeadStatusPill extends StatelessWidget { const LeadStatusPill({required LeadStatus status}); }
class PublishStatusPill extends StatelessWidget { const PublishStatusPill({required PublishStatus status}); }

abstract final class LaCasaToast {
  static void showPending(BuildContext context, String message);
  static void showSuccess(BuildContext context, String message);
  static void showError(BuildContext context, String message);
  static Future<T> run<T>({
    required BuildContext context, required Future<T> Function() action,
    required String pending, required String success,
    String Function(Object error)? errorMessage,
  });
}

class CrmListTile extends StatelessWidget {
  const CrmListTile({
    required Widget leading, required String title, String? subtitle,
    Widget? trailing, VoidCallback? onTap,
  });
}
// Leading is rendered 44x44, clipped rounded — pass a small ListingPhoto/AgentAvatar.
// Use for my-listings rows, leads-list rows, coworkers-list rows.

const String kMediaUploadUnavailableMessage; // "Photo upload isn't available in this build yet."
class MediaUploadUnavailableNotice extends StatelessWidget {
  const MediaUploadUnavailableNotice({String label = 'Photo upload'});
}
void showMediaUploadUnavailableToast(BuildContext context, {String label = 'Photo upload'});
```

Already existed, reuse rather than reinvent (see the original conventions survey for
full constructors): `ListRow`/`ListRowGroupLabel`, `AgentAvatar`, `ListingPhoto`,
`CompactListingCard`/`FullListingCard`, `PricePill`, `FavouriteButton` (hide it on CRM ad
cards — it's a buyer affordance, check role), `ShimmerBox`/`RailRetryCard`/
`FullWidthState` (empty-state copy is **"No listings found"** for ads; SCREENS.md
overrides this per-screen for §25 "Ads not found."/§30 "No leads yet."/§35 "No coworkers
yet." — use the screen's own §3 copy, not the generic shared-widget default, wherever
SCREENS.md states one), `SectionHeader`, `confirmSignOut`/`confirmAndSignOut`,
`Formatters` (`groupedPrice`, `price`, `date`, `isValidUzPhone`, `adIdBadge`, `rooms`,
`area`, `floor`, `statLine`, `trimNum`).

### 4.3 Fixtures — `lib/shared/fixtures/work_seed_data.dart` (exported from `shared.dart`)

```dart
final List<Ad> workAdsFixtures;                 // all 8, every stage, §4.1
final List<Lead> workLeadsFixtures;              // 6, §4.2
final List<AgentDetail> workAgentsFixtures;      // 3 real agents, §4.3
final List<Coworker> workCoworkersFixtures;      // 2 coworkers, §4.3
final List<ActivityEvent> workStatisticsCoworkersFixture; // backs the 2 coworkers' counts
enum WorkNotificationKind { lead, publish, sold, coworkerActivity }
class WorkNotificationFixture { id, kind, title, relativeTime, unread, targetId; }
final List<WorkNotificationFixture> workNotificationsFixture; // 5, §4.4
class WorkDashboardStatsFixture { adsCreatedThisMonth, adsSoldThisMonth, activeLeads, coworkers; }
const workDashboardStatsFixture;                 // §4.5
class WorkDashboardChartPoint { day, created, sold; }
const List<WorkDashboardChartPoint> workDashboardChartFixture; // 12 points, §4.6
```

IDs you can rely on across every fixture list: agents `agent-javlon`/`agent-shahnoza`/
`agent-otabek`; coworkers `coworker-sardor` (under `agent-javlon`)/`coworker-kamola`
(under `agent-shahnoza`); ads `ad-1001`..`ad-1008`; leads `lead-2001`..`lead-2006`.

**Divergence from `features/home/data/home_feed_fixtures.dart` worth knowing**: that
file's `ad-1006`/`ad-1008` use `agentId: 'agent-sardor'`/`'agent-kamola'` (a
documented simplification for the public agents-only feed). This file's copies of the
same two ads use the real pairing instead — `agentId: 'agent-javlon'`/`'agent-shahnoza'`
+ `coworkerId: 'coworker-sardor'`/`'coworker-kamola'`. Use **this** file's version for
anything Work-tab; don't cross-reference Home's ad list for Work screens.

Each of your six features still builds its **own** `fixture_<feature>_repository.dart`
per this app's convention (see §6) — you slice/filter these shared lists yourself
(e.g. `leads`'s fixture repo returns `workLeadsFixtures` as-is; `coworkers`'s combines
`workCoworkersFixtures` with counts derived from `workAdsFixtures`/
`workStatisticsCoworkersFixture`).

---

## 5. Dependency decisions

**No `pubspec.yaml` changes were made in this pass.** Every picker/chart need in
screens 21–38 has a decided, dependency-free answer:

### 5.1 Charting (§24 dashboard)

**No charting package added.** The real reason: `GET /statistics/ads` returns two
aggregate totals for the whole selected period, not a bucketed daily series — there is
no server endpoint to actually drive a 12-point area chart from (see §7.1). Since the
chart can only ever be fixture data or a client-side fold of `ActivityEvent` rows
anyway, build it with plain Flutter primitives — a row of `Container`s sized by height
(bar chart) or a small `CustomPainter` (area/line) is entirely sufficient for 12 points
and matches `apps/console`'s own choice to hand-draw a much simpler 2-bar comparison
rather than pull in a charting library for one screen.

### 5.2 Photo/video/avatar pickers (§26, §27, §36, §37)

**No `image_picker`/`file_picker` added.** This exact call was already made for
`edit-profile`'s avatar control (`features/edit_profile/widgets/edit_profile_screen.dart`)
and for camera/photo permissions (`features/permissions/data/permission_gateway.dart`).
Adding a picker plugin without the native `Info.plist`/`AndroidManifest.xml`
declarations it needs is worse than not shipping it — use
`lib/shared/widgets/media_upload_unavailable_notice.dart`'s
`MediaUploadUnavailableNotice` widget (a caption) and `showMediaUploadUnavailableToast`
(the tap handler) wherever SCREENS.md describes a photo/video/avatar picker control.
`UploadsResource` (§4.1) is still real and correct — it's just not reachable without
bytes to hand it, which is exactly the gap this notice is honest about.

### 5.3 Opening the Instagram OAuth URL (§21)

**No `url_launcher` added.** This is a Work-specific instance of the app-wide "no
url_launcher" gap already documented (every `tel:`/share-sheet affordance in the
already-shipped screens 1–20 copies to clipboard instead of launching). Apply the same
pattern: `InstagramAuthResource.connectUrl()` returns the OAuth URL; copy it to the
clipboard with `Clipboard.setData(ClipboardData(text: url))` (`package:flutter/services.dart`
— no new dependency) and show a toast/snackbar telling the user to paste it into their
browser. Do **not** attempt any in-app `WebView` — SCREENS.md §21 explicitly forbids
that regardless of tooling.

### 5.4 Raw file PUT to the presigned upload URL

Uses `dio` directly (`UploadsResource.putBytes`), which is already a pubspec dependency
via the existing `ApiClient`/`DioTransport` stack — nothing new here either.

**If you believe your screen genuinely cannot be built without a new dependency**,
say so explicitly in your own return value with your reasoning — do not add it to
`pubspec.yaml` yourself.

---

## 6. Conventions digest (condensed — see your own judgment calls against real files, not just this summary)

**Feature directory shape** (mirrors `lib/features/home/`, `lib/features/saved_listings/`):
```
lib/features/<name>/
  <name>.dart                       # barrel, exports only widgets/<root_screen>.dart(s)
  data/
    <name>_repository.dart          # abstract interface, throws ApiException subtypes only
    live_<name>_repository.dart     # thin adapter over LaCasaApi, the only impl
  state/
    <name>_repository_provider.dart # Provider<XRepository> building the live impl
    <name>_providers.dart           # AsyncNotifier/FutureProvider/Notifier providers
  widgets/
    ...screen + supporting widgets
```
One `*_mode.dart` dart-define switch **per feature**, always defaulting OFF (fixtures) —
this app must render sensibly with zero network, always. If two of your own screens
(e.g. `create-listing`+`edit-listing` in `listing_editor`) share one repository, one
mode switch for the whole feature dir is correct; don't invent per-screen switches.

**Riverpod** (`flutter_riverpod: ^3.4.2`, no codegen, no `StateNotifierProvider`):
- Plain `Provider` — repository selection (fixture vs live).
- `AsyncNotifierProvider` — a list load plus real mutations/retries (e.g. Leads list
  with create/update/delete all going through the same notifier).
- `FutureProvider.autoDispose.family<T, String>` — a pushed/detail screen keyed by id
  where the only operation is "load, redo via `ref.invalidate`" (e.g.
  `EditListingScreen`/`CoworkerDetailScreen`/`PublishStatusScreen`'s own detail fetch).
- Plain `Notifier` — local synchronous UI state (selected Kanban filter, form dirty
  flag, etc).
- **Independent providers per independently-failable section** — Dashboard's 4 stat
  tiles + chart + coworker table should be 4+ separate providers, not one blob; a
  failing coworker-stats fetch must not blank the ad stat tiles.
- Async state via `.when` at the widget/rail level: loading → `ShimmerBox`, error →
  `RailRetryCard`/`FullWidthState` + `ref.invalidate(...)`, data → empty-check → content.

**Router** — see §2 above; you never edit `app_router.dart`/`route_paths.dart`
yourself. `branchPrefix` pattern: any screen your feature pushes further under
`/work/...` should accept a `branchPrefix` param defaulting to `RoutePaths.work`,
mirroring `ListingDetailScreen`/`AgentProfileScreen`'s existing convention.

**Theme tokens** (`lib/theme/theme.dart` barrel): `Theme.of(context).extension<LaCasaColors>()!`
(`ink, ink2, muted, faint, screen, card, sunk, line, pill, pillInk`),
`Theme.of(context).extension<LaCasaTypography>()!` (`display, sectionHeading, sheetTitle,
navTitle, cardTitle, rowTitle, body, bodySmall, label, caption, micro, ...` — see
`app_typography.dart`, `LaCasaTypography.tabular(style)` for price/count figures),
`AppSpacing` (`xs=4,sm=6,md=8,base=12,lg=16,xl=20,xxl=22`), `AppRadii` (`sm=12,md=16,
card=20,cardLg=22,sheet=32,pill=BorderRadius.circular(9999)`), `AppShadows`,
`AppStatusColors` (flat, non-themed — `successText/Bg, warningText/Bg, errorText/Bg,
infoText/Bg, dangerBorder, dangerIconBg, accentStatusBg, ratingStar`), `GlassSurface` +
`GlassVariant` (`onSurface`/`onPhoto`/`flatForm`) — **never nest `GlassSurface`s**; any
scrollable containing one needs `ScrollConfiguration(behavior: const
MaterialScrollBehavior().copyWith(overscroll: false))` (Android stretch-overscroll
black-render bug). Glass renders as a flat frosted fallback under Skia/`flutter test` —
that is not evidence of on-device appearance.

**Formatters** (`Formatters` in `lib/shared/formatters/formatters.dart`, already
exported via `shared.dart`): `groupedPrice(Ad)`, `price(Ad)`, `date(DateTime)` (
`DD.MM.YYYY | HH:MM`), `isValidUzPhone(String)` (`^\+998\d{9}$`), `adIdBadge(String id)`
(`#` + first 5 chars — needed by `my-listings`), `rooms/area/floor/statLine/trimNum`.
No lead-stage/publish-status label formatter needed — use `LeadStatusPill`/
`PublishStatusPill`/`AdStagePill` (§4.2), which already own that vocabulary.

**Tests**: `test/features/<name>/...` mirrors `lib/features/<name>/...`, plus a
`support/` folder for fakes. `group('<behavior category>', () { testWidgets(...) })` —
group by behavior (`'happy path'`, `'empty state'`, `'error state'`), not by widget
name. Fakes implement the abstract repository interface, take optional `Object? xError`
fields, track call counts. Screens pumped via a local
`pumpXScreen(tester, {required FakeXRepository repository})` helper building a
`ProviderContainer(retry: (retryCount, error) => null, overrides: [...])` inside
`UncontrolledProviderScope(child: MaterialApp(theme: AppTheme.light(), home: ...))`.
`retry: (_, _) => null` is load-bearing (disables Riverpod 3's auto-retry backoff so
error-state assertions stay deterministic). `test/phone_width_overflow_test.dart` pumps
the whole app at 3 fixed sizes and asserts zero overflow — your screens are
automatically exercised by it **once wired into the router** (which you don't do), but
must genuinely not overflow at 360×800 regardless.

---

## 7. Server-vs-spec divergences and rulings

These are real gaps between SCREENS.md's ask and what `apps/api`/`apps/console`/
`apps/web` actually support. Build against the **ruling**, not the literal spec text,
in every case below.

**7.1 — CLOSED. Dashboard chart now has a server-backed bucketed series.**
`GET /statistics/ads/series?filterType=|from=&to=` now exists and returns a real,
server-bucketed day/hour series (`granularity` field), zero-filled per bucket. **Ruling
(superseded)**: both modes plot this one endpoint through `DashboardRepository.fetchAdsSeries`
— fixture mode builds its `AdsSeries` from `workDashboardChartFixture` (§4.3) instead of
reading it directly, live mode calls the real endpoint, and `ads_statistics_panel.dart`'s
`CustomPainter` renders whichever `AdsSeries` it's handed, formatting axis labels by
`granularity` rather than assuming a daily series. The old "fold `GET /statistics/coworkers`
yourself, or degrade to a 2-bar comparison" advice below no longer applies to this screen —
kept only as a record of what the gap used to require before this endpoint existed.

**7.2 — `GET /statistics/coworkers` ignores `filterType` entirely.** Always returns the
agent's full, unfiltered event history regardless of Dashboard's time-range selector.
**Ruling**: filter `ActivityEvent.createdAt` client-side yourself if the selector needs
to actually narrow the coworker section; do not pass a `filterType` to this endpoint
expecting it to do anything (`StatisticsResource.coworkers()` takes no such param at
all — this is already reflected in the resource's own signature).

**7.3 — PARTIALLY CLOSED (2026-08-11). A dedicated retry endpoint now exists for
Telegram/Instagram; the "publish to N at once" gap stands.** `POST
/publish/ads/:adId/:channel/retry` replays the exact original request stored on the
FAILED row server-side — a genuinely different call from a fresh
`publishInstagram`/`publishTelegram`, which is what made "do not wire Retry, it can't be
distinguished from a fresh publish" the right call originally. **Ruling (superseded for
Telegram/Instagram)**: `publish-status`'s "Retry" (§29) is real and tappable for those two
channels (`PublishResource.retry`), surfacing each of the endpoint's distinct rejection
codes (`already_published`/`awaiting_review`/`not_failed`/`retry_unavailable`/
`retry_in_progress`) as its own message rather than one generic "failed" toast. **Still
true, unchanged**: `publish-channels-sheet` (§28) still has no multi-channel "publish to
N at once" endpoint, so "Publish" still fans out one call per selected channel; YouTube
(no direct-publish call, only `reportYoutube`) and OLX (needs the desktop extension) stay
visibly disabled — Retry has nothing to replay for either, since neither channel's FAILED
row (if one existed) would have a stored request behind it the way Telegram/Instagram's do.

**7.4 — Create/edit-listing: build the full spec field set, not console's reduced one.**
`apps/console`'s own editor drops Address, Reference, Nearby chips (`nearPlacesList`),
Additional Info (`optionList`), and video upload — all of which `AdWriteInput` (§4.1)
fully supports on the wire (they're real fields on `adInputSchema`, just unused by
console's UI). **Ruling**: build SCREENS.md §26's full 4-field-group set; every field
maps directly onto an `AdWriteInput` field, nothing here is aspirational.

**7.5 — Kanban move: replicate console's optimistic-then-confirmed-clear mechanism.**
Apply a local status override the instant a move is confirmed (before the `PATCH`
resolves); clear the override immediately + show a "Couldn't move — try again" note on
that one card if the mutation fails; **do not** clear the override synchronously on
success — instead clear it once the provider's own re-fetched `leads` list independently
agrees with the new status, avoiding a flicker-back to the old column before the real
data catches up. This is `apps/console`'s own `KanbanScreen.tsx` mechanism, worth
replicating exactly rather than reinventing.

**7.6 — CLOSED. `GET /statistics/coworkers/summary` now serves the fold server-side,
including "Sale count".** `Coworker` still carries none of `listingsCount`/`closed`/
`lastActive` on its own wire shape — that part of the original ruling stands. But
`GET /statistics/coworkers/summary` now returns one row per coworker
(`adsCreatedCount`/`adsSoldCount`/`leadsCreatedCount`/`lastActiveAt`, the last genuinely
nullable for a coworker with no tracked events — never fabricate a date for it). **Ruling
(superseded)**: `coworkers-list`/`coworker-detail` read `adsCreatedCount`/`lastActiveAt`
from this one endpoint (`CoworkersRepository.summary`) instead of folding
`AgentAdsResource.myList()`/`StatisticsResource.coworkers()` client-side. **"Deals
closed"/"Sale count" is real too, and was wrongly read as ungettable** — no `LeadStatus
.SUCCESS`-shaped status exists, that much was correct, but `ActivityEventStage.adSold`
events always carried `coworkerId`; `dashboard`'s coworker table folds that stage from
the same event stream it already reads for "Ads count" (`CoworkerStatRow.saleCount`,
`state/dashboard_providers.dart`), and `summary`'s own `adsSoldCount` field covers the
same figure server-side. Render `0`, not an em-dash, for a coworker whose real count is
genuinely zero — an em-dash is now reserved for a fetch that hasn't resolved.

**7.7 — CLOSED. `my-listings` now has a real pagination contract.** `GET
/my/ads?paged=true&limit=&cursor=&stage=` returns `{ items, nextCursor }` — the same
opt-in envelope `GET /ads` gained for `listing-search` — instead of the old bare,
complete-list-only array. **Ruling (superseded)**: `AgentAdsResource.myListPage` sends
real keyset paging (and a real `stage` filter) server-side; `MyListingsResultsNotifier
.loadMore` (`state/my_listings_providers.dart`) fetches genuinely-unfetched pages, not a
client-side reveal over an already-complete list. `AgentAdsResource.myList()` (the old
bare-array method) still exists and is still used where the caller genuinely wants
everything at once with no paging (`dashboard`'s stat folding) — the two are now separate
methods with separate return types, not one method with a runtime branch.

**7.8 — CLOSED. `Lead.coworkerId` is real and resolvable — the original refusal was
wrong.** The original ruling (below, superseded) claimed `Lead` carries no
agent/coworker identity distinct from the signed-in session's own scope. That premise
doesn't hold: `Lead.coworkerId` (`leadService.js#serializeLead`, same
empty-string-means-none convention as `Ad.coworkerId`) is set from the acting user on
create when they're a COWORKER, and `GET /coworkers` resolves it for **either** role —
an AGENT sees their team, a COWORKER sees their siblings — via `coworkersListProvider`
(`features/coworkers/state/coworkers_providers.dart`), the same plain, already-cached
provider `coworkers-list` itself reads, so resolving it here triggers no fetch of its
own. And since leads are agent-scoped, not coworker-scoped
(`leadService.js#listLeads`), a coworker's board shows the *whole team's* leads —
resolving the id is the only place on that board that tells them who owns a card,
information genuinely unavailable anywhere else on it. **Ruling**: `kanban_card.dart`
renders the footer's coworker half whenever `Lead.coworkerId` is non-empty, omits it
outright when empty (a solo agent's — and a lone coworker's — leads always are, and the
coworkers feature is hidden for that session anyway), and degrades to just the
created-at half — never a placeholder identity, never a spinner — while the roster is
loading or has failed to load.

**Ruling (superseded)**: `Lead` carries no agent-identity field distinct from its own
`agentId`/`coworkerId` — every lead is already scoped server-side to the signed-in
agent, so SCREENS.md §31's "coworker avatar/name" footer slot has nothing real to bind
for an agent's own view. Omit that slot rather than fabricate an avatar; keep the
created-at timestamp half of the footer (real: `Lead.createdAt`).

**7.9 — Instagram connected-account fields ARE real, use them.** `media_count`/
`followers_count`/`follows_count`/`profile_picture_url` are genuine optional fields on
`GET /publish/instagram/accounts` (`ConnectedInstagramAccount`, §4.1) —
`apps/console` simply never renders them. **Ruling**: render §21's "Posts {…} / Followers
{…} / Following {…}" whenever present, hide the row/field when absent (they're
optional because the underlying Graph API call can itself fail independent of a valid
token) — this is a real win, not a gap to work around.

**7.10 — Telegram/YouTube connected-account cards have no backing data at all.**
`AuthUser.tgChatIds.length` (a bare count) is the *only* Telegram data that exists
anywhere — no per-channel avatar/title/`members_count`. YouTube has zero backing
data or OAuth route. **Ruling**: render Telegram as a count-only row (no per-channel
cards, no disconnect action — matches SCREENS.md §21's own "(no disconnect action)"
note for Telegram) and YouTube as a visibly-disabled "Add account"/"Sign out" pair with
a "Beta — not available in this build" note, exactly like OLX's own always-disabled
treatment elsewhere in the app.

**7.11 — CLOSED. `GET /notifications` now exists; no client-side synthesis needed.**
A real `notifications` route/service exists server-side (still no `Notification` table —
it's derived per-request from leads/ad-lifecycle/coworker/publish activity, but that's
now the *server's* derivation to own, not this client's). **Ruling (superseded)**:
`LiveNotificationsRepository` calls the endpoint directly (`NotificationsResource.fetch`)
instead of folding `GET /leads` + `GET /my/ads` + `GET /statistics/coworkers` +
`GET /coworkers` itself — which also closes the old synthesis's real limitation of only
covering 3 of SCREENS.md §4.4's 4 kinds (`publish` needed a `lastAttemptAt` the old
client-side fold had no way to get; the server's own implementation reads it directly).
`unread` is a snapshot the server computes against whatever `since` the caller sends, not
a stored flag — this client persists its own client-side read-state watermark
(`notifications_watermark_repository.dart`) across visits to give `since` a real value.

**7.12 — Currency default: `uzs`, not console's `usd`.** SCREENS.md §26 specifies
`uzs` ("so'm") as `create-listing`'s default `priceType`; `apps/console`'s own form
defaults to `usd`. **Ruling**: follow the spec — default to `uzs`. This is a one-line
form-state default, not a data-availability question.

**7.13 — Threads / Facebook Marketplace / X / LinkedIn are display-only channels, and
`Channel` now carries two kinds of member.** The product wants these four named on the
publish surfaces and on `connected-accounts`. `apps/api` has nothing behind any of them:
no route, no `Channel` Postgres-enum value, no credentials — and the server is not being
changed for this. **Ruling**: they are added to the `Channel` enum and to every app-side
channel surface, rendered in the app's established visibly-disabled state — the exact
treatment ruling 7.10 gave YouTube and §7.3 gave OLX — each with its own honest,
localized reason (`listingEditor<Name>UnavailableHint`,
`connectedAccounts<Name>UnavailableNoteMessage`). No connect flow, no enabled control, no
invented endpoint.

The load-bearing half of this ruling is the list boundary in `lib/api/models/enums.dart`.
`Channel.allChannels` is a description of *someone else's* response — it mirrors the
server's `ALL_CHANNELS`, which drives `GET /publish/ads/:adId/status`, and the server
synthesizes a `PENDING` placeholder row for every entry with no publish attempt. It stays
**frozen at exactly four members in exactly their current order** (`telegram`,
`instagram`, `youtube`, `olx`). A second, app-only list —
`Channel.publishSurfaceChannels` — describes *our own UI*: eight entries in publish-row
render order, excluding `unknown` (a decode fallback). Appending the four new members to `allChannels` instead would give
every ad four permanently-PENDING status rows that no action in the app could ever
clear. `test/api/channel_display_list_test.dart` pins both lists, and
`publish_status_screen_test.dart`'s "exactly 4 channel rows" assertion is the
second tripwire — if it ever sees eight rows, the two lists were merged.

Three consequences follow from the four members having no server representation, and all
three are deliberate: `Channel.fromWire` gains **no** cases for them (the server can never
send those strings, so a `FAILED`/`PENDING` row for one of these channels is formally
unreachable — which is also why they get no `NonRetryableReason` copy); `Channel.wire` and
`publish_resource.dart`'s `_retryChannelSegment` gain arms that **throw**, following
`Channel.unknown`'s own precedent in `wire`, because `wire`'s invariant across that file
is "returns a string the live API understands" and returning `'THREADS'` would break it
silently; and enabled-vs-disabled is expressed by one documented predicate,
`Channel.hasServerPublishPath` (true only for `telegram`/`instagram`), so the surfaces
branch on a fact about the API rather than on a hardcoded `enabled: false` repeated per
row. Note `hasServerPublishPath` is **not** interchangeable with
`publish_status_screen.dart`'s `_isRetryableChannel`: they list the same members today and
ask different questions (a retryable row also needs a stored original request
server-side). OLX behaviour is untouched by this ruling.

---

## 8. Known risks for the integration pass (not blocking, but flag if you hit them)

- The one cross-feature import (`showLeadDetailSheet`, §3.4) means `work_misc`
  (feature F) cannot fully compile in isolation until `leads` (feature D) exists. If
  you're feature F and this blocks you, write the call against the documented signature
  anyway and note the dependency in your own return value — do not stub it out.
- `filter_sheet.dart`'s `isCrm` seam (§3.1) is the one sanctioned edit outside your own
  feature directory. If `my_listings` (feature B) and nobody else touches
  `lib/features/filter/`, there's no collision; if you're not feature B, leave it alone
  entirely.
- `ConnectedAccountsScreen`/`MessagesScreen` are each reached from two different
  `RoutePaths` constants (`workX` and `profileX`) — build the widget itself with no
  assumption about which branch it's mounted under; the integration pass wires both
  routes to the same class, you don't need a `branchPrefix` for either since neither
  pushes anything further per SCREENS.md §21/§23.
