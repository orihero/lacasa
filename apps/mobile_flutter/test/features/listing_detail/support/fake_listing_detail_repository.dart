/// A [ListingDetailRepository] a test can steer: hand it the ad and agent
/// it should answer with, make either throw, or make either hang so the
/// loading state is observable.
///
/// Deliberately not backed by `listing_detail_fixtures.dart` — a test that
/// asserts "the Nearby Places heading disappears for an ad with no nearby
/// places" must own that ad, not depend on which fixture happens to have an
/// empty list this month.
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_detail/listing_detail.dart';

class FakeListingDetailRepository implements ListingDetailRepository {
  FakeListingDetailRepository({this.ad, this.agent});

  Ad? ad;
  AgentDetail? agent;

  /// When set, [fetchAd] throws this instead of returning [ad].
  Object? adError;

  /// When true, [fetchAd] never completes — the loading state.
  bool adHangs = false;

  /// Counts calls, so a Retry assertion can prove a re-fetch happened
  /// rather than inferring it from the UI settling.
  int fetchAdCalls = 0;
  int fetchAgentCalls = 0;

  @override
  Future<Ad> fetchAd(String id) {
    fetchAdCalls++;
    if (adHangs) return Completer<Ad>().future;
    if (adError != null) return Future.error(adError!);
    final current = ad;
    if (current == null) {
      return Future.error(
        ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.notFound,
            message: 'Listing not found',
          ),
          statusCode: 404,
        ),
      );
    }
    return Future.value(current);
  }

  @override
  Future<AgentDetail?> fetchAgent(String agentId) async {
    fetchAgentCalls++;
    return agent;
  }
}
