/// Every route path in the app, in one place, so `app_router.dart` and any
/// widget that needs to navigate (`context.go`/`context.push`) share the
/// exact same strings — no route typo'd differently in two files.
///
/// Grouped by shell branch per the build spec's route tree; top-level
/// (root-navigator) routes listed last.
abstract final class RoutePaths {
  // ---- Branch 0: Home -------------------------------------------------
  static const home = '/home';
  static const homeListingDetail = '/home/listing/:id';
  static const homeAgentProfile = '/home/agent/:id';
  static const homeNotifications = '/home/notifications';

  // ---- Branch 1: Search -------------------------------------------------
  static const search = '/search';
  static const searchAgentProfile = '/search/agent/:id';
  static const searchListingDetail = '/search/listing/:id';

  // ---- Branch 2: Work ----------------------------------------------------
  // `/work` itself is redirect-only (see app_router.dart's `_redirect`):
  // coworker -> workMyListings, agent -> workDashboard.
  static const work = '/work';
  static const workDashboard = '/work/dashboard';
  static const workMyListings = '/work/my-listings';
  static const workLeads = '/work/leads';
  static const workLeadsKanban = '/work/leads/kanban';

  // `create-lead` (§33) is a PUSHED screen (SCREENS.md §1's pushed list),
  // reachable from both `workLeads` and `workLeadsKanban`'s "+ Add new
  // lead" button — nested under `leads` (a sibling of `kanban`) rather
  // than duplicated under both, since both parents push the identical
  // route. `lead-detail` (§32) and `kanban-move-sheet` (§34) are bottom
  // sheets, not routes — no path constant for either, matching
  // `filter-sheet`'s own convention (opened via a `show...Sheet` function,
  // never `context.push`).
  static const workCreateLead = '/work/leads/create';
  static const workCoworkers = '/work/coworkers';

  // `add-coworker` (§37) is PUSHED, same reasoning as [workCreateLead]
  // above — nested as a sibling of `:id` under `coworkers`. Declared
  // before `:id` in `app_router.dart`'s route tree for the same reason
  // `agentsListingDetail` is declared before `agents/:id` there: a static
  // segment must be matched before a same-position dynamic one.
  static const workAddCoworker = '/work/coworkers/create';
  static const workCoworkerDetail = '/work/coworkers/:id';
  static const workSettings = '/work/settings';
  static const workConnectedAccounts = '/work/connected-accounts';
  static const workEditListing = '/work/edit-listing/:id';
  static const workPublishStatus = '/work/publish-status/:id';

  // `notifications` (§22) and `messages` (§23) are each reachable from
  // more than one branch in SCREENS.md — `notifications` from "Bell icon
  // (any header)", `messages` from `profile-agent`'s row. Home already has
  // its own `homeNotifications`/`profileMessages` below; these are the
  // Work branch's own copies, so a bell/Messages tap from inside `/work/*`
  // (e.g. `dashboard`'s header) pushes into the Work tab's own back stack
  // instead of crossing into another tab — the same `branchPrefix`
  // reasoning `agentsListingDetail`'s note documents, applied to these two
  // instead of `listing-detail`.
  static const workNotifications = '/work/notifications';
  static const workMessages = '/work/messages';

  // `my-listings`' row tap (outside thumbnail/edit icon) pushes
  // `listing-detail` (§25) — every other branch already carries its own
  // copy of this route (see [agentsListingDetail]'s note on why); Work's
  // was missing until this pass added it.
  static const workListingDetail = '/work/listing/:id';

  // ---- Branch 3: Agents --------------------------------------------------
  static const agents = '/agents';
  static const agentProfile = '/agents/:id';

  // `agent-profile`'s "Ads List" grid pushes a listing, and a pushed screen
  // stays in the back stack of the tab it was opened from (SCREENS.md §1),
  // so this branch needs its own copy of `listing-detail` — the same reason
  // Home and Search each declare one. It does not collide with
  // [agentProfile]: three path segments versus two.
  static const agentsListingDetail = '/agents/listing/:id';

  // And that listing's own agent block pushes back out to a profile, using
  // the same `{branchPrefix}/agent/:id` shape every branch honours (see
  // `listing_detail_screen.dart`). Redundant with [agentProfile] as a
  // *destination* — both render `AgentProfileScreen` — but not as a
  // *path*: `listing-detail` builds its target from the branch prefix it
  // was handed and cannot special-case one branch without the prefix
  // contract meaning something different per branch.
  static const agentsAgentProfile = '/agents/agent/:id';

  // ---- Branch 4: Profile (one route; content switches on role) -----------
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileSaved = '/profile/saved';
  static const profileSettings = '/profile/settings';

  // `saved-listings`'s card grid pushes a listing, exactly like `/home`,
  // `/search` and `/agents` each do for their own tab — see
  // `agentsListingDetail`'s note above on why a pushed screen needs its own
  // per-branch copy of this route rather than sharing one of the others.
  static const profileListingDetail = '/profile/listing/:id';

  // `profile-agent` (agent/coworker only) and `settings` (agent only, via
  // its Connected Accounts row) both push this — neither screen exists yet,
  // so it renders a `PlaceholderScreen` until one does, matching
  // `workConnectedAccounts`'s equivalent under the Work branch.
  static const profileConnectedAccounts = '/profile/connected-accounts';

  // `profile-agent`'s "Messages" row (§3.16) — no `messages` screen exists
  // anywhere in this app yet, so this renders a `PlaceholderScreen` too.
  static const profileMessages = '/profile/messages';

  // ---- Top-level routes (parentNavigatorKey: rootNavigatorKey) -----------
  // Modal/fullscreen-dialog pages — paint above the shell, tab bar never in
  // their tree.
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const createListing = '/create-listing';
  static const permissionsPrimer = '/permissions-primer';

  // No-chrome full-screen pages — also on the root navigator.
  static const photoGallery = '/photo-gallery';
  static const mapView = '/map-view';
}
