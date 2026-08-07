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
  static const workCoworkers = '/work/coworkers';
  static const workCoworkerDetail = '/work/coworkers/:id';
  static const workSettings = '/work/settings';
  static const workConnectedAccounts = '/work/connected-accounts';
  static const workEditListing = '/work/edit-listing/:id';
  static const workPublishStatus = '/work/publish-status/:id';

  // ---- Branch 3: Agents --------------------------------------------------
  static const agents = '/agents';
  static const agentProfile = '/agents/:id';

  // ---- Branch 4: Profile (one route; content switches on role) -----------
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileSaved = '/profile/saved';
  static const profileSettings = '/profile/settings';

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
