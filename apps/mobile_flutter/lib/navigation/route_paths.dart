/// Every route path in the app, in one place, so `app_router.dart` and any
/// widget that needs to navigate (`context.go`/`context.push`) share the
/// exact same strings — no route typo'd differently in two files.
///
/// Grouped by shell branch per the build spec's route tree; top-level
/// (root-navigator) routes listed last.
///
/// **Two shells, two branch sets.** `app_router.dart` declares a *buyer*
/// shell (`/home`, `/search`, `/agents`, `/profile` — 4 tabs, branch indices
/// 0–3) and an *agent* shell (everything under `/work` — 5 tabs, its own
/// branch indices 0–4). Which one a session is in is decided by role plus
/// `navigation/workspace_mode.dart`'s Browse/Work switch, never by a path
/// appearing in both trees: every path below belongs to exactly one shell.
abstract final class RoutePaths {
  // ---- Buyer shell, branch 0: Home ------------------------------------
  static const home = '/home';
  static const homeListingDetail = '/home/listing/:id';
  static const homeAgentProfile = '/home/agent/:id';
  static const homeNotifications = '/home/notifications';

  // ---- Buyer shell, branch 1: Search --------------------------------------
  static const search = '/search';
  static const searchAgentProfile = '/search/agent/:id';
  static const searchListingDetail = '/search/listing/:id';

  // ==== AGENT SHELL =========================================================
  // A second `StatefulShellRoute` with its own five branches, entered by an
  // agent/coworker session whose workspace mode is `WorkspaceMode.work`. The
  // buyer shell above is not mounted at the same time and vice versa — see
  // `app_router.dart`'s two-shell note and `workspace_mode.dart`.
  //
  // Every route below is nested under the branch root that owns it, which is
  // what makes a deep link (or a hardware Back) resolve to a stack with a
  // real screen underneath it — `/work/my-listings/edit-listing/:id` builds
  // `[my-listings, edit-listing]`, not a lone page over nothing. The old
  // flat layout (`/work/edit-listing/:id`, a direct child of a `/work`
  // placeholder page) is what M7 — a Back press stranding the user on a
  // permanently blank screen — came out of; the nesting here is the
  // structural fix, and it retired the self-correcting `_WorkPlaceholder`
  // widget that used to paper over it.

  // `/work` itself is redirect-only (see app_router.dart's `_redirect`):
  // coworker -> workMyListings, agent -> workDashboard. It is deliberately
  // NOT a declared route in either shell — every arrival is redirected
  // before matching, which is why the back-arrow fallbacks scattered across
  // the Work screens (`context.go(RoutePaths.work)`) always land on the
  // right per-role screen rather than needing to know which one that is.
  static const work = '/work';

  // ---- Agent shell, branch 0: Dashboard ------------------------------------
  static const workDashboard = '/work/dashboard';

  // `notifications` (§22) is reached from the bell in any Work header, and
  // the Dashboard is the branch that owns that header — nesting it here (as
  // opposed to the old top-level `/work/notifications`) is what gives a bell
  // tap something to go back to.
  static const workNotifications = '/work/dashboard/notifications';

  // ---- Agent shell, branch 1: My Ads ---------------------------------------
  static const workMyListings = '/work/my-listings';

  // `my-listings`' row tap (outside thumbnail/edit icon) pushes
  // `listing-detail` (§25) — every branch that can reach a listing carries
  // its own copy of that route (see [agentsListingDetail]'s note on why).
  static const workListingDetail = '/work/my-listings/listing/:id';

  // §27/§29 — both reached from a `my-listings` row, and both nested under
  // it for the back-stack reason in this section's header comment.
  static const workEditListing = '/work/my-listings/edit-listing/:id';
  static const workPublishStatus = '/work/my-listings/publish-status/:id';

  // ---- Agent shell, branch 2: Leads ----------------------------------------
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

  // ---- Agent shell, branch 3: Team -----------------------------------------
  static const workCoworkers = '/work/coworkers';

  // `add-coworker` (§37) is PUSHED, same reasoning as [workCreateLead]
  // above — nested as a sibling of `:id` under `coworkers`. Declared
  // before `:id` in `app_router.dart`'s route tree for the same reason
  // `agentsListingDetail` is declared before `agents/:id` there: a static
  // segment must be matched before a same-position dynamic one.
  static const workAddCoworker = '/work/coworkers/create';
  static const workCoworkerDetail = '/work/coworkers/:id';

  // ---- Agent shell, branch 4: Profile --------------------------------------
  // The agent's own `profile-agent` screen (§3.16), rendered by the same
  // `ProfileAgentScreen` the buyer shell's `/profile` shows an agent in
  // Browse mode — one widget, handed a different `branchPrefix` per shell so
  // its rows push into whichever tree it is currently in. This is also where
  // the Browse/Work switch lives.
  static const workProfile = '/work/profile';
  static const workProfileEdit = '/work/profile/edit';
  static const workSettings = '/work/profile/settings';
  static const workConnectedAccounts = '/work/profile/connected-accounts';

  // `messages` (§23) is reached from `profile-agent`'s row, so it belongs to
  // this branch. `notifications` (§22), reached from the header bell, sits
  // under the Dashboard branch instead — see [workNotifications].
  static const workMessages = '/work/profile/messages';

  // ---- Buyer shell, branch 2: Agents ---------------------------------------
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

  // ---- Buyer shell, branch 3: Profile (one route; content switches on
  // role) --------------------------------------------------------------
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

  // `listing-detail`'s 3D Tour section (§7) pushes here — its own
  // root-navigator route rather than a mode flag on `photoGallery`,
  // because it renders a live [WebViewWidget], not a photo/video item
  // `gallery_item.dart#resolveGalleryItems` could ever produce. See
  // `tour3d_view_screen.dart`.
  static const tour3dView = '/tour-3d-view';
}
