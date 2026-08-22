/// Inert stand-in for [ListingDetailRepository], for tests that mount a
/// surface which happens to reach the listing-detail providers without
/// caring what they return.
///
/// It exists because every repository provider now unconditionally builds
/// its live implementation around `LaCasaApi.create()` — the old
/// `Fixture*Repository` classes and the `FLUTTER_TEST` switch in
/// `lib/api/app_mode.dart` that forced them are gone. Widget tests that
/// build the real router mount a shell touching nearly every repository, so
/// a provider left un-overridden fires real HTTP from the test process and
/// the test dies on a `pumpAndSettle` timeout. Overriding the provider with
/// this class makes that impossible: no network, no throwing, no delay.
///
/// Deliberately inert, and that is the whole contract. Every method returns
/// the emptiest value its signature permits and none of them throw — not
/// even [fetchAd], whose real implementations surface `notFound` as an
/// [ApiErrorException], because a test that did not opt into this feature
/// should not have to handle an error state either. A test that actually
/// exercises listing-detail behaviour (a real ad, a missing agent, the
/// terminal error state) must NOT reach for this class; it should override
/// the provider with a purpose-built fake from
/// `test/features/listing_detail/support/` that returns the data that test
/// is about.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_detail/data/listing_detail_repository.dart';

class InertListingDetailRepository implements ListingDetailRepository {
  const InertListingDetailRepository();

  /// The blankest [Ad] the model allows: empty strings, `null` everywhere
  /// nullable, empty lists, a zero price and epoch timestamps. Enum fields
  /// take a real member rather than the `unknown` sentinel, because
  /// `unknown` throws from its `wire` getter and the point of this class is
  /// that nothing downstream of it can blow up.
  @override
  Future<Ad> fetchAd(String id) async => Ad(
    id: id,
    title: '',
    city: '',
    district: '',
    address: null,
    reference: null,
    type: AdType.residential,
    category: AdCategory.sale,
    repairment: null,
    rooms: null,
    area: null,
    storey: null,
    floors: null,
    furniture: null,
    hashtags: null,
    price: 0,
    priceType: CurrencyCode.uzs,
    stage: AdStage.active,
    description: null,
    nearPlacesList: const [],
    optionList: null,
    active: false,
    lat: null,
    lng: null,
    tour3dLink: null,
    agentId: '',
    coworkerId: '',
    photos: const [],
    media: const [],
    createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  /// `null` is already the interface's own degraded answer — the agent block
  /// renders its "unavailable" state and the rest of the listing is
  /// unaffected — so the inert value here is also the honest one.
  @override
  Future<AgentDetail?> fetchAgent(String agentId) async => null;
}
