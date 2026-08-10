/// A [ListingEditorRepository] a test can steer end to end — hand it the ad
/// `edit-listing` should prefill from, make any call throw, or just count
/// calls to prove a submit/delete/publish actually happened with the right
/// arguments. Deliberately not backed by `work_seed_data.dart` — a test
/// that asserts "Save sends exactly these fields" must own the starting
/// [Ad], not depend on which fixture happens to have which shape this
/// month (same reasoning as `fake_listing_detail_repository.dart`).
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/data/listing_editor_repository.dart';

class FakeListingEditorRepository implements ListingEditorRepository {
  FakeListingEditorRepository({this.ad, this.hold});

  Ad? ad;

  /// When set, [create]/[update] await this before resolving — lets a test
  /// observe the transient "Creating"/"Updating" pending toast (which a
  /// bare `async` method with no real `await` never leaves on screen long
  /// enough to assert against; see `fake_coworkers_repository.dart`'s
  /// identical field for the same reasoning).
  final Completer<void>? hold;

  Object? getByIdError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Object? publishStatusError;
  Object? publishInstagramError;
  Object? publishTelegramError;

  int publishStatusCalls = 0;

  int getByIdCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int publishInstagramCalls = 0;
  int publishTelegramCalls = 0;

  AdWriteInput? lastCreateInput;
  String? lastUpdateId;
  AdWriteInput? lastUpdateInput;
  String? lastDeleteId;

  List<String>? lastPublishInstagramIgUserIds;
  List<String>? lastPublishTelegramChatIds;

  List<ConnectedInstagramAccount> instagramAccountsResult = const [];
  AdPublishStatus? publishStatusResult;

  /// `[ok: true]` per call by default — a test that wants a failed
  /// per-target result overrides this before publishing.
  bool instagramResultsOk = true;
  bool telegramResultsOk = true;

  @override
  Future<Ad> getById(String id) async {
    getByIdCalls++;
    if (getByIdError != null) return Future.error(getByIdError!);
    final current = ad;
    if (current == null) {
      return Future.error(
        ApiErrorException(
          body: const ApiErrorBody(code: ApiErrorCode.notFound, message: 'Listing not found'),
          statusCode: 404,
        ),
      );
    }
    return current;
  }

  @override
  Future<Ad> create(AdWriteInput input) async {
    createCalls++;
    lastCreateInput = input;
    if (hold != null) await hold!.future;
    if (createError != null) return Future.error(createError!);
    return ad ?? _blankAd();
  }

  @override
  Future<Ad> update(String id, AdWriteInput input) async {
    updateCalls++;
    lastUpdateId = id;
    lastUpdateInput = input;
    if (hold != null) await hold!.future;
    if (updateError != null) return Future.error(updateError!);
    return ad ?? _blankAd();
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    lastDeleteId = id;
    if (deleteError != null) return Future.error(deleteError!);
  }

  @override
  Future<AdPublishStatus> publishStatus(String adId) async {
    publishStatusCalls++;
    if (publishStatusError != null) return Future.error(publishStatusError!);
    return publishStatusResult ??
        AdPublishStatus(
          adId: adId,
          channels: [
            for (final channel in Channel.allChannels)
              ChannelStatus(
                channel: channel,
                status: PublishStatus.pending,
                externalUrl: null,
                externalId: null,
                lastAttemptAt: null,
                errorMessage: null,
              ),
          ],
        );
  }

  @override
  Future<List<ConnectedInstagramAccount>> instagramAccounts() async =>
      instagramAccountsResult;

  @override
  Future<PublishAttemptResponse> publishInstagram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    List<String>? igUserIds,
  }) async {
    publishInstagramCalls++;
    lastPublishInstagramIgUserIds = igUserIds;
    if (publishInstagramError != null) return Future.error(publishInstagramError!);
    final targets = igUserIds ?? const <String>[];
    return PublishAttemptResponse(
      publication: _publication(adId, Channel.instagram),
      results: [
        for (final t in targets)
          PublishAttemptResult(
            target: t,
            ok: instagramResultsOk,
            mediaOrMessageId: instagramResultsOk ? 'media-$t' : null,
            error: instagramResultsOk ? null : 'boom',
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
    publishTelegramCalls++;
    lastPublishTelegramChatIds = chatIds;
    if (publishTelegramError != null) return Future.error(publishTelegramError!);
    return PublishAttemptResponse(
      publication: _publication(adId, Channel.telegram),
      results: [
        for (final t in chatIds)
          PublishAttemptResult(
            target: t,
            ok: telegramResultsOk,
            mediaOrMessageId: telegramResultsOk ? 'message-$t' : null,
            error: telegramResultsOk ? null : 'boom',
          ),
      ],
    );
  }

  Publication _publication(String adId, Channel channel) => Publication(
    id: 'pub-$adId-${channel.wire}',
    adId: adId,
    channel: channel,
    status: PublishStatus.published,
    externalId: null,
    externalUrl: null,
    attempts: 1,
    lastAttemptAt: DateTime.utc(2026, 8, 10),
    publishedAt: DateTime.utc(2026, 8, 10),
    errorMessage: null,
  );

  Ad _blankAd() => testAd();
}

/// A minimal, fully-populated [Ad] a test can override fields on via
/// named args — every required field gets an inert default so a test only
/// has to name the fields it actually cares about.
Ad testAd({
  String id = 'ad-9001',
  String title = 'Bright 3-room apartment',
  String city = 'Tashkent',
  String district = 'Chilonzor',
  String? address = '12 Bunyodkor avenue',
  String? reference = 'Near the park',
  String type = 'residential',
  String category = 'sale',
  String? repairment,
  int? rooms = 3,
  double? area = 65,
  int? storey = 4,
  int? floors = 9,
  String? furniture,
  String? hashtags,
  double price = 78000,
  String priceType = 'uzs',
  String stage = '1',
  String? description = 'A bright apartment.',
  List<String> nearPlacesList = const [],
  Object? optionList = const [],
  bool active = true,
  double? lat,
  double? lng,
  String? tour3dLink,
  String agentId = 'agent-javlon',
  String coworkerId = '',
  List<String> photos = const [],
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': city,
    'district': district,
    'address': address,
    'reference': reference,
    'type': type,
    'category': category,
    'repairment': repairment,
    'rooms': rooms,
    'area': area,
    'storey': storey,
    'floors': floors,
    'furniture': furniture,
    'hashtags': hashtags,
    'price': price,
    'priceType': priceType,
    'stage': stage,
    'description': description,
    'nearPlacesList': nearPlacesList,
    'optionList': optionList,
    'active': active,
    'lat': lat,
    'lng': lng,
    'tour3dLink': tour3dLink,
    'agentId': agentId,
    'coworkerId': coworkerId,
    'photos': photos,
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}
