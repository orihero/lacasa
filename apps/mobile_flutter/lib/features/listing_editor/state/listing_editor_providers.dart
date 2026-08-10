/// Riverpod state for `listing_editor`'s three read-only fetches —
/// `edit-listing`'s prefill, `publish-status`'s channel grid, and
/// `publish-channels-sheet`'s connected-Instagram-accounts list. Each is a
/// `FutureProvider.autoDispose.family` keyed by ad id (or a bare
/// `FutureProvider.autoDispose` for the accounts list, which isn't
/// per-ad) — "load, redo via `ref.invalidate`" is the only operation each
/// one needs, matching `listing_detail_providers.dart`'s identical
/// reasoning for why this isn't an [AsyncNotifier].
///
/// Mutations (create/update/delete/publish) are NOT providers — each
/// screen calls [listingEditorRepositoryProvider] directly inside its own
/// submit handler (wrapped in [LaCasaToast.run]), the same shape
/// `edit_profile_screen.dart` uses for its own single-shot submit. A
/// provider only earns its keep here for state more than one widget reads
/// or that needs a retry affordance wired to `ref.invalidate`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'listing_editor_repository_provider.dart';

/// `edit-listing`'s prefill fetch, keyed by ad id.
final editListingAdProvider = FutureProvider.autoDispose.family<Ad, String>((
  ref,
  adId,
) {
  return ref.read(listingEditorRepositoryProvider).getById(adId);
});

/// `publish-status`'s (§29) one data source, keyed by ad id.
final publishStatusProvider = FutureProvider.autoDispose.family<AdPublishStatus, String>((
  ref,
  adId,
) {
  return ref.read(listingEditorRepositoryProvider).publishStatus(adId);
});

/// `publish-channels-sheet`'s (§28) connected-Instagram-accounts list —
/// not ad-scoped, so a bare `.autoDispose` rather than a family.
final instagramAccountsProvider =
    FutureProvider.autoDispose<List<ConnectedInstagramAccount>>((ref) {
      return ref.read(listingEditorRepositoryProvider).instagramAccounts();
    });
