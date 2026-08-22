/// `my-listings` (SCREENS.md §25) — header "My Ads", with both of §25's
/// controls riding the nav header itself as round icon buttons (the
/// mockup's `.nav .rnd` pair), not a second toolbar row: **"Filter"**
/// → the CRM variant of `filter-sheet` (`showCrmFilterSheet`, build
/// contract rule 3/§3.1 — Sort + Status appended); **"+"** (Create New
/// Post) → `create-listing`. Rows: thumbnail; `#{id}`; Created At; City;
/// Status pill; Author; `{rooms} room`; `{area} m²`; edit icon →
/// `edit-listing`. Row tap (outside thumbnail/edit) → `listing-detail`.
/// Empty state: "Ads not found." Infinite scroll is a real paginated fetch
/// loop against `GET /my/ads`'s keyset paging — see
/// `data/my_listings_repository.dart`'s doc comment for how, and
/// `README.md`'s Known gaps for why this used to be a client-side-only
/// window.
///
/// **Three additions beyond §25's literal anatomy**, all from the UX audit,
/// each with its own file-level rationale:
/// - [MyListingsStageStrip] under the header — the All/Active/Sold/Draft
///   counts (§1 "Relocate"/§5.6), which also make the session-sticky stage
///   filter visible where it is applied.
/// - Per-row publish-channel badges (§9.2), inside `my_listing_row.dart`.
/// - A pull-to-refresh and two distinguishable empty states (§9.3/§9.4),
///   inside `my_listings_list.dart`.
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
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../filter/filter.dart';
import '../state/my_listings_providers.dart';
import 'my_listings_list.dart';
import 'my_listings_stage_strip.dart';

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

  /// Fetches the next real `GET /my/ads` page once the scroll position
  /// nears the bottom of what's currently rendered — see
  /// `my_listings_providers.dart`'s `MyListingsResultsNotifier.loadMore`
  /// doc comment; that method is itself a no-op if a page is already in
  /// flight or there is no next page, so calling it eagerly on every
  /// near-bottom scroll tick is safe.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    ref.read(myListingsResultsProvider.notifier).loadMore();
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
    // Each of these three is independently watched by
    // `MyListingsResultsNotifier.build()` (`my_listings_providers.dart`), so
    // setting the last one is what actually re-triggers the fetch — no
    // separate "reset the paging window" call is needed any more, unlike
    // before real server paging existed.
    ref.read(myListingsStatusProvider.notifier).setStatus(result.status);
  }

  void _openCreate() => context.push(RoutePaths.createListing);

  // `listing-detail` is not one of build contract §2.2's "Work-only
  // concept" screens (it has a copy under every branch) — within the Work
  // branch itself either push or go is fine (§2.2), so this pushes to stay
  // consistent with every other branch's own listing-detail entry point
  // (`SearchScreen._openListingDetail`, `AgentProfileScreen`'s grid, …).
  void _openListingDetail(Ad ad) {
    context.push(RoutePaths.workListingDetail.replaceFirst(':id', ad.id));
  }

  // `edit-listing` is one of build contract §2.2's "Work-only concept"
  // screens, but §2.2's `context.go` rule is about reaching one from
  // *another branch* (the bell in Home's header, say) — its own last
  // sentence says either verb is fine within the Work branch, and this
  // screen only ever lives in that branch. So this pushes: `go` replaces
  // the branch stack, which threw away this very screen (its applied
  // filters, its paged scroll position) on every edit-icon tap and left
  // `edit-listing`'s own `_leave()`/back arrow with nothing to pop to —
  // see `edit_listing_screen.dart`'s `_leave`. `edit-listing` is declared
  // as a child of `my-listings` in `app_router.dart` precisely so this
  // push has a real page underneath it.
  void _openEditListing(Ad ad) {
    context.push(RoutePaths.workEditListing.replaceFirst(':id', ad.id));
  }

  /// The row's channel badges tap through to `publish-status` (UX audit
  /// §9.2) — the screen that carries what a tint cannot: the error message
  /// on a FAILED row, the external URL on a PUBLISHED one, and Retry.
  /// Pushed, not `go`ne, for the same reason `_openEditListing` is: both
  /// routes are declared as children of `my-listings` in `app_router.dart`
  /// precisely so this screen (its filters, its paged scroll position)
  /// survives underneath them.
  void _openPublishStatus(Ad ad) {
    context.push(RoutePaths.workPublishStatus.replaceFirst(':id', ad.id));
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
            // The mockup's `.nav` carries both actions itself — a round
            // glass "filter" button and a round `--pill`-filled "+" —
            // rather than a second toolbar row below the header, so both
            // ride NavRow's own `trailing` slot.
            NavRow(
              title: AppLocalizations.of(context).myListingsNavTitle,
              onBack: () => _pop(context),
              trailing: [
                _FiltersButton(count: activeCount, onTap: _openFilters),
                const SizedBox(width: AppSpacing.xs),
                _CreateButton(onTap: _openCreate),
              ],
            ),
            // The stage-count strip rides the header, above the scroll
            // view rather than inside it — see
            // `my_listings_stage_strip.dart`: it is both the counts an
            // agent opens this screen for and the only always-visible
            // statement that a (session-sticky) stage filter is on, and
            // neither job survives being scrolled off the top.
            // No spacer around it: the strip owns its own padding and
            // collapses to zero height when the counts are unavailable, so
            // a spacer here would leave a gap with nothing in it.
            const MyListingsStageStrip(),
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: MyListingsList(
                  scrollController: _scrollController,
                  onTapAd: _openListingDetail,
                  onTapEdit: _openEditListing,
                  onTapPublishStatus: _openPublishStatus,
                  onCreate: _openCreate,
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

/// `.nav .rnd.gl` — the header's round glass filter button. SCREENS.md
/// §25 names this control **"Filter"**; the mockup shows no label next to
/// the glyph, so the word survives as the Semantics label instead.
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).myListingsFilterButtonLabel,
      child: GestureDetector(
        key: const ValueKey('myListingsFiltersButton'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: AppRadii.pill,
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: Icon(Icons.tune_rounded, size: 18, color: colors.ink),
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  key: const ValueKey('myListingsFiltersBadge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.pill,
                    borderRadius: AppRadii.pill,
                    border: Border.all(color: colors.screen, width: 2),
                  ),
                  child: Text(
                    '$count',
                    style: type.caption.copyWith(color: colors.pillInk),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// `.nav .rnd.acc` — the header's round "+" button. Its fill is
/// `var(--pill)`/`var(--pill-ink)`, not the accent gradient: `.rnd.acc`
/// inside a `.nav` resolves to the ink pill (mockup lines 204-205).
class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).myListingsCreateButtonSemanticsLabel,
      child: GestureDetector(
        key: const ValueKey('myListingsCreateButton'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.pill,
            borderRadius: AppRadii.pill,
          ),
          child: Icon(Icons.add_rounded, size: 20, color: colors.pillInk),
        ),
      ),
    );
  }
}
