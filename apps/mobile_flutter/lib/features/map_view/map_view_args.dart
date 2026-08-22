/// The `extra:` payload `RoutePaths.mapView` should carry, and the reason
/// `map-view` can finally tell "show me the search" apart from "show me
/// *this* flat".
///
/// `mapView` carries zero path params (see `route_paths.dart`), so
/// go_router's untyped `extra:` is the only channel a caller has. Both
/// callers used to pass a bare `List<Ad>` — `listing-search`'s map toggle
/// passing the current result set, and `listing-detail`'s Location section
/// passing a one-element list — and the route read it as
/// `state.extra is List<Ad>`.
/// Those two lists mean completely different things, and a `List<Ad>` cannot
/// say which: the screen watched the search provider either way, so a buyer
/// who tapped one listing's map got up to 20 unrelated listings a second
/// later, the camera framed around all of them, their own listing
/// unselected, and a Filters button for a search they never ran (audit
/// §4.5). The pin card's push target had the same shape of problem — it was
/// hardcoded `/search/listing/:id`, so a listing reached from Home grafted a
/// detail page onto the Search tab's stack.
///
/// [MapViewScreen] already took both distinctions as constructor arguments
/// ([MapViewScreen.focusAd], [MapViewScreen.branchPrefix]) — they were
/// simply unreachable, because no caller could say which mode it wanted.
/// This class is the typed carrier for them, so the route builder is a cast
/// rather than a re-decision.
///
/// **This is wired end to end now.** `app_router.dart`'s `mapView` builder
/// tests `extra is MapViewArgs` first and forwards all three fields, keeping
/// the bare-`List<Ad>` read beneath it for deep links and restored route
/// stacks. `listing_location_section.dart` sends
/// `MapViewArgs(focusAd: ad, branchPrefix: branchPrefix)`, its `branchPrefix`
/// handed down from `ListingDetailScreen`; `search_screen.dart#_openMap`
/// sends `MapViewArgs(ads: currentResults)`, which changes nothing about
/// search-mode behaviour — the screen still prefers live search state over
/// its fallback — and exists so the route has one payload type to read.
///
/// **Order mattered, and would matter again**: the route builder had to land
/// *before* either call site started sending a [MapViewArgs], because the
/// old builder tested `extra is List<Ad>` and would have silently dropped
/// the payload — the Location section's tap would have opened an empty
/// search map instead of a wrong one. A third caller should widen the route
/// first and switch the call site second, the same way round.
library;

import '../../api/api.dart';
import '../../navigation/route_paths.dart';

class MapViewArgs {
  const MapViewArgs({
    this.ads = const [],
    this.focusAd,
    this.branchPrefix = RoutePaths.search,
  });

  /// The caller's snapshot of the result set, used **only as a fallback**
  /// when live search state has nothing yet — see `map_view_screen.dart`'s
  /// doc comment for why the screen prefers the provider. Ignored entirely
  /// in [focusAd] mode.
  final List<Ad> ads;

  /// Set by a caller asking "where is *this* one?" rather than "where are
  /// the results?". Non-null puts the screen in single-listing mode: the
  /// search provider is never watched (so no search fetch is even started),
  /// this ad is the whole content and opens pre-selected, and the Filters
  /// button and partial-results chip are hidden — none of them means
  /// anything when the content is one property.
  final Ad? focusAd;

  /// Which shell branch the map was opened from, e.g. `/home` or `/search`.
  /// The preview card pushes `'$branchPrefix/listing/:id'`, the same
  /// contract `ListingDetailScreen` and `AgentProfileScreen` already take,
  /// so a listing reached from Home stays on Home's stack.
  final String branchPrefix;
}
