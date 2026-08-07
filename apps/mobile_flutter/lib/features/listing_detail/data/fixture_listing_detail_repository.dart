/// Offline stand-in for [ListingDetailRepository], backed by
/// `listing_detail_fixtures.dart`'s SCREENS.md §4 seed data. No network, no
/// [LaCasaApi] dependency — this is what the screen renders from by default
/// (see `listing_detail_mode.dart`).
///
/// [fetchAd] throws the same shape the live path does for an unresolvable
/// id (an [ApiErrorException] carrying [ApiErrorCode.notFound] and status
/// 404) rather than returning `null` or a blank [Ad]. That keeps the
/// screen's terminal error branch on one code path in both modes — a
/// fixture that quietly answered "here is an empty listing" would let a
/// broken link render as a real, if oddly empty, page.
library;

import '../../../api/api.dart';
import 'listing_detail_fixtures.dart';
import 'listing_detail_repository.dart';

class FixtureListingDetailRepository implements ListingDetailRepository {
  const FixtureListingDetailRepository();

  @override
  Future<Ad> fetchAd(String id) async {
    for (final ad in listingDetailFixtureAds) {
      if (ad.id == id) return ad;
    }
    throw ApiErrorException(
      body: const ApiErrorBody(
        code: ApiErrorCode.notFound,
        message: 'Listing not found',
      ),
      statusCode: 404,
    );
  }

  @override
  Future<AgentDetail?> fetchAgent(String agentId) async {
    for (final agent in listingDetailFixtureAgents) {
      if (agent.id == agentId) return agent;
    }
    // Never throws — see [ListingDetailRepository.fetchAgent]'s contract.
    return null;
  }
}
