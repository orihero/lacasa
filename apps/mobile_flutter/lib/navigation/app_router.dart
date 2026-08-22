/// The single [GoRouter] for the whole app: **two**
/// `StatefulShellRoute.indexedStack`s — a buyer shell and an agent shell —
/// plus a handful of top-level routes declared with `parentNavigatorKey:
/// rootNavigatorKey` so they paint on the *root* [Navigator], above whichever
/// shell is mounted, including its bottom tab bar. That placement in the
/// route tree, not a per-route "hide tab bar" flag, is the whole
/// tab-bar-hiding mechanism (build spec, "Tab bar hiding mechanism").
///
/// Bottom sheets and the native delete-confirm alert are deliberately
/// *not* routes here at all — `showModalBottomSheet`/`showDialog` calls
/// made from within a branch screen, per the build spec. Nothing in this
/// file wires them; there is nothing to wire.
///
/// ## Two shells, not one shell with a conditional tab
///
/// The **buyer shell** owns `/home`, `/search`, `/agents`, `/profile` — four
/// tabs. The **agent shell** owns everything under `/work` — five tabs
/// (`dashboard`, `my-listings`, `leads`, `coworkers`, `profile`), i.e. the
/// whole CRM (SCREENS.md §21–§38) promoted out of the single crowded "Work"
/// tab it used to hide behind. The two are never mounted at the same time:
/// an agent is not "the buyer app plus a tab", their screen set, their tab
/// bar and their entire back-stack space are different.
///
/// This replaces the previous design, in which one 5-branch shell declared
/// `/work` unconditionally and role-gating happened by (1) omitting the Work
/// item from the drawn tab row and (2) a redirect guard. That design existed
/// because [StatefulShellRoute]'s branch list is fixed at construction and
/// mutating it would have meant rebuilding this [GoRouter], destroying every
/// branch's [Navigator] and the "own back stack, own scroll position"
/// guarantee. Declaring two sibling shell *routes* sidesteps that constraint
/// entirely: each keeps its own fixed branch list, and go_router mounts
/// whichever one the current location belongs to. The cost is that crossing
/// between them discards the other side's remembered stacks — which is the
/// wanted behaviour here (see [_redirect]'s M5 note) rather than a
/// regression.
///
/// ## Who ends up in which shell
///
/// [_redirect] decides, from two inputs:
///
/// - **role** — only `agent`/`coworker` may be in the agent shell at all;
///   any other session (buyer, signed-out, a forward-compat role this build
///   doesn't recognize) is bounced out of `/work*` to `/home`, exactly as
///   before.
/// - **workspace mode** — an agent's own Browse/Work switch
///   (`workspace_mode.dart`), because realtors still need the buyer surfaces
///   to search comparables and read competitors' listings. In
///   [WorkspaceMode.work] a buyer-shell location redirects to `/work`; in
///   [WorkspaceMode.browse] a `/work*` location redirects to `/home`. The
///   switch itself only sets the mode — [_AuthRouterRefresh] listens to that
///   provider, so flipping it re-runs this redirect and the shell swap
///   follows on its own, with no restart.
///
/// `/work` itself is redirect-only and is deliberately **not** a declared
/// route in either shell: every arrival is redirected before matching
/// (coworker → `my-listings`, agent → `dashboard`). That is what lets the
/// back-arrow fallbacks scattered across the Work screens
/// (`context.go(RoutePaths.work)`) stay correct without knowing the role —
/// and it is why the self-correcting `_WorkPlaceholder` widget that used to
/// live here is gone: there is no blank parent page left to strand anyone
/// on (M7). Every agent-shell route now nests under a branch root that
/// renders a real screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../api/api.dart';
import '../features/agents/agents.dart';
import '../features/auth/auth.dart';
import '../features/coworkers/coworkers.dart';
import '../features/edit_profile/edit_profile.dart';
import '../features/home/home.dart';
import '../features/leads/leads.dart';
import '../features/listing_detail/listing_detail.dart';
import '../features/listing_editor/listing_editor.dart';
import '../features/map_view/map_view.dart';
import '../features/my_listings/my_listings.dart';
import '../features/onboarding/onboarding.dart';
import '../features/permissions/permissions.dart';
import '../features/photo_gallery/photo_gallery.dart';
import '../features/profile/profile.dart';
import '../features/saved_listings/saved_listings.dart';
import '../features/search/search.dart';
import '../features/settings/settings.dart';
import '../features/work_dashboard/work_dashboard.dart';
import '../features/work_misc/work_misc.dart';
import '../l10n/generated/app_localizations.dart';
import 'auth_session.dart';
import 'placeholder_screen.dart';
import 'profile_role_screen.dart';
import 'route_paths.dart';
import 'shell/glass_tab_bar.dart';
import 'shell/tab_shell_scaffold.dart';
import 'workspace_mode.dart';

