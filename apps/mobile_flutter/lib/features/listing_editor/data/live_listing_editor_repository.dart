/// The real, network-backed [ListingEditorRepository] — a thin adapter over
/// [LaCasaApi], adding no wire shapes of its own. [getById] deliberately
/// goes through [LaCasaApi.ads] (the public `GET /ads/:id`), not
/// [LaCasaApi.agentAds] (which has no single-ad read at all) — see
/// `listing_editor_repository.dart`'s own doc comment.
library;

import '../../../api/api.dart';
import 'listing_editor_repository.dart';

class LiveListingEditorRepository implements ListingEditorRepository {
  const LiveListingEditorRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<Ad> getById(String id) => _api.ads.getById(id);

  @override
  Future<Ad> create(AdWriteInput input) => _api.agentAds.create(input);

  @override
  Future<Ad> update(String id, AdWriteInput input) =>
      _api.agentAds.update(id, input);

  @override
  Future<void> delete(String id) => _api.agentAds.delete(id);

  @override
  Future<AdPublishStatus> publishStatus(String adId) =>
      _api.publish.statusForAd(adId);

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() =>
      _api.publish.instagramAccounts();

  @override
  Future<PublishAttemptResponse> publishInstagram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    List<String>? igUserIds,
  }) => _api.publish.publishInstagram(
    adId: adId,
    caption: caption,
    imageUrls: imageUrls,
    igUserIds: igUserIds,
  );

  @override
  Future<PublishAttemptResponse> publishTelegram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    required List<String> chatIds,
  }) => _api.publish.publishTelegram(
    adId: adId,
    caption: caption,
    imageUrls: imageUrls,
    chatIds: chatIds,
  );
}
