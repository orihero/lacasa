/// `/api/publish/*` — behind `publish-channels-sheet` (§28), `publish-status`
/// (§29), `connected-accounts`' Instagram half (§21), and the channel
/// badges on `my-listings` (§25). Every route requires auth; every route
/// except [statusForAd]/[statusForAds] additionally 403s
/// `code: forbidden` for `role: "user"` (`actorFields` returns `null` for
/// that role — see the API contract survey).
///
/// **No multi-channel "publish to N at once" endpoint exists** — each
/// channel is a separate call ([publishInstagram]/[publishTelegram]/
/// [reportYoutube]), and there is no retry endpoint for a [PublishStatus.failed]
/// row either. `apps/console` permanently disables both affordances for
/// exactly this reason (see the web/console survey) — a Work screen that
/// wants a "Publish to N channels" button has to fan out these calls
/// itself and has nothing to offer a "Retry" button that calls.
library;

import '../api_client.dart';
import '../models/connected_account.dart';
import '../models/enums.dart';
import '../models/publish.dart';

class PublishResource {
  final ApiClient _client;

  const PublishResource(this._client);

  /// `POST /publish/instagram` — direct server-side publish via the
  /// agent's stored token(s), no browser extension involved. [imageUrls]
  /// must be 1–20 already-uploaded URLs (see `UploadsResource.presign`).
  /// [igUserIds] narrows which connected account(s) to post to; omit to
  /// post to all of them. Throws [ApiErrorException] `code:
  /// noConnectedAccounts` (400) if the agent has zero matching
  /// `AgentIgToken` rows.
  Future<PublishAttemptResponse> publishInstagram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    List<String>? igUserIds,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/publish/instagram',
      body: {
        'adId': adId,
        'caption': caption,
        'imageUrls': imageUrls,
        'igUserIds': ?igUserIds,
      },
    );
    return PublishAttemptResponse.fromJson(
      json as Map<String, dynamic>,
      targetKey: 'igUserId',
      idKey: 'mediaId',
    );
  }

  /// `GET /publish/instagram/accounts` — the connected Instagram accounts
  /// list `connected-accounts` (§21) renders as cards.
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async {
    final json = await _client.request(
      method: 'GET',
      path: '/publish/instagram/accounts',
    );
    final accounts = (json as Map<String, dynamic>)['accounts'] as List<dynamic>?;
    return (accounts ?? const [])
        .map((e) => ConnectedInstagramAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /publish/instagram/consent` — no body. Returns the consent
  /// timestamp the server just recorded.
  Future<DateTime?> instagramConsent() async {
    final json = await _client.request(
      method: 'POST',
      path: '/publish/instagram/consent',
    );
    final value = (json as Map<String, dynamic>)['igAssistConsentAt'] as String?;
    return value == null ? null : DateTime.tryParse(value);
  }

  /// `POST /publish/telegram`. [chatIds] is filtered server-side against
  /// the caller's/their agent's `User.tgChatIds` — passing an id the agent
  /// never connected just gets silently dropped from the attempt, not
  /// rejected. Throws `code: noConnectedAccounts` (400) if none match, or
  /// `code: tgUnconfigured`... actually the wire code is `tg_unconfigured`
  /// which this client's [ApiErrorCode] doesn't have a dedicated member for
  /// yet (falls through to [ApiErrorCode.unknown]) — 503 when the server
  /// has no `TG_BOT_TOKEN` configured at all. A [Publication] row with
  /// `status: FAILED` is still recorded before that 503 is thrown, so
  /// `publish-status` will show the attempt even though this call itself
  /// threw.
  Future<PublishAttemptResponse> publishTelegram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    required List<String> chatIds,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/publish/telegram',
      body: {
        'adId': adId,
        'caption': caption,
        'imageUrls': imageUrls,
        'chatIds': chatIds,
      },
    );
    return PublishAttemptResponse.fromJson(
      json as Map<String, dynamic>,
      targetKey: 'chatId',
      idKey: 'messageId',
    );
  }

  /// `POST /publish/youtube` — report-back only, there is no server-side
  /// upload. [status] must be [PublishStatus.published] or
  /// [PublishStatus.failed]; [externalId] (an 11-char YouTube video id) is
  /// required when [status] is [PublishStatus.published] (400 `validation`
  /// otherwise — this client does not pre-validate that pairing).
  Future<Publication> reportYoutube({
    required String adId,
    required PublishStatus status,
    String? externalId,
    String? externalUrl,
    String? errorMessage,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/publish/youtube',
      body: {
        'adId': adId,
        'status': status.wire,
        'externalId': ?externalId,
        'externalUrl': ?externalUrl,
        'errorMessage': ?errorMessage,
      },
    );
    return Publication.fromJson(
      (json as Map<String, dynamic>)['publication'] as Map<String, dynamic>,
    );
  }

  /// `GET /publish/ads/:adId/status` — the `publish-status` screen's one
  /// data source. No ownership check server-side beyond being signed in at
  /// all (any authenticated role, including `"user"`, can read any ad's
  /// status). Always exactly 5 [ChannelStatus] rows, [Channel.allChannels]
  /// order, PENDING-synthesized for any channel never attempted.
  Future<AdPublishStatus> statusForAd(String adId) async {
    final json = await _client.request(
      method: 'GET',
      path: '/publish/ads/$adId/status',
    );
    return AdPublishStatus.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /publish/status?adIds=id1,id2,...` (max 200 ids) — the lean
  /// batched form `my-listings` (§25) needs for its channel badges. Returns
  /// `{ adId: [ChannelStatus, ...] }`; unlike [statusForAd], **this does
  /// NOT synthesize a PENDING row for an untouched channel** — an ad with
  /// zero publish attempts maps to an empty list, and each [ChannelStatus]
  /// here only ever has [ChannelStatus.channel]/[ChannelStatus.status] set
  /// (externalUrl/externalId/lastAttemptAt/errorMessage are always `null`
  /// — this endpoint's response shape genuinely omits them, not a decode
  /// gap in this client).
  Future<Map<String, List<ChannelStatus>>> statusForAds(
    List<String> adIds,
  ) async {
    final json = await _client.request(
      method: 'GET',
      path: '/publish/status',
      query: {'adIds': adIds.join(',')},
    );
    return (json as Map<String, dynamic>).map(
      (adId, rows) => MapEntry(
        adId,
        (rows as List<dynamic>)
            .map((e) => ChannelStatus.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
  }
}