/// The root [Navigator]'s key. Top-level routes below are pushed on this
/// navigator explicitly via `parentNavigatorKey: rootNavigatorKey`, which
/// is what lifts them above the mounted shell's own [Scaffold]/tab bar.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds a placeholder [GoRoute] body. Only the two untyped-`extra:` guards
/// at the bottom of the route tree still reach for it — every branch route
/// points at a real screen.
Widget _placeholder(String name) => PlaceholderScreen(name: name);

/// The buyer shell's four branch roots. A location under one of these is
/// what an agent in [WorkspaceMode.work] gets redirected *out of*; anything
/// else — a root-navigator modal (`/login`, `/create-listing`), a no-chrome
/// full-screen page (`/photo-gallery`, `/map-view`, `/tour-3d-view`) — is
/// left alone, because those belong to no shell at all and are opened
/// deliberately from wherever the user already is. An agent in work mode
/// must still be able to open the photo gallery from a listing.
const List<String> _buyerShellRoots = [
  RoutePaths.home,
  RoutePaths.search,
  RoutePaths.agents,
  RoutePaths.profile,
];

bool _isBuyerShellLocation(String loc) {
  for (final root in _buyerShellRoots) {
    if (loc == root || loc.startsWith('$root/')) return true;
  }
  return false;
}

/// The agent shell's five branch roots, in branch order. Used to answer
/// "which branch does this location belong to?" for the per-branch M5 reset
/// — see [_AuthRouterRefresh.consumeStaleBranch].
const List<String> _agentBranchRoots = [
  RoutePaths.workDashboard,
  RoutePaths.workMyListings,
  RoutePaths.workLeads,
  RoutePaths.workCoworkers,
  RoutePaths.workProfile,
];

String? _agentBranchRootFor(String loc) {
  for (final root in _agentBranchRoots) {
    if (loc == root || loc.startsWith('$root/')) return root;
  }
  return null;
}

