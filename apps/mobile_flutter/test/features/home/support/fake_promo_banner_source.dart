/// A [PromoBannerSource] that hands back whatever the test hands it, so a
/// test can pin the exact banner shape it is about (no URL, an empty list, a
/// URL that will fail) instead of asserting through
/// `LocalPromoBannerSource`'s two real photographs.
library;

import 'package:lacasa_mobile/features/home/data/promo_banner.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

class FakePromoBannerSource implements PromoBannerSource {
  const FakePromoBannerSource(this.banners);

  final List<PromoBanner> banners;

  @override
  List<PromoBanner> promos(AppLocalizations l10n) => banners;
}
