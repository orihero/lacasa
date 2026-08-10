/// `my-listings` (SCREENS.md §25) — header "My Ads". Toolbar: **"Filter"**
/// → the CRM variant of `filter-sheet` (`showCrmFilterSheet`, build
/// contract rule 3/§3.1 — Sort + Status appended); **"+"** (Create New
/// Post) → `create-listing`. Rows: thumbnail; `#{id}`; Created At; City;
/// Status pill; Author; `{rooms} room`; `{area} m²`; edit icon →
/// `edit-listing`. Row tap (outside thumbnail/edit) → `listing-detail`.
/// Empty state: "Ads not found." Infinite scroll — see
/// `data/my_listings_repository.dart`'s doc comment (build contract §7.7)
/// for why this is a client-side paging window, never a real paginated
/// fetch.
///
/// **Router wiring**: this screen takes no constructor arguments and reads
/// no path params (build contract §2's exact table) — swap
/// `app_router.dart`'s `/work/my-listings` branch-root placeholder for
/// `const MyListingsScreen()`.
///
/// **Reached two different ways** (SCREENS.md §1/§5), both already correct
/// with no `branchPrefix` needed since every push/go below hardcodes an
/// absolute `/work/...` path — this screen is *only* ever mounted inside
/// the Work branch, never another tab's:
/// - **Agent session**: pushed from `dashboard` (`RoutePaths.workDashboard`
///   → `RoutePaths.workMyListings`), so it has something to pop back to.
/// - **Coworker session**: the Work branch's own root (§5: "`role:
///   "coworker"` opens Work directly on `my-listings`, skips `dashboard`"),
///   so a deep link here has nothing to pop — [_pop] falls back to
///   `context.go(RoutePaths.work)` exactly like every other pushed-or-root
///   screen in this app (`SettingsScreen`/`SavedListingsScreen`'s own
///   identical `_pop`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../filter/filter.dart';
import '../state/my_listings_providers.dart';
import 'my_listings_list.dart';
import 'my_listings_toolbar.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Reveals the next page of the client-side paging window once the
  /// scroll position nears the bottom of what's currently rendered — see
  /// `my_listings_providers.dart`'s `myListingsVisibleCountProvider` doc
  /// comment for why this can only ever page an already-fetched list.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    final total = ref.read(displayedMyListingsProvider).value?.length ?? 0;
    final visible = ref.read(myListingsVisibleCountProvider);
    if (visible < total) {
      ref.read(myListingsVisibleCountProvider.notifier).showMore();
    }
  }

  Future<void> _openFilters() async {
    final result = await showCrmFilterSheet(
      context,
      initialFilters: ref.read(appliedMyListingsFiltersProvider),
      initialSort: ref.read(myListingsSortProvider),
      initialStatus: ref.read(myListingsStatusProvider),
    );
    if (result == null || !mounted) return;

    ref.read(appliedMyListingsFiltersProvider.notifier).apply(result.filters);
    ref
        .read(myListingsSortProvider.notifier)
        .setSort(result.sort ?? AdSort.newest);
    ref.read(myListingsStatusProvider.notifier).setStatus(result.status);
    ref.read(myListingsVisibleCountProvider.notifier).reset();
  }

  void _openCreate() => context.push(RoutePaths.createListing);

  // `listing-detail` is not one of build contract §2.2's "Work-only
  // concept" screens (it has a copy under every branch) — within the Work
  // branch itself either push or go is fine (§2.2), so this pushes to stay
  // consistent with every other branch's own listing-detail entry point
  // (`SearchScreen._openListingDetail`, `AgentProfileScreen`'s grid, …).
  void _openListingDetail(Ad ad) {
    context.push('${RoutePaths.work}/listing/${ad.id}');
  }

  // `edit-listing` IS one of §2.2's Work-only-concept screens — its own
  // table row explicitly calls for `context.go`, not `push`, regardless of
  // which branch is doing the pushing (irrelevant here, since this screen
  // only ever lives in the Work branch anyway, but followed literally per
  // the contract).
  void _openEditListing(Ad ad) {
    context.go('${RoutePaths.work}/edit-listing/${ad.id}');
  }

  void _pop(BuildContext context) {
    // Same reasoning as `SettingsScreen`/`SavedListingsScreen`'s own
    // `_pop`: a coworker session's deep link straight into this screen (or
    // any restored route) has nothing to pop, and "up" is just the Work
    // branch root rather than an error.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final activeCount = ref.watch(activeMyListingsFilterCountProvider);

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(title: 'My Ads', onBack: () => _pop(context)),
            const SizedBox(height: AppSpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: MyListingsToolbar(
                activeFilterCount: activeCount,
                onOpenFilters: _openFilters,
                onCreate: _openCreate,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: MyListingsList(
                  scrollController: _scrollController,
                  onTapAd: _openListingDetail,
                  onTapEdit: _openEditListing,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 90),
          ],
        ),
      ),
    );
  }
}