/// The onboarding gate (SCREENS.md §3.1: "App first launch") + the role/mode
/// rules that decide which shell a session lives in (see this library's doc
/// comment) + the M5 stale-session guard (see [_AuthRouterRefresh]'s
/// [consumeWorkBranchReset] doc comment).
String? _redirect(
  GoRouterState state,
  AuthSessionState authState, {
  required WorkspaceMode mode,
  required bool hasSeenOnboarding,
  required _AuthRouterRefresh refresh,
}) {
  final loc = state.matchedLocation;

  // Onboarding is checked first and applies to every location: on a first
  // launch there is no destination in the app the user should reach ahead
  // of it, deep link or otherwise. `hasSeenOnboarding` is known
  // synchronously here by construction — see `main.dart`.
  if (!hasSeenOnboarding) {
    return loc == RoutePaths.onboarding ? null : RoutePaths.onboarding;
  }
  // And once it's done, `/onboarding` is not somewhere to go back to.
  if (loc == RoutePaths.onboarding) return RoutePaths.home;

  final onAgentShell =
      loc == RoutePaths.work || loc.startsWith('${RoutePaths.work}/');

  if (!authState.canAccessWork) {
    // Signed-out or buyer session landing on any /work* location (e.g. a
    // stale deep link) is bounced straight to Home — never shown an agent
    // screen it isn't allowed to see, even transiently. Everywhere else is
    // this session's own shell, so there is nothing to do.
    return onAgentShell ? RoutePaths.home : null;
  }

  // Agent/coworker from here down; the mode switch picks the shell.
  if (mode == WorkspaceMode.browse) {
    return onAgentShell ? RoutePaths.home : null;
  }

  if (!onAgentShell) {
    // Work mode, but the location belongs to the buyer shell. Two ordinary
    // cases land here: a cold start (`initialLocation` is `/home`, and the
    // role only arrives once `AuthSessionNotifier`'s startup restore
    // resolves — this redirect re-runs then, via `_AuthRouterRefresh`), and
    // a fresh sign-in from `/login`. Anything belonging to no shell is left
    // alone; see [_buyerShellRoots].
    return _isBuyerShellLocation(loc) ? RoutePaths.work : null;
  }

  if (loc == RoutePaths.work) {
    // `/work` itself is redirect-only: coworkers skip straight to
    // my-listings (skipping the dashboard, matching the web's
    // Statistics-hidden-for-coworkers rule), agents land on the dashboard.
    return authState.isCoworker
        ? RoutePaths.workMyListings
        : RoutePaths.workDashboard;
  }

  // M5: a sign-in/sign-out that changed *who* is signed in must not let
  // whatever the previous session had pushed into a branch (a coworker's
  // detail page, an edit-listing form, …) carry over into the new one —
  // even when both sessions share a role that would otherwise sail through
  // the checks above unchanged (the exact case that slipped past before:
  // two agent accounts).
  //
  // The two-shell split covers half of this structurally: an identity
  // change that costs the session its agent role (a sign-out, or a swap to
  // a buyer) unmounts the entire agent shell, so no remembered stack
  // survives to leak. What is left is an agent→agent swap, where the shell
  // stays mounted with all five branches' stacks intact — and *that* is why
  // the reset is tracked per branch root rather than as one flag. One flag
  // could only ever fix the branch that happened to be on screen when the
  // swap landed; the other four would keep their stale stacks until the new
  // agent tapped into them. Each root is consumed the first time its own
  // branch is (re-)entered, and bouncing to the root collapses that
  // branch's Navigator stack back to a single fresh entry.
  final branchRoot = _agentBranchRootFor(loc);
  if (branchRoot != null && refresh.consumeStaleBranch(branchRoot)) {
    // Already sitting on the root: nothing was pushed on top of it, so
    // there is nothing to collapse — and returning the current location
    // from a redirect is what go_router reports as a redirect loop.
    return loc == branchRoot ? null : branchRoot;
  }

  return null;
}

