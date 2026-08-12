/// The single [GoRouter] for the whole app: one
/// `StatefulShellRoute.indexedStack` for the 5-branch tab experience, plus
/// a handful of top-level routes declared with `parentNavigatorKey:
/// rootNavigatorKey` so they paint on the *root* [Navigator], above the
/// shell's [Scaffold] — including its bottom tab bar. That placement in the
/// route tree, not a per-route "hide tab bar" flag, is the whole
/// tab-bar-hiding mechanism (build spec, "Tab bar hiding mechanism").
///
/// Bottom sheets and the native delete-confirm alert are deliberately
/// *not* routes here at all — `showModalBottomSheet`/`showDialog` calls
/// made from within a branch screen, per the build spec. Nothing in this
/// file wires them; there is nothing to wire.
///
/// **Why the Work branch is declared unconditionally** (build spec, "Why
/// the Work branch always exists"): [StatefulShellRoute]'s branch list is
/// fixed at construction time. Conditionally adding/removing branches would
/// mean rebuilding this whole [GoRouter], destroying every other branch's
/// [Navigator] and the "own back stack, own scroll position" guarantee.
/// So branch 2 (`/work`) always exists; role-gating happens two other ways
/// instead:
/// 1. Visually — [GlassTabBar] just omits the Work item from the row it
///    draws when role isn't agent/coworker (see `shell/glass_tab_bar.dart`).
/// 2. As a guard — [_redirect] below bounces `/work*` to `/home` when the
///    session isn't agent/coworker, and [_AuthRouterRefresh] re-runs that
///    redirect the instant the signed-in *identity* changes — not just
///    role, so one agent account being swapped for another counts too —
///    without an app restart.
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
import '../features/saved_listings/saved_listings.dart';
import '../features/search/search.dart';
import '../features/settings/settings.dart';
import '../features/work_dashboard/work_dashboard.dart';
import '../features/work_misc/work_misc.dart';
import 'auth_session.dart';
import 'placeholder_screen.dart';
import 'profile_role_screen.dart';
import 'route_paths.dart';
import 'shell/tab_shell_scaffold.dart';

/// The root [Navigator]'s key. Top-level routes below are pushed on this
/// navigator explicitly via `parentNavigatorKey: rootNavigatorKey`, which
/// is what lifts them above the shell's own [Scaffold]/tab bar.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds a placeholder [GoRoute] body. Later agents replace individual
/// routes' `builder:` with the real screen — this helper (and the routes
/// still pointing at it) should shrink over time.
Widget _placeholder(String name) => PlaceholderScreen(name: name);

/// The `/work` route's own builder (M7). `edit-listing/:id` and
/// `publish-status/:id` are declared as direct children of `/work` (see the
/// route tree below), so this placeholder is *always* built as their
/// Navigator stack's parent page whenever either is open — go_router's
/// `Navigator` gets the *entire* matched page stack (`[_WorkPlaceholder,
/// PublishStatusPage]`, say), not just the top one, so this widget's
/// `initState` genuinely fires on every such nested navigation, not only
/// through the pop-bypass path below. It just isn't the *visible*
/// (`ModalRoute.isCurrent`) page in that case — see [build]'s guard, which
/// is why this can't unconditionally self-correct in `initState`.
///
/// The scenario this widget exists for: a hardware/OS Back gesture from
/// either child pops straight to this placeholder, becoming the *current*
/// route — go_router only runs `redirect` on its own navigation events
/// (`go`/`push`/`restore`/…), **not** when a nested branch [Navigator] pops
/// imperatively, which is exactly what that gesture does
/// (`GoRouterDelegate.popRoute` calls `NavigatorState.maybePop()` directly,
/// bypassing `GoRouter.pop()`'s own `restore()` call that would otherwise
/// re-run `redirect`). Without this widget, that pop would strand the user
/// on a permanently blank screen — with nothing else left on that branch's
/// stack to pop to, a *second* Back would exit the app outright.
///
/// The fix: make the placeholder self-correcting, but only when it is
/// actually the one on screen (`ModalRoute.isCurrent` — see [build]). It
/// then `go`es to `/work` itself, landing squarely back in [_redirect]'s
/// existing `loc == RoutePaths.work` branch, which picks the correct
/// role-based Work screen exactly as it would for a fresh `/work`
/// navigation. Deferred to a post-frame callback because navigating away
/// from a route is unsafe to do mid-build/`initState`. See the call site
/// below for why [GoRouter.refresh] — the first thing tried here — does
/// not actually work for this.
class _WorkPlaceholder extends StatefulWidget {
  const _WorkPlaceholder();

