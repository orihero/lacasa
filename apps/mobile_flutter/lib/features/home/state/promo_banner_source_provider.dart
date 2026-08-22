/// Picks the [PromoBannerSource] `promo_carousel.dart` reads, mirroring
/// `home_feed_repository_provider.dart`'s shape so the two Home data seams
/// read the same way.
///
/// There is only one implementation today and only one reason for that (no
/// promotions endpoint and no admin surface — see `data/promo_banner.dart`).
/// This provider is the entire cost of making that reversible: when a backend
/// lands, the body below becomes `LivePromoBannerSource(LaCasaApi.create())`
/// and nothing in `widgets/` changes. Tests override it the same way they
/// override `homeFeedRepositoryProvider`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_promo_banner_source.dart';
import '../data/promo_banner.dart';

final promoBannerSourceProvider = Provider<PromoBannerSource>((ref) {
  return const LocalPromoBannerSource();
});