/// Bridges [authSessionProvider] and [workspaceModeProvider] to [GoRouter]'s
/// `refreshListenable`, so [_redirect] is re-evaluated the instant the
/// signed-in *identity* or the Browse/Work choice changes — with no restart
/// and, importantly, without rebuilding [GoRouter] itself (which would
/// destroy the mounted shell's [Navigator]s and their back stacks).
///
/// Listening to the mode here is what lets the switch be a one-liner at its
/// call site: `setMode(...)` alone moves the session into the other shell,
/// with no navigation call of its own racing this redirect to the same
/// destination.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    _subscription = ref.listen<AuthSessionState>(authSessionProvider, (
      previous,
      next,
    ) {
      // M5: comparing `role` alone (the original check) misses an agent
      // account being swapped for a *different* agent account — same
      // role, different person, e.g. agent@lacasa.dev signing out and
      // sardor@lacasa.dev signing in. `user?.id` is what actually names
      // "who", so it has to be part of this comparison; `role` stays in
      // the OR because a role change with the same id (rare, but
      // theoretically a server-side promotion mid-session) is exactly the
      // same category of "the agent shell's current content might no
      // longer be valid" as an id change.
      final identityChanged =
          previous?.user?.id != next.user?.id || previous?.role != next.role;
      if (identityChanged) {
        // Only flag a reset when the *outgoing* session could actually
        // have populated the agent shell (was signed in as agent/coworker)
        // — only that session could have left anything behind worth
        // invalidating. Gating on this matters: without it, a brand-new
        // session's very first navigation — e.g. a deep link straight into
        // `/work/leads/create`, reached the instant after a fresh sign-in
        // with nothing stale anywhere — would also set the flag and
        // `_redirect` would incorrectly bounce that legitimate, live
        // navigation to the bare-`/work` default instead of honouring it.
        if (previous?.canAccessWork ?? false) {
          // Every branch at once: the outgoing session could have left a
          // pushed page in any of them. See [_staleAgentBranches].
          _staleAgentBranches.addAll(_agentBranchRoots);
        }
        notifyListeners();
      }
    });

    // The Browse/Work switch. Re-running `_redirect` on a mode change is
    // the entire mechanism by which the switch moves the session between
    // shells — see this class's doc comment.
    _workspaceModeSubscription = ref.listen<WorkspaceMode>(
      workspaceModeProvider,
      (previous, next) {
        if (previous != next) notifyListeners();
      },
    );

    // The onboarding flag flips exactly once per install, when the carousel
    // is finished or skipped. Re-running [_redirect] on that flip is what
    // lets `OnboardingScreen`'s `context.go(home)` actually land instead of
    // being bounced straight back by a gate still reading "unseen".
    _onboardingSubscription = ref.listen<bool>(onboardingSeenProvider, (
      previous,
      next,
    ) {
      if (previous != next) notifyListeners();
    });
  }

  late final ProviderSubscription<AuthSessionState> _subscription;
  late final ProviderSubscription<WorkspaceMode> _workspaceModeSubscription;
  late final ProviderSubscription<bool> _onboardingSubscription;

  /// Agent-shell branch roots whose remembered stack still belongs to a
  /// previous identity. Filled with all five the instant `identityChanged`
  /// above fires for a session that could reach them, and drained one root
  /// at a time as each branch is next entered.
  ///
  /// Why a set of roots and not one flag: firing [notifyListeners] makes
  /// go_router re-evaluate `_redirect` against whatever location is
  /// *current right now* (see `GoRouter.refresh`), which resets exactly one
  /// branch — the one on screen when the swap landed. The other four keep
  /// their stacks in memory until the new agent taps into them, and that
  /// re-entry is a go_router `restore`, not a fresh `redirect`-bearing
  /// navigation, so it is only this bookkeeping that can catch it. One
  /// `bool` consumed on the first `/work*` evaluation — the previous
  /// single-branch design — would have been spent on the on-screen branch
  /// and left the rest stale.
  ///
  /// Draining rather than "compare identity on every pass" is what keeps a
  /// legitimate deep navigation by the *new* session from being bounced: a
  /// root is only ever reset once per identity change, on first entry.
  final Set<String> _staleAgentBranches = <String>{};

  /// Called by [_redirect] for the branch a `/work*` location belongs to.
  /// Returns whether that branch is still carrying a previous identity's
  /// stack, and marks it handled either way — a single read-and-clear, so
  /// the *next* navigation into the same branch is left alone.
  bool consumeStaleBranch(String branchRoot) =>
      _staleAgentBranches.remove(branchRoot);

  @override
  void dispose() {
    _subscription.close();
    _workspaceModeSubscription.close();
    _onboardingSubscription.close();
    super.dispose();
  }
}