  @override
  State<_WorkPlaceholder> createState() => _WorkPlaceholderState();
}

class _WorkPlaceholderState extends State<_WorkPlaceholder> {
  /// Guards against re-firing `go()` on every subsequent rebuild while
  /// this placeholder stays current (e.g. a theme/locale change) — only
  /// the transition *into* being current should trigger the correction.
  bool _lastIsCurrent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `initState` alone is not enough: this widget is *always* built as
    // the Navigator-stack parent of an open `edit-listing/:id` or
    // `publish-status/:id` (see the class doc comment), so its first
    // build/`initState` typically happens while it is *not* the visible
    // route — self-correcting then would wrongly bounce a perfectly live
    // nested navigation back to `/work`'s role-based default. And because
    // `initState` runs exactly once per `State`, it can't be the hook for
    // the pop-bypass scenario either: popping the child reuses this same
    // `State` object rather than remounting it, so `initState` never runs
    // again at the moment this placeholder actually *becomes* current.
    // `didChangeDependencies`, in contrast, re-fires whenever
    // `ModalRoute.of(context)` — an `InheritedWidget` dependency — changes,
    // which includes exactly this route's `isCurrent` flipping to `true`
    // after the child above it is popped.
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    final becameCurrent = isCurrent && !_lastIsCurrent;
    _lastIsCurrent = isCurrent;
    if (!becameCurrent) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // `GoRouter.refresh()` was tried first and does *not* work here: it
      // re-notifies `routeInformationProvider` but re-parses whatever URI
      // that provider still holds — and a raw `NavigatorState.maybePop()`
      // (what a hardware Back does) only updates
      // `GoRouterDelegate.currentConfiguration` (the Navigator-facing
      // state), never `GoRouteInformationProvider`'s own `_value`, which
      // stays stuck on the pre-pop `/work/publish-status/ad-1001`. `refresh`
      // re-running `redirect` against that stale value never reaches the
      // `loc == RoutePaths.work` branch, so nothing changes and the app is
      // left showing this same blank placeholder — confirmed by instrumenting
      // both: `currentConfiguration.uri` reads `/work` immediately after the
      // pop while `_redirect`'s own `loc` on the `refresh()`-triggered pass
      // still read `/work/publish-status/ad-1001`.
      // `go(RoutePaths.work)` doesn't have that problem: it targets
      // `routeInformationProvider` directly and unconditionally overwrites
      // its `_value` to `/work` before deciding whether to notify — since
      // that stale value differs from `/work`, it always notifies, and
      // *that* re-parse's `loc` genuinely is `/work`, landing in
      // `_redirect`'s `loc == RoutePaths.work` branch as intended.
      GoRouter.of(context).go(RoutePaths.work);
    });
  }

  @override
  Widget build(BuildContext context) => _placeholder('Work');
}

