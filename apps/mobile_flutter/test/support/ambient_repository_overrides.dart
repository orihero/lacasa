/// Provider overrides that keep a widget test off the network, for every
/// repository the test is *not* about.
///
/// **Why this exists.** Every feature used to ship a
/// `Fixture<Feature>Repository` full of bundled seed rows, and
/// `lib/api/app_mode.dart` forced those fixtures whenever `FLUTTER_TEST` was
/// set. A widget test could therefore pump a screen, override only the one
/// repository it cared about, and rely on the guard to keep everything else
/// off the network.
///
/// The fixture repositories are deleted and that guard is gone with them.
/// Every repository provider now unconditionally builds a live
/// implementation around `LaCasaApi.create()`, so an un-overridden provider
/// fires real HTTP out of the test process. That does not fail cleanly — it
/// *hangs*, and the test dies on `pumpAndSettle timed out` with nothing in
/// the output pointing at which provider was responsible.
///
/// **This is worse than it sounds for router-based tests.** Anything that
/// reads `goRouterProvider` and pumps the real router mounts the whole app
/// shell, which touches nearly every repository in the app — not just the
/// feature under test. That is why this list covers all of them rather than
/// the two or three a given screen obviously needs.
///
/// Spread it into the test's `overrides`, alongside the test's own:
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     ...ambientRepositoryOverrides(listingDetail: false),
///     listingDetailRepositoryProvider.overrideWithValue(fake),
///   ],
///   child: ...,
/// )
/// ```
///
/// **Every entry has an opt-out flag because Riverpod rejects a duplicate
/// override outright** — a container built with the same provider overridden
/// twice throws `Tried to override a provider twice within the same
/// container` rather than letting the later entry win. So switch off the one
/// the test supplies itself, as above; do not override on top of it.
///
/// **Nothing here is fixture data.** Every implementation returns the
/// emptiest value its signature allows and none of them throw, so a screen
/// built on one renders its empty state and settles. An empty feed is the
/// *absence* of a fixture, not a small one — a test that asserts against
/// content must override that provider with a purpose-built fake from
/// `test/features/<feature>/support/`, which is also where a fake that
/// records calls belongs.
library;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/state/agents_repository_provider.dart';
import 'package:lacasa_mobile/features/auth/data/auth_repository.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/contact/state/contact_repository_provider.dart';
import 'package:lacasa_mobile/features/coworkers/state/coworkers_repository_provider.dart';
import 'package:lacasa_mobile/features/filter/state/filter_repository_provider.dart';
import 'package:lacasa_mobile/features/filter/state/regions_repository_provider.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/leads/state/leads_repository_provider.dart';
import 'package:lacasa_mobile/features/listing_detail/state/listing_detail_repository_provider.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_repository_provider.dart';
import 'package:lacasa_mobile/features/saved_listings/state/saved_listings_repository_provider.dart';
import 'package:lacasa_mobile/features/search/data/recent_searches_repository.dart';
import 'package:lacasa_mobile/features/search/state/recent_searches_repository_provider.dart';
import 'package:lacasa_mobile/features/search/state/search_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';
import 'package:lacasa_mobile/features/work_misc/state/connected_accounts_repository_provider.dart';
import 'package:lacasa_mobile/features/work_misc/state/notifications_repository_provider.dart';
import 'package:lacasa_mobile/shared/state/favourite_ad_ids_provider.dart';
import 'package:lacasa_mobile/shared/state/favourite_ad_ids_repository.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository_provider.dart';

import 'inert/inert_agents_repository.dart';
import 'inert/inert_connected_accounts_repository.dart';
import 'inert/inert_contact_repository.dart';
import 'inert/inert_coworkers_repository.dart';
import 'inert/inert_dashboard_repository.dart';
import 'inert/inert_filter_repository.dart';
import 'inert/inert_home_feed_repository.dart';
import 'inert/inert_leads_repository.dart';
import 'inert/inert_listing_detail_repository.dart';
import 'inert/inert_listing_editor_repository.dart';
import 'inert/inert_my_listings_repository.dart';
import 'inert/inert_notifications_repository.dart';
import 'inert/inert_regions_repository.dart';
import 'inert/inert_saved_listings_repository.dart';
import 'inert/inert_search_repository.dart';
import 'inert/inert_uploads_repository.dart';

/// Nothing is favourited, and favouriting is a no-op that succeeds.
class InertFavouriteAdIdsRepository implements FavouriteAdIdsRepository {
  const InertFavouriteAdIdsRepository();

  @override
  Future<Set<String>> fetchInitialSavedAdIds() async => const <String>{};

  @override
  Future<void> saveAd(String adId) async {}

  @override
  Future<void> unsaveAd(String adId) async {}
}

