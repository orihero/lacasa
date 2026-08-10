/// Offline stand-in for [ListingEditorRepository], seeded from
/// `work_seed_data.dart`'s [workAdsFixtures] and kept mutable **within this
/// repository instance's own lifetime** — a create/update/delete actually
/// changes what a later [getById]/[publishStatus] call on the same instance
/// sees, so a session that creates then immediately edits an ad (or
/// publishes then checks `publish-status`) gets a coherent answer with zero
/// network. Publish attempts are recorded the same way, so
/// `publish-channels-sheet` → `publish-status` is a genuine offline loop,
/// not two screens that coincidentally both compile.
///
/// **What this does NOT do**: this instance's mutations are invisible to
/// `my_listings`' own `FixtureMyListingsRepository` — each Work feature
/// builds its own fixture repository per `WORK_TAB_CONTRACT.md`'s
/// convention, and nothing in this build wires a shared, cross-feature
/// mutable ad store. A listing created here will not appear in `my-listings`
/// after navigating back to it in fixture mode. This is a known, accepted
/// limit of the fixture architecture (every other feature's own fixture
/// repository has the identical limit), not something this file can fix on
/// its own — see this feature's own return-value report for the explicit
/// flag.
library;

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import 'listing_editor_repository.dart';

class FixtureListingEditorRepository implements ListingEditorRepository {
  FixtureListingEditorRepository() : _ads = List.of(workAdsFixtures);

  final List<Ad> _ads;
  final Map<String, Map<Channel, ChannelStatus>> _publishState = {};
  int _nextIdSuffix = 9001;

  static const List<ConnectedInstagramAccount> _instagramAccounts = [
    ConnectedInstagramAccount(
      igUserId: 'ig-lacasa-demo',
      username: 'lacasa.realty',
      expiresAt: null,
      profilePictureUrl: null,
      mediaCount: 128,
      followersCount: 4302,
      followsCount: 210,
    ),
  ];

  @override
  Future<Ad> getById(String id) async {
    for (final ad in _ads) {
      if (ad.id == id) return ad;
    }
    throw _notFound('Listing not found');
  }

  @override
  Future<Ad> create(AdWriteInput input) async {
    final now = DateTime.now().toUtc();
    final blank = Ad(
      id: 'ad-${_nextIdSuffix++}',
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
      optionList: const [],
      active: true,
      lat: null,
      lng: null,
      tour3dLink: null,
      agentId: 'agent-javlon',
      coworkerId: '',
      photos: const [],
      media: const [],
      createdAt: now,
      updatedAt: now,
    );
    final created = _applyWrite(blank, input);
    _ads.insert(0, created);
    return created;
  }

  @override
  Future<Ad> update(String id, AdWriteInput input) async {
    final index = _ads.indexWhere((a) => a.id == id);
    if (index == -1) throw _notFound('Listing not found');
    final updated = _applyWrite(_ads[index], input);
    _ads[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    final removed = _ads.any((a) => a.id == id);
    _ads.removeWhere((a) => a.id == id);
    if (!removed) throw _notFound('Listing not found');
  }

  @override
  Future<AdPublishStatus> publishStatus(String adId) async {
    final byChannel = _publishState[adId];
    final channels = [
      for (final channel in Channel.allChannels)
        byChannel?[channel] ??
            ChannelStatus(
              channel: channel,
              status: PublishStatus.pending,
              externalUrl: null,
              externalId: null,
              lastAttemptAt: null,
              errorMessage: null,
            ),
    ];
    return AdPublishStatus(adId: adId, channels: channels);
  }

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async =>
      _instagramAccounts;

  @override
  Future<PublishAttemptResponse> publishInstagram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    List<String>? igUserIds,
  }) async {
    final targets = igUserIds ?? _instagramAccounts.map((a) => a.igUserId).toList();
    final publication = _recordAttempt(adId, Channel.instagram);
    return PublishAttemptResponse(
      publication: publication,
      results: [
        for (final target in targets)
          PublishAttemptResult(
            target: target,
            ok: true,
            mediaOrMessageId: 'fixture-media-$target',
            error: null,
          ),
      ],
    );
  }

  @override
  Future<PublishAttemptResponse> publishTelegram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    required List<String> chatIds,
  }) async {
    final publication = _recordAttempt(adId, Channel.telegram);
    return PublishAttemptResponse(
      publication: publication,
      results: [
        for (final chatId in chatIds)
          PublishAttemptResult(
            target: chatId,
            ok: true,
            mediaOrMessageId: 'fixture-message-$chatId',
            error: null,
          ),
      ],
    );
  }

  Publication _recordAttempt(String adId, Channel channel) {
    final now = DateTime.now().toUtc();
    final byChannel = _publishState.putIfAbsent(adId, () => {});
    byChannel[channel] = ChannelStatus(
      channel: channel,
      status: PublishStatus.published,
      externalUrl: null,
      externalId: null,
      lastAttemptAt: now,
      errorMessage: null,
    );
    return Publication(
      id: 'fixture-pub-$adId-${channel.wire}',
      adId: adId,
      channel: channel,
      status: PublishStatus.published,
      externalId: null,
      externalUrl: null,
      attempts: 1,
      lastAttemptAt: now,
      publishedAt: now,
      errorMessage: null,
    );
  }

  Ad _applyWrite(Ad base, AdWriteInput w) {
    return Ad(
      id: base.id,
      title: w.title?.value ?? base.title,
      city: w.city?.value ?? base.city,
      district: w.district?.value ?? base.district,
      address: w.address != null ? w.address!.value : base.address,
      reference: w.reference != null ? w.reference!.value : base.reference,
      type: w.type?.value ?? base.type,
      category: w.category?.value ?? base.category,
      repairment: w.repairment != null ? w.repairment!.value : base.repairment,
      rooms: w.rooms != null ? w.rooms!.value : base.rooms,
      area: w.area != null ? w.area!.value : base.area,
      storey: w.storey != null ? w.storey!.value : base.storey,
      floors: w.floors != null ? w.floors!.value : base.floors,
      furniture: w.furniture != null ? w.furniture!.value : base.furniture,
      hashtags: w.hashtags != null ? w.hashtags!.value : base.hashtags,
      price: w.price?.value ?? base.price,
      priceType: w.priceType?.value ?? base.priceType,
      stage: w.stage?.value ?? base.stage,
      description: w.description != null ? w.description!.value : base.description,
      nearPlacesList: w.nearPlacesList?.value ?? base.nearPlacesList,
      optionList: w.optionList?.value ?? base.optionList,
      active: w.active?.value ?? base.active,
      lat: w.lat != null ? w.lat!.value : base.lat,
      lng: w.lng != null ? w.lng!.value : base.lng,
      tour3dLink: w.tour3dLink != null ? w.tour3dLink!.value : base.tour3dLink,
      agentId: base.agentId,
      coworkerId: base.coworkerId,
      photos: w.photos?.value ?? base.photos,
      media: base.media,
      createdAt: base.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  ApiErrorException _notFound(String message) => ApiErrorException(
    body: ApiErrorBody(code: ApiErrorCode.notFound, message: message),
    statusCode: 404,
  );
}
