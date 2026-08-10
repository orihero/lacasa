/// Data-access seam for the whole `listing_editor` feature directory —
/// `create-listing` (§26), `edit-listing` (§27), `publish-channels-sheet`
/// (§28) and `publish-status` (§29). One repository for all four screens,
/// per `WORK_TAB_CONTRACT.md`'s conventions digest: "if two of your own
/// screens share one repository, one mode switch for the whole feature dir
/// is correct" — all four are pieces of the same ad-authoring/publishing
/// flow (create/edit write an [Ad]; publish-channels-sheet and
/// publish-status both read/act on that same ad's publish state), so they
/// share one `*_mode.dart` switch rather than each screen inventing its own.
library;

import '../../../api/api.dart';

abstract class ListingEditorRepository {
  /// `edit-listing`'s prefill fetch (`GET /ads/:id`, the public/read-only
  /// endpoint — works regardless of caller role, matching
  /// `listing_detail_repository.dart`'s own use of it). Throws
  /// [ApiErrorException] with `code: notFound` for an id that doesn't
  /// resolve.
  Future<Ad> getById(String id);

  /// `POST /ads` (or the fixture equivalent). See [AdWriteInput]'s own doc
  /// comment for the omit-vs-clear field convention every write on this
  /// seam follows.
  Future<Ad> create(AdWriteInput input);

  /// `PATCH /ads/:id`.
  Future<Ad> update(String id, AdWriteInput input);

  /// `DELETE /ads/:id`, AGENT only server-side — the caller (not this seam)
  /// is responsible for hiding/disabling Delete for a coworker session, per
  /// `AgentAdsResource.delete`'s own doc comment.
  Future<void> delete(String id);

  /// `publish-status`'s (§29) one data source — always exactly 5
  /// [ChannelStatus] rows, [Channel.allChannels] order, PENDING-synthesized
  /// for any channel never attempted.
  Future<AdPublishStatus> publishStatus(String adId);

  /// `publish-channels-sheet`'s (§28) Instagram half — which connected
  /// accounts to list as checkboxes, and whether to show the "no account
  /// connected" hint at all.
  Future<List<ConnectedInstagramAccount>> instagramAccounts();

  Future<PublishAttemptResponse> publishInstagram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    List<String>? igUserIds,
  });

  Future<PublishAttemptResponse> publishTelegram({
    required String adId,
    required String caption,
    required List<String> imageUrls,
    required List<String> chatIds,
  });
}