/// Signed out, and staying that way.
///
/// [currentUser] is the one that matters: `AuthSessionNotifier.build()` fires
/// a startup session restore on a microtask for every screen that sits under
/// a router shell, and the live repository answers it with a real
/// `GET /auth/me`. Throwing `unauthorized` is the documented way to say
/// "there is no persisted session" — the same answer the live repository
/// gives when nothing is signed in — so the notifier settles immediately on
/// signed-out rather than waiting out its 8-second restore timeout.
///
/// The command methods throw [UnimplementedError] rather than returning a
/// plausible user: a test that actually exercises sign-in should override
/// this provider with `FakeAuthRepository`
/// (`test/features/auth/support/fake_auth_repository.dart`), which is built
/// for it, and failing loudly here is what tells you to.
class SignedOutAuthRepository implements AuthRepository {
  const SignedOutAuthRepository();

  @override
  Future<AuthUser> currentUser() async => throw ApiErrorException(
    body: const ApiErrorBody(
      code: ApiErrorCode.unauthorized,
      message: 'No persisted session',
    ),
    statusCode: 401,
  );

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> login({required String email, required String password}) =>
      throw UnimplementedError(
        'override authRepositoryProvider with FakeAuthRepository to test login',
      );

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) => throw UnimplementedError(
    'override authRepositoryProvider with FakeAuthRepository to test register',
  );

  @override
  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) => throw UnimplementedError(
    'override authRepositoryProvider with FakeAuthRepository to test profile '
    'updates',
  );
}

/// No recent searches, and recording one is a no-op that succeeds.
class InertRecentSearchesRepository implements RecentSearchesRepository {
  const InertRecentSearchesRepository();

  @override
  Future<List<String>> load() async => const <String>[];

  @override
  Future<void> save(List<String> recents) async {}
}

/// See this library's doc comment — including why every entry has an opt-out
/// flag rather than being unconditionally present.
///
/// `Override` is exported from `flutter_riverpod/misc.dart` rather than the
/// package's main library, hence the narrow `show` import above.
List<Override> ambientRepositoryOverrides({
  bool agents = true,
  bool auth = true,
  bool connectedAccounts = true,
  bool contact = true,
  bool coworkers = true,
  bool dashboard = true,
  bool favourites = true,
  bool filter = true,
  bool homeFeed = true,
  bool leads = true,
  bool listingDetail = true,
  bool listingEditor = true,
  bool myListings = true,
  bool notifications = true,
  bool recentSearches = true,
  bool regions = true,
  bool savedListings = true,
  bool search = true,
  bool uploads = true,
}) => [
  if (agents)
    agentsRepositoryProvider.overrideWithValue(const InertAgentsRepository()),
  if (auth)
    authRepositoryProvider.overrideWithValue(const SignedOutAuthRepository()),
  if (connectedAccounts)
    connectedAccountsRepositoryProvider.overrideWithValue(
      const InertConnectedAccountsRepository(),
    ),
  if (contact)
    contactRepositoryProvider.overrideWithValue(const InertContactRepository()),
  if (coworkers)
    coworkersRepositoryProvider.overrideWithValue(
      const InertCoworkersRepository(),
    ),
  if (dashboard)
    dashboardRepositoryProvider.overrideWithValue(
      const InertDashboardRepository(),
    ),
  if (favourites)
    favouriteAdIdsRepositoryProvider.overrideWithValue(
      const InertFavouriteAdIdsRepository(),
    ),
  if (filter)
    filterRepositoryProvider.overrideWithValue(const InertFilterRepository()),
  if (homeFeed)
    homeFeedRepositoryProvider.overrideWithValue(
      const InertHomeFeedRepository(),
    ),
  if (leads)
    leadsRepositoryProvider.overrideWithValue(const InertLeadsRepository()),
  if (listingDetail)
    listingDetailRepositoryProvider.overrideWithValue(
      const InertListingDetailRepository(),
    ),
  if (listingEditor)
    listingEditorRepositoryProvider.overrideWithValue(
      const InertListingEditorRepository(),
    ),
  if (myListings)
    myListingsRepositoryProvider.overrideWithValue(
      const InertMyListingsRepository(),
    ),
  if (notifications)
    notificationsRepositoryProvider.overrideWithValue(
      const InertNotificationsRepository(),
    ),
  if (recentSearches)
    recentSearchesRepositoryProvider.overrideWithValue(
      const InertRecentSearchesRepository(),
    ),
  if (regions)
    regionsRepositoryProvider.overrideWithValue(const InertRegionsRepository()),
  if (savedListings)
    savedListingsRepositoryProvider.overrideWithValue(
      const InertSavedListingsRepository(),
    ),
  if (search)
    searchRepositoryProvider.overrideWithValue(const InertSearchRepository()),
  if (uploads)
    uploadsRepositoryProvider.overrideWithValue(const InertUploadsRepository()),
];
