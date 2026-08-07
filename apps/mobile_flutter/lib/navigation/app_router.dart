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
///    redirect the instant role changes (e.g. an agent signs out while
///    sitting on `/work/leads`), without an app restart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home.dart';
import '../features/listing_detail/listing_detail.dart';
import '../features/photo_gallery/photo_gallery.dart';
import '../features/search/search.dart';
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

/// `/work*` guard + `/work` initial-screen-by-role redirect (build spec,
/// "Work's initial screen by role" and "Why the Work branch always
/// exists", point 2).
String? _redirect(GoRouterState state, AuthSessionState authState) {
  final loc = state.matchedLocation;
  final onWorkBranch =
      loc == RoutePaths.work || loc.startsWith('${RoutePaths.work}/');
  if (!onWorkBranch) return null;

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

  return null;
}

/// Bridges [authSessionProvider] to [GoRouter]'s `refreshListenable`, so
/// [_redirect] is re-evaluated the instant role changes — with no restart
/// and, importantly, without rebuilding [GoRouter] itself (which would
/// destroy every branch's [Navigator] and its back stack). This is the
/// *only* job this class has: the tab bar's own visible-item-set reactivity
/// goes through [WidgetRef.watch] directly in `GlassTabBar`, not through
/// this class.
class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Ref ref) {
    _subscription = ref.listen<AuthSessionState>(authSessionProvider, (
      previous,
      next,
    ) {
      if (previous?.role != next.role) notifyListeners();
    });
  }

  late final ProviderSubscription<AuthSessionState> _subscription;

  @override
  void dispose() {
    _subscription.close();
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
    redirect: (context, state) =>
        _redirect(state, ref.read(authSessionProvider)),
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
                    builder: (context, state) =>
                        _placeholder('Agent ${state.pathParameters['id']}'),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => _placeholder('Notifications'),
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
                    builder: (context, state) =>
                        _placeholder('Agent ${state.pathParameters['id']}'),
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
                // Never actually renders: `_redirect` always sends `/work`
                // itself on to a concrete sub-route or bounces it to
                // `/home`. Kept as a harmless placeholder for the instant
                // between navigation and redirect evaluation.
                builder: (context, state) => _placeholder('Work'),
                routes: [
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) => _placeholder('Dashboard'),
                  ),
                  GoRoute(
                    path: 'my-listings',
                    builder: (context, state) => _placeholder('My Listings'),
                  ),
                  GoRoute(
                    path: 'leads',
                    builder: (context, state) => _placeholder('Leads'),
                    routes: [
                      GoRoute(
                        path: 'kanban',
                        builder: (context, state) =>
                            _placeholder('Leads Kanban'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'coworkers',
                    builder: (context, state) => _placeholder('Coworkers'),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => _placeholder(
                          'Coworker ${state.pathParameters['id']}',
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => _placeholder('Work Settings'),
                  ),
                  GoRoute(
                    path: 'connected-accounts',
                    builder: (context, state) =>
                        _placeholder('Connected Accounts'),
                  ),
                  GoRoute(
                    path: 'edit-listing/:id',
                    builder: (context, state) => _placeholder(
                      'Edit Listing ${state.pathParameters['id']}',
                    ),
                  ),
                  GoRoute(
                    path: 'publish-status/:id',
                    builder: (context, state) => _placeholder(
                      'Publish Status ${state.pathParameters['id']}',
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
                builder: (context, state) => _placeholder('Agents'),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        _placeholder('Agent ${state.pathParameters['id']}'),
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
                    builder: (context, state) => _placeholder('Edit Profile'),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (context, state) => _placeholder('Saved'),
                  ),
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) =>
                        _placeholder('Profile Settings'),
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
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: _placeholder('Onboarding'),
        ),
      ),
      GoRoute(
        path: RoutePaths.login,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            MaterialPage(fullscreenDialog: true, child: _placeholder('Login')),
      ),
      GoRoute(
        path: RoutePaths.register,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: _placeholder('Register'),
        ),
      ),
      GoRoute(
        path: RoutePaths.createListing,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: _placeholder('Create Listing'),
        ),
      ),
      GoRoute(
        path: RoutePaths.permissionsPrimer,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => MaterialPage(
          fullscreenDialog: true,
          child: _placeholder('Permissions Primer'),
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
      GoRoute(
        path: RoutePaths.mapView,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => _placeholder('Map View'),
      ),
    ],
  );
});
