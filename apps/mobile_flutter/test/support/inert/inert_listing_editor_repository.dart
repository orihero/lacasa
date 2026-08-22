/// The do-nothing [ListingEditorRepository] the ambient test overrides mount
/// in place of the live, `LaCasaApi`-backed implementation.
///
/// Every repository provider in this app now builds a network-backed
/// implementation unconditionally — the old `Fixture*Repository` classes and
/// the `FLUTTER_TEST` switch in `lib/api/app_mode.dart` that forced them are
/// gone. Widget tests that build the real router mount a shell touching
/// nearly every feature's repository, so any provider a test leaves
/// un-overridden fires real HTTP from the test process and the test dies on
/// "pumpAndSettle timed out". This class exists purely to stop that: it
/// answers every method of the seam immediately, with the emptiest value the
/// return type allows, and never throws.
///
/// It is deliberately inert — it has no state, records nothing, and asserts
/// nothing. A test that wants create/edit/publish to actually *behave*
/// (returning a seeded [Ad], reporting a channel as PUBLISHED, failing a
/// retry with a specific [ApiErrorException] code) must not extend or tweak
/// this class; override the provider with a purpose-built fake from
/// `test/features/listing_editor/support/` instead, so the behaviour a test
/// depends on lives next to that test rather than in this shared default.
///
/// Note the two non-nullable object returns, [getById]/[create]/[update]'s
/// [Ad] and the three publish calls' [PublishAttemptResponse]: neither type
/// has an "empty" value, so this returns the smallest structurally valid
/// instance — empty strings, zero price, `unknown` enums, epoch timestamps,
/// a PENDING publication with no results. Treat those as placeholders, not
/// as anything a test should assert against.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/data/listing_editor_repository.dart';

class InertListingEditorRepository implements ListingEditorRepository {
  const InertListingEditorRepository();

  @override
  Future<Ad> getById(String id) async => _emptyAd(id);

  @override
  Future<Ad> create(AdWriteInput input) async => _emptyAd('');

  @override
  Future<Ad> update(String id, AdWriteInput input) async => _emptyAd(id);

  @override
  Future<void> delete(String id) async {}

  /// Empty `channels`, not the 5 synthesized PENDING rows the real endpoint
  /// guarantees — `publish-status` renders an empty list harmlessly, and a
  /// test that cares about the rows should supply its own fake.
  @override
  Future<AdPublishStatus> publishStatus(String adId) async =>
      AdPublishStatus(adId: adId, channels: const []);

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async => const [];

  @override
  Future<PublishAttemptResponse> publishInstagram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    List<String>? igUserIds,
  }) async => _emptyAttempt(adId: adId, channel: Channel.instagram);

  @override
  Future<PublishAttemptResponse> publishTelegram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    required List<String> chatIds,
  }) async => _emptyAttempt(adId: adId, channel: Channel.telegram);

  @override
  Future<PublishAttemptResponse> retryPublish({
    required String adId,
    required Channel channel,
  }) async => _emptyAttempt(adId: adId, channel: channel);

  /// The smallest structurally valid [Ad]. Timestamps use the same epoch
  /// fallback `Ad.fromJson` itself falls back to for a missing wire value.
  static Ad _emptyAd(String id) => Ad(
    id: id,
    title: '',
    city: '',
    district: '',
    address: null,
    reference: null,
    type: AdType.unknown,
    category: AdCategory.unknown,
    repairment: null,
    rooms: null,
    area: null,
    storey: null,
    floors: null,
    furniture: null,
    hashtags: null,
    price: 0,
    priceType: CurrencyCode.unknown,
    stage: AdStage.unknown,
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

  /// A PENDING publication with no per-target results — the "nothing has
  /// happened yet" shape, for the channel the caller asked about.
  static PublishAttemptResponse _emptyAttempt({
    required String adId,
    required Channel channel,
  }) => PublishAttemptResponse(
    publication: Publication(
      id: '',
      adId: adId,
      channel: channel,
      status: PublishStatus.pending,
      externalId: null,
      externalUrl: null,
      attempts: 0,
      lastAttemptAt: null,
      publishedAt: null,
      errorMessage: null,
    ),
    results: const [],
  );
}
