/// Picks [FixtureListingDetailRepository] or [LiveListingDetailRepository]
/// once, per `listing_detail_mode.dart`'s compile-time switch. Every other
/// listing-detail provider reads through this one instead of constructing a
/// repository itself — which is also the single point every widget test
/// overrides.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/fixture_listing_detail_repository.dart';
import '../data/listing_detail_mode.dart';
import '../data/listing_detail_repository.dart';
import '../data/live_listing_detail_repository.dart';

final listingDetailRepositoryProvider = Provider<ListingDetailRepository>((
  ref,
) {
  if (useLiveListingDetailApi) {
    return LiveListingDetailRepository(LaCasaApi.create());
  }
  return const FixtureListingDetailRepository();
});