/// The onboarding gate (SCREENS.md §3.1: "App first launch") + `/work*`
/// guard + `/work` initial-screen-by-role redirect (build spec, "Work's
/// initial screen by role" and "Why the Work branch always exists",
/// point 2) + the M5 stale-session guard (see [refresh]'s
/// `consumeWorkBranchReset` doc comment).
String? _redirect(
  GoRouterState state,
  AuthSessionState authState, {
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

  final onWorkBranch =
      loc == RoutePaths.work || loc.startsWith('${RoutePaths.work}/');
  if (!onWorkBranch) return null;

  // Consumed unconditionally, the instant any /work* location is
  // (re-)evaluated — whether that settles the pending reset below (the
  // `!canAccessWork` and bare-`/work` branches both already recompute the
  // right destination from the *current* `authState` on every call, so
  // consuming here is enough for them) or has to force it (the final
  // `pendingIdentityReset` check). See `consumeWorkBranchReset`'s doc
  // comment for why it must be read exactly once, right here, rather than
  // only in that final branch.
  final pendingIdentityReset = refresh.consumeWorkBranchReset();

  if (!authState.canAccessWork) {
    // Signed-out or buyer session landing on any /work* location (e.g. a
    // stale deep link) is bounced straight to Home — never shown a Work
    // screen it isn't allowed to see, even transiently.
    return RoutePaths.home;
  }

  if (loc == RoutePaths.work) {
    // `/work` itself is redirect-only: coworkers skip straight to
    // my-listings (skipping dashboard), agents land on dashboard.
    return authState.isCoworker
        ? RoutePaths.workMyListings
        : RoutePaths.workDashboard;
  }

  // M5: a sign-in/sign-out that changed *who* is signed in, since this
  // deep `/work/...` location was last validated, must not let whatever
  // the previous session had pushed here (a coworker's detail page, an
  // edit-listing form, ...) carry over into the new one — even when both
  // sessions share a role that would otherwise sail through the checks
  // above unchanged (the exact case that slipped past before: two agent
  // accounts). Bouncing to the bare `/work` re-enters the two branches
  // above on the *next* pass of go_router's redirect loop, landing the new
  // session on its own correct initial screen — and because that
  // recomputes the match list from `/work` outward instead of keeping
  // today's nested matches, it also collapses the branch Navigator's stack
  // back to that one fresh entry, discarding whatever the old session had
  // pushed on top of it.
  if (pendingIdentityReset) {
    return RoutePaths.work;
  }

  return null;
}

/// Bridges [authSessionProvider] to [GoRouter]'s `refreshListenable`, so
/// [_redirect] is re-evaluated the instant the signed-in *identity*
/// changes — with no restart and, importantly, without rebuilding
/// [GoRouter] itself (which would destroy every branch's [Navigator] and
/// its back stack). The tab bar's own visible-item-set reactivity goes
/// through [WidgetRef.watch] directly in `GlassTabBar`, not through this
/// class — this class exists purely to drive [_redirect] re-evaluation,
/// plus (see [_workBranchNeedsReset]) to flag the one thing re-evaluating
/// `_redirect` on its own can't fix: a *deep* `/work/...` location that was
/// pushed by a now-gone session.
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
      // same category of "the Work branch's current content might no
      // longer be valid" as an id change.
      final identityChanged =
          previous?.user?.id != next.user?.id || previous?.role != next.role;
      if (identityChanged) {
        // Only flag a reset when the *outgoing* session could actually
        // have populated the Work branch (was signed in as agent/coworker)
        // — only that session could have left anything behind worth
        // invalidating. Gating on this matters: without it, a brand-new
        // session's very first navigation — e.g. a deep link straight into
        // `/work/leads/create`, reached the instant after a fresh sign-in
        // with nothing stale anywhere — would also set the flag and
        // `_redirect` would incorrectly bounce that legitimate, live
        // navigation to the bare-`/work` default instead of honouring it.
        if (previous?.canAccessWork ?? false) {
          // See this field's own doc comment for why setting it here isn't
          // enough by itself — `_redirect` has to consume it too.
          _workBranchNeedsReset = true;
        }
        notifyListeners();
      }
    });

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
  late final ProviderSubscription<bool> _onboardingSubscription;

  /// Set the instant [identityChanged] above fires, cleared the next time
  /// [_redirect] consults it via [consumeWorkBranchReset] — a one-shot
  /// flag, not a running "is the session stale" bit.
  ///
  /// Why this can't just be "notify, and let `_redirect` re-run": firing
  /// [notifyListeners] makes go_router re-evaluate `_redirect` against
  /// whatever location is *current right now* (see `GoRouter.refresh`) —
  /// which is exactly what fixes an agent who is signed out/in while
  /// sitting on `/work/leads`. But M5's repro leaves the Work branch on
  /// `coworkers-list`/`coworker-detail` and then signs out **from
  /// somewhere else** (e.g. Profile's Settings) — at the moment identity
  /// changes, the *current* location isn't under `/work*` at all, so that
  /// immediate re-evaluation has nothing to bounce. The Work branch's own
  /// remembered stack sits untouched in memory until the user taps the
  /// Work tab again — and *that* re-entry (a go_router `restore`, not a
  /// fresh `redirect`-bearing navigation) is the moment this flag has to
  /// still be around to catch.
  bool _workBranchNeedsReset = false;

  /// Called by [_redirect] on every `/work*` evaluation. Returns whether an
  /// identity change is still pending a Work-branch bounce, and clears the
  /// flag either way — see [_workBranchNeedsReset]'s doc comment for why a
  /// single read-and-clear, done unconditionally rather than only when the
  /// bounce actually fires, is the correct contract: leaving it set after a
  /// `/work` bare/`!canAccessWork` pass already fully re-resolved things
  /// would make the *next*, unrelated deep Work navigation this session
  /// takes get incorrectly bounced too.
  bool consumeWorkBranchReset() {
    if (!_workBranchNeedsReset) return false;
    _workBranchNeedsReset = false;
    return true;
  }

  @override
  void dispose() {
    _subscription.close();
    _onboardingSubscription.close();
    super.dispose();
  }
}

