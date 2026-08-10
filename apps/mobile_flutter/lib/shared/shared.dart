/// Barrel for `lib/shared/` — the cross-feature kit every screen (Home
/// plus the five buyer-facing screens it precedes: `listing-search`,
/// `filter-sheet`, `map-view`, `listing-detail`, `photo-gallery`, and
/// beyond) builds against instead of each reinventing its own listing
/// card, price pill, favourite control, or formatter.
///
/// Import this one file for the common case:
/// ```dart
/// import 'package:lacasa_mobile/shared/shared.dart';
/// ```
/// Individual files under `widgets/`, `formatters/`, and `state/` remain
/// directly importable too, for a caller that wants only one piece.
library;

export 'fixtures/work_seed_data.dart';
export 'formatters/formatters.dart';
export 'state/favourite_ad_ids_provider.dart';
export 'state/favourite_ad_ids_repository.dart';
export 'widgets/agent_avatar.dart';
export 'widgets/choice_chip_group.dart';
export 'widgets/compact_listing_card.dart';
export 'widgets/crm_list_tile.dart';
export 'widgets/delete_confirm.dart';
export 'widgets/discard_changes_confirm.dart';
export 'widgets/favourite_button.dart';
export 'widgets/field_label.dart';
export 'widgets/full_listing_card.dart';
export 'widgets/labelled_form_field.dart';
export 'widgets/list_row.dart';
export 'widgets/list_states.dart';
export 'widgets/listing_photo.dart';
export 'widgets/media_upload_unavailable_notice.dart';
export 'widgets/nav_row.dart';
export 'widgets/price_pill.dart';
export 'widgets/section_header.dart';
export 'widgets/sign_out_confirm.dart';
export 'widgets/status_pill.dart';
export 'widgets/toast.dart';
export 'widgets/visibility_toggle.dart';