/// The app's one [GoRouter] instance. Backed by a plain (non-autoDispose)
/// [Provider], so it is created once, lazily, on first read, and lives for
/// the app's lifetime — never rebuilt on auth or mode changes (see
/// [_AuthRouterRefresh] for how those are handled instead).
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.home,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(
      state,
      ref.read(authSessionProvider),
      mode: ref.read(workspaceModeProvider),
      hasSeenOnboarding: ref.read(onboardingSeenProvider),
      refresh: refresh,
    ),
    routes: [
      // ======== BUYER SHELL — 4 branches ==================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => TabShellScaffold(
          navigationShell: navigationShell,
          items: buyerTabItems(AppLocalizations.of(context)),
        ),
        branches: [
          // Branch 0: Home ---------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeFeedScreen(),
                routes: [
                  // Declared once per branch rather than as one top-level
                  // route: SCREENS.md §1 lists `listing-detail` under
                  // "Pushed (full-screen, back-stack)", so it must keep the
                  // tab bar and stay in the back stack of the tab it was
                  // opened from. `branchPrefix` is what lets the screen
                  // push its own siblings (agent-profile) into that same
                  // branch — see `listing_detail_screen.dart`.
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) => ListingDetailScreen(
                      adId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.home,
                    ),
                  ),
                  GoRoute(
                    path: 'agent/:id',
                    builder: (context, state) => AgentProfileScreen(
                      agentId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.home,
                    ),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: Search ----------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.search,
                builder: (context, state) => const SearchScreen(),
                routes: [
                  GoRoute(
                    path: 'agent/:id',
                    builder: (context, state) => AgentProfileScreen(
                      agentId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.search,
                    ),
                  ),
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) => ListingDetailScreen(
                      adId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.search,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Agents ----------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.agents,
                builder: (context, state) => const AgentsDirectoryScreen(),
                routes: [
                  // Declared before `:id` so the more specific three-segment
                  // pattern is matched first — see RoutePaths'
                  // `agentsListingDetail` note on why this branch carries its
                  // own listing-detail route at all.
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) => ListingDetailScreen(
                      adId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.agents,
                    ),
                  ),
                  // The target that listing's agent block pushes back to —
                  // see RoutePaths' `agentsAgentProfile` note.
                  GoRoute(
                    path: 'agent/:id',
                    builder: (context, state) => AgentProfileScreen(
                      agentId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.agents,
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => AgentProfileScreen(
                      agentId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.agents,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Profile — one route; ProfileRoleScreen switches its
          // own content on role via ref.watch (see profile_role_screen.dart).
          // An agent in browse mode gets `profile-agent` here, carrying the
          // switch back into the agent shell.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileRoleScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => const SavedListingsScreen(),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) =>
                        const SettingsScreen(branchPrefix: RoutePaths.profile),
                  ),
                  GoRoute(
                    path: 'connected-accounts',
                    builder: (context, state) =>
                        const ConnectedAccountsScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) => const MessagesScreen(),
                  ),
                  // Same convention as `/home`, `/search`, `/agents`' own
                  // copies — see `route_paths.dart`'s `agentsListingDetail`
                  // note — this branch needs its own because
                  // `saved-listings`'s grid pushes into it.
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) => ListingDetailScreen(
                      adId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.profile,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ======== AGENT SHELL — 5 branches ==================================
      // Entered only by an agent/coworker session in WorkspaceMode.work;
      // `_redirect` is the only way in or out. Every route nests under the
      // branch root that owns it, so a deep link — or a hardware Back —
      // resolves to a stack with a real screen underneath the top page.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => TabShellScaffold(
          navigationShell: navigationShell,
          items: agentTabItems(AppLocalizations.of(context)),
        ),
        branches: [
          // Branch 0: Dashboard --------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workDashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  // §22 — reached from the bell in this branch's own header,
                  // which is what it should go back to.
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: My Ads -----------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workMyListings,
                builder: (context, state) => const MyListingsScreen(),
                routes: [
                  // `my-listings`' row *is* the only in-app entry point to
                  // each of these three, so it is what a Back from them
                  // should reveal — with the filters and paged scroll
                  // position of that already-built screen still in place.
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) => ListingDetailScreen(
                      adId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.workMyListings,
                    ),
                  ),
                  GoRoute(
                    path: 'edit-listing/:id',
                    builder: (context, state) =>
                        EditListingScreen(adId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'publish-status/:id',
                    builder: (context, state) =>
                        PublishStatusScreen(adId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Leads ------------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workLeads,
                builder: (context, state) => const LeadsListScreen(),
                routes: [
                  GoRoute(
                    path: 'kanban',
                    builder: (context, state) => const LeadsKanbanScreen(),
                  ),
                  // §33, pushed. `lead-detail`/`kanban-move-sheet`
                  // (§32/§34) are bottom sheets — deliberately no route for
                  // either, see `route_paths.dart`'s `workCreateLead` note.
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateLeadScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Coworkers --------------------------------------------
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workCoworkers,
                builder: (context, state) => const CoworkersListScreen(),
                routes: [
                  // Declared before `:id` so the static `create` segment is
                  // matched first — same reasoning as `agentsListingDetail`'s
                  // note in `route_paths.dart`.
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const AddCoworkerScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => CoworkerDetailScreen(
                      coworkerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 4: Profile ----------------------------------------------
          // The same `ProfileAgentScreen` the buyer shell shows an agent on
          // its own Profile tab, handed this shell's prefix so its rows push
          // into this tree instead of that one — and carrying the switch
          // *out* to browse mode.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workProfile,
                builder: (context, state) => const ProfileAgentScreen(
                  branchPrefix: RoutePaths.workProfile,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(
                      branchPrefix: RoutePaths.workProfile,
                    ),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(
                      branchPrefix: RoutePaths.workProfile,
                    ),
                  ),
                  GoRoute(
                    path: 'connected-accounts',
                    builder: (context, state) =>
                        const ConnectedAccountsScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) => const MessagesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // `/work` — a builder-less, redirect-only route. It renders nothing
      // and belongs to no shell; it exists so the path *matches*, which the
      // top-level `_redirect` alone does not guarantee: a location matching
      // no route at all resolves to go_router's error match, and
      // `GoRouterState.matchedLocation` for that is not the `/work` the
      // `loc == RoutePaths.work` branch above is looking for — so a
      // refresh-driven redirect that lands here (an agent signing in, say)
      // would stop on an unmatched `/work` instead of continuing to the
      // role-based screen. Declaring it makes the hop resolve every time,
      // and this route-level redirect is the one that finishes the job.
      GoRoute(
        path: RoutePaths.work,
        redirect: (context, state) => ref.read(authSessionProvider).isCoworker
            ? RoutePaths.workMyListings
            : RoutePaths.workDashboard,
      ),

      // ---- Top-level routes: pushed on the root Navigator, above the
      // mounted shell's Scaffold (and therefore above its tab bar). ------

      // Modal / fullscreen-dialog pages.
      GoRoute(
        path: RoutePaths.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.register,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: RegisterScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.createListing,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: CreateListingScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.permissionsPrimer,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: PermissionsPrimerScreen(),
        ),
      ),

      // No-chrome full-screen pages — root navigator, but a plain push
      // transition rather than the fullscreenDialog (slide-up) treatment.
      // `photoGallery` carries no path params, so its ad + start index
      // arrive via `extra:` (see `photo_gallery_args.dart`).
      // `listing-detail` is now the one screen that pushes here, and it
      // always supplies a well-formed payload — but `extra:` is an untyped
      // channel, and a deep link or a restored route stack reaches this
      // route with nothing at all. A bare `state.extra as PhotoGalleryArgs`
      // would throw for those, so the type check stays: it guards the cases
      // no caller controls, not the one that does.
      GoRoute(
        path: RoutePaths.photoGallery,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra;
          if (args is! PhotoGalleryArgs) return _placeholder('Photo Gallery');
          return PhotoGalleryScreen(args: args);
        },
      ),
      // `map-view` takes the current result set through `extra:` as a
      // fallback only — it prefers live search state (see
      // `map_view_screen.dart`). So unlike `photoGallery` above, a missing
      // or wrong-typed `extra` is not a degraded case worth a placeholder:
      // the screen simply reads the provider, which is what it does on
      // every normal entry anyway.
      //
      // **`MapViewArgs` is the branch that makes "where is *this* flat?"
      // work.** A bare `List<Ad>` cannot distinguish the two callers —
      // `listing-search`'s map toggle passing its result set, and
      // `listing-detail`'s Location section passing the one ad the user
      // asked about — so reading only `List<Ad>` forced both into search
      // mode. The screen then watched `searchResultsProvider`, and that
      // watch *starts* the fetch: a buyer tapping one listing's map got
      // their ad for a beat and then 20 unrelated listings, their own
      // deselected, under a Filters button for a search they never ran.
      // The typed payload carries `focusAd` and `branchPrefix` through, so
      // this builder is a cast rather than a re-decision.
      GoRoute(
        path: RoutePaths.mapView,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is MapViewArgs) {
            return MapViewScreen(
              fallbackAds: extra.ads,
              focusAd: extra.focusAd,
              branchPrefix: extra.branchPrefix,
            );
          }
          // Still honoured below the typed branch: a deep link or a
          // restored route stack reaches this route with a bare list or
          // with nothing at all, and neither is an error.
          return MapViewScreen(
            fallbackAds: extra is List<Ad> ? extra : const [],
          );
        },
      ),
      // `ListingTourSection` is the one screen that pushes here, same
      // "wrong/missing typed `extra`" guard as `photoGallery` above and for
      // the same reason — a deep link or restored route stack can reach
      // this path with nothing at all.
      GoRoute(
        path: RoutePaths.tour3dView,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final args = state.extra;
          if (args is! Tour3dViewArgs) return _placeholder('3D Tour');
          return Tour3dViewScreen(args: args);
        },
      ),
    ],
  );
});