/// The app's one [GoRouter] instance. Backed by a plain (non-autoDispose)
/// [Provider], so it is created once, lazily, on first read, and lives for
/// the app's lifetime — never rebuilt on auth changes (see
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
      hasSeenOnboarding: ref.read(onboardingSeenProvider),
      refresh: refresh,
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabShellScaffold(navigationShell: navigationShell),
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

          // Branch 2: Work — always declared; gated by `_redirect` above and
          // by GlassTabBar's item list, never by removing this branch.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.work,
                // Never actually renders under a normal GoRouter-driven
                // navigation: `_redirect` always sends `/work` itself on to
                // a concrete sub-route or bounces it to `/home` first. It
                // *can* still get built via a hardware-Back pop, though —
                // see `_WorkPlaceholder`'s doc comment (M7) for why that
                // needs its own self-correcting widget rather than the bare
                // `_placeholder('Work')` every other placeholder route uses.
                builder: (context, state) => const _WorkPlaceholder(),
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) => const DashboardScreen(),
                  ),
                  GoRoute(
                    path: 'my-listings',
                    builder: (context, state) => const MyListingsScreen(),
                  ),
                  GoRoute(
                    path: 'leads',
                    builder: (context, state) => const LeadsListScreen(),
                    routes: [
                      GoRoute(
                        path: 'kanban',
                        builder: (context, state) =>
                            const LeadsKanbanScreen(),
                      ),
                      // §33, pushed. `lead-detail`/`kanban-move-sheet`
                      // (§32/§34) are bottom sheets — deliberately no
                      // route for either, see `route_paths.dart`'s
                      // `workCreateLead` note.
                      GoRoute(
                        path: 'create',
                        builder: (context, state) => const CreateLeadScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'coworkers',
                    builder: (context, state) => const CoworkersListScreen(),
                    routes: [
                      // Declared before `:id` so the static `create`
                      // segment is matched first — same reasoning as
                      // `agentsListingDetail`'s note in `route_paths.dart`.
                      GoRoute(
                        path: 'create',
                        builder: (context, state) =>
                            const AddCoworkerScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => CoworkerDetailScreen(
                          coworkerId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) =>
                        const SettingsScreen(branchPrefix: RoutePaths.work),
                  ),
                  GoRoute(
                    path: 'connected-accounts',
                    builder: (context, state) =>
                        const ConnectedAccountsScreen(),
                  ),
                  GoRoute(
                    path: 'edit-listing/:id',
                    builder: (context, state) => EditListingScreen(
                      adId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'publish-status/:id',
                    builder: (context, state) => PublishStatusScreen(
                      adId: state.pathParameters['id']!,
                    ),
                  ),
                  // Work's own copies of `notifications`/`messages` — see
                  // `route_paths.dart`'s `workNotifications` note for why
                  // these are separate from Home's/Profile's.
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) => const MessagesScreen(),
                  ),
                  // `my-listings`' own copy of `listing-detail` — see
                  // `route_paths.dart`'s `workListingDetail` note.
                  GoRoute(
                    path: 'listing/:id',
                    builder: (context, state) => ListingDetailScreen(
                      adId: state.pathParameters['id']!,
                      branchPrefix: RoutePaths.work,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Agents ------------------------------------------------
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

          // Branch 4: Profile — one route; ProfileRoleScreen switches its
          // own content on role via ref.watch (see profile_role_screen.dart).
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
                  // Neither screen exists yet — `profile-agent`'s Connected
                  // Accounts/Messages rows and `settings`'s own Connected
                  // Accounts row (agent-only) push these so they at least
                  // resolve instead of 404ing; see `route_paths.dart`'s
                  // `profileConnectedAccounts`/`profileMessages` notes.
                  GoRoute(
                    path: 'connected-accounts',
                    builder: (context, state) =>
                        const ConnectedAccountsScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (context, state) => const MessagesScreen(),
                  ),
                  // Same convention as `/home`, `/search`, `/agents`'
                  // own copies — see `route_paths.dart`'s
                  // `agentsListingDetail` note — this branch needs its own
                  // because `saved-listings`'s grid pushes into it.
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

      // ---- Top-level routes: pushed on the root Navigator, above the
      // shell's Scaffold (and therefore above its tab bar). ------------

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
      GoRoute(
        path: RoutePaths.mapView,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
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
