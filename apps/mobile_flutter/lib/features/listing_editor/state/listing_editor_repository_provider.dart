/// Picks [FixtureListingEditorRepository] or [LiveListingEditorRepository]
/// once, per `listing_editor_mode.dart`'s compile-time switch. Every other
/// provider in this feature reads through this one instead of constructing
/// a repository itself — the single point a widget test overrides.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../data/fixture_listing_editor_repository.dart';
import '../data/listing_editor_mode.dart';
import '../data/listing_editor_repository.dart';
import '../data/live_listing_editor_repository.dart';

final listingEditorRepositoryProvider = Provider<ListingEditorRepository>((
  ref,
) {
  if (useLiveListingEditorApi) {
    return LiveListingEditorRepository(LaCasaApi.create());
  }
  return FixtureListingEditorRepository();
});
