/// `AdPublication` and every `/api/publish/*` response shape — the truth
/// for `my-listings` channel badges, `publish-status`, and
/// `publish-channels-sheet`.
///
/// **Timestamp format note**, same caveat as `Lead.callbackDate`:
/// [Publication.lastAttemptAt]/[Publication.publishedAt] are raw JS `Date`s
/// serialized as plain ISO-8601 strings, NOT the `{seconds}` shape `Ad`/
/// `Lead`'s own `createdAt`/`updatedAt` use — decode with `DateTime.parse`-
/// style parsing here, never [dateTimeFromWireTimestamp].
library;

import 'enums.dart';

/// `serializePublication`'s full shape — one row of publish history for one
/// (ad, channel) pair.
class Publication {
  final String id;
  final String adId;
  final Channel channel;
  final PublishStatus status;
  final String? externalId;
  final String? externalUrl;
  final int attempts;
  final DateTime? lastAttemptAt;
  final DateTime? publishedAt;
  final String? errorMessage;

  const Publication({
    required this.id,
    required this.adId,
    required this.channel,
    required this.status,
    required this.externalId,
    required this.externalUrl,
    required this.attempts,
    required this.lastAttemptAt,
    required this.publishedAt,
    required this.errorMessage,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'] as String? ?? '',
      adId: json['adId'] as String? ?? '',
      channel: Channel.fromWire(json['channel'] as String?),
      status: PublishStatus.fromWire(json['status'] as String?),
      externalId: json['externalId'] as String?,
      externalUrl: json['externalUrl'] as String?,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastAttemptAt: _parseIso(json['lastAttemptAt']),
      publishedAt: _parseIso(json['publishedAt']),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// One row of `GET /publish/ads/:adId/status`'s `channels[]` — always
/// exactly 5 of these, in [Channel.allChannels] order, with a synthesized
/// `PENDING`/all-null row for any channel that's never been attempted (the
/// server does this synthesis, not this client — see the API contract
/// survey). The four display-only channels never appear here —
/// [Channel.fromWire] cannot produce one, and [Channel.allChannels] (which
/// is what the server's own `ALL_CHANNELS` mirrors) does not list one; see
/// [Channel.publishSurfaceChannels] for why the app-side list is separate.
class ChannelStatus {
  final Channel channel;
  final PublishStatus status;
  final String? externalUrl;
  final String? externalId;
  final DateTime? lastAttemptAt;
  final String? errorMessage;

  const ChannelStatus({
    required this.channel,
    required this.status,
    required this.externalUrl,
    required this.externalId,
    required this.lastAttemptAt,
    required this.errorMessage,
  });

  factory ChannelStatus.fromJson(Map<String, dynamic> json) {
    return ChannelStatus(
      channel: Channel.fromWire(json['channel'] as String?),
      status: PublishStatus.fromWire(json['status'] as String?),
      externalUrl: json['externalUrl'] as String?,
      externalId: json['externalId'] as String?,
      lastAttemptAt: _parseIso(json['lastAttemptAt']),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// `GET /publish/ads/:adId/status`'s whole response — the `publish-status`
/// screen's one data source.
class AdPublishStatus {
  final String adId;
  final List<ChannelStatus> channels;

  const AdPublishStatus({required this.adId, required this.channels});

  factory AdPublishStatus.fromJson(Map<String, dynamic> json) {
    return AdPublishStatus(
      adId: json['adId'] as String? ?? '',
      channels:
          (json['channels'] as List<dynamic>?)
              ?.map((e) => ChannelStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

/// One row of `POST /publish/instagram`'s `results[]` (per `igUserId`) or
/// `POST /publish/telegram`'s `results[]` (per `chatId`) — [target] holds
/// whichever id the request was keyed on; the two endpoints don't share a
/// field name for it (`igUserId` vs `chatId`), so this model normalizes
/// them into one name rather than have callers branch on which endpoint
/// they called to know which JSON key to read.
class PublishAttemptResult {
  final String target;
  final bool ok;
  final String? mediaOrMessageId;
  final String? error;

  const PublishAttemptResult({
    required this.target,
    required this.ok,
    required this.mediaOrMessageId,
    required this.error,
  });

  factory PublishAttemptResult.fromJson(
    Map<String, dynamic> json, {
    required String targetKey,
    required String idKey,
  }) {
    return PublishAttemptResult(
      target: json[targetKey] as String? ?? '',
      ok: json['ok'] as bool? ?? false,
      mediaOrMessageId: json[idKey] as String?,
      error: json['error'] as String?,
    );
  }
}

/// `POST /publish/instagram` / `POST /publish/telegram`'s shared response
/// envelope: the [Publication] row the attempt produced, plus one
/// [PublishAttemptResult] per target account/chat.
class PublishAttemptResponse {
  final Publication publication;
  final List<PublishAttemptResult> results;

  const PublishAttemptResponse({
    required this.publication,
    required this.results,
  });

  factory PublishAttemptResponse.fromJson(
    Map<String, dynamic> json, {
    required String targetKey,
    required String idKey,
  }) {
    return PublishAttemptResponse(
      publication: Publication.fromJson(
        json['publication'] as Map<String, dynamic>,
      ),
      results:
          (json['results'] as List<dynamic>?)
              ?.map(
                (e) => PublishAttemptResult.fromJson(
                  e as Map<String, dynamic>,
                  targetKey: targetKey,
                  idKey: idKey,
                ),
              )
              .toList() ??
          const [],
    );
  }
}

DateTime? _parseIso(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
