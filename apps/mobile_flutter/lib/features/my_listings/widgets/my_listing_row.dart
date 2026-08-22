/// One row of `my-listings`, shaped after the mockup's `.trow glf`
/// (Direction E, screen 25) rather than the generic [CrmListTile]:
/// SCREENS.md §25's row anatomy ("thumbnail; #{id}; Created At; City;
/// Status pill; Author; {rooms} room; {area} m²; edit icon") is a *set* of
/// facts, and the mockup lays that set out as a three-line body the shared
/// tile's `String title` / `String? subtitle` slots cannot express:
///
/// - **`.trow__ph`** → the 52×52 thumbnail ([ListingPhoto]).
/// - **`.trow__id`** → the id badge eyebrow ([Formatters.adIdBadge]),
///   9.5/600 in `faint`, tabular.
/// - **`.trow__t`** → `ad.title`, the row's dominant line, clamped to two
///   lines exactly like the mockup's `clamp2`.
/// - **`.trow__m` ×2** → the status pill ([AdStagePill]) inline with
///   "City · {rooms} · {area}", then "Created At · Author" beneath it.
///   Two lines, not one `·`-joined string, so nothing truncates at phone
///   width (see this file's "layout holds at real phone widths" test
///   group).
/// - **`.trow__act`** → the edit icon, alone in the trailing slot, in its
///   own 34px `sunk` circle — painted at 34, *hit* at 48 via [TapTarget]
///   (UX audit §10.2: the mockup's sizes came from a CSS prototype nobody
///   touched with a thumb, and 34dp is under both platform floors). The
///   circle is unchanged; only the transparent box around it grew.
///
/// One addition to §25's row anatomy, from UX audit §9.2:
/// [MyListingChannelStrip], the per-channel publish badges, sits between
/// the spec line and the origin line. See that file's doc comment for why
/// an irreversible public post cannot have its only record two levels deep
/// inside the edit form.
///
/// [CrmListTile] is deliberately **not** reused here: its body is two
/// `String` slots rendered as single-line ellipsized [Text]s, and widening
/// it to take arbitrary body widgets would erase the very constraint that
/// makes it a shared row shape for `leads-list`/`coworkers-list`. The glass
/// surface, radius, and leading-clip idiom below still mirror it exactly.
///
/// **Tap regions**: SCREENS.md §25 says "Row tap (outside thumbnail/edit)
/// → `listing-detail`". The row's own [GestureDetector] covers the whole
/// row including the thumbnail; only the edit icon's nested detector wins
/// the gesture arena and opens `edit-listing` instead. Flagged as a minor,
/// deliberate deviation from the mockup's literal tap-region split.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'my_listing_channel_strip.dart';

class MyListingRow extends StatelessWidget {
  const MyListingRow({
    super.key,
    required this.ad,
    required this.authorName,
    required this.channelStatuses,
    required this.onTap,
    required this.onEdit,
    required this.onTapChannels,
  });

  final Ad ad;

  /// Already resolved by the caller (`resolveAdAuthorName`) — an em dash
  /// when unknown, never blank. See that function's own doc comment.
  final String authorName;

  /// This ad's rows from `myListingsPublishStatusesProvider`, or `null`
  /// while the batch is unresolved — [MyListingChannelStrip] documents the
  /// difference between that and an empty list, which is load-bearing.
  final List<ChannelStatus>? channelStatuses;

  final VoidCallback onTap;
  final VoidCallback onEdit;

  /// Opens `publish-status` for this ad — see [MyListingChannelStrip].
  final VoidCallback onTapChannels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final idBadge = Formatters.adIdBadge(ad.id);
    final specLine = [
      ad.city,
      Formatters.rooms(ad.rooms),
      Formatters.area(ad.area),
    ].whereType<String>().join(' · ');
    // `.toLocal()` is not cosmetic here. `Ad.createdAt` is decoded by
    // `dateTimeFromWireTimestamp`, which builds its [DateTime] with
    // `isUtc: true`; [Formatters.date] reads `.day`/`.hour` straight off
    // whatever it is handed, so without this an ad created at 09:30 in
    // Tashkent printed "04:30" — and an ad created after 05:00 local
    // printed the *previous day's* date, which on a list sorted newest-
    // first reads as the row being out of order. Every other date call
    // site in this build already localizes (`kanban_card.dart`,
    // `agent_reviews_section.dart`, `lead_form_controls.dart`); this row
    // was the outlier.
    final originLine =
        '${Formatters.date(ad.createdAt.toLocal())} · $authorName';
    final metaStyle = type.specMeta.copyWith(color: colors.muted);

    return Semantics(
      button: true,
      label: '$idBadge, ${ad.title}, $specLine, $originLine',
      child: GestureDetector(
        key: ValueKey('myListingRow-${ad.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ListingPhoto(url: ad.photos.firstOrNull),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      idBadge,
                      style: LaCasaTypography.tabular(
                        type.caption,
                      ).copyWith(color: colors.faint, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      ad.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 7,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AdStagePill(stage: ad.stage),
                        Text(specLine, style: metaStyle),
                      ],
                    ),
                    MyListingChannelStrip(
                      adId: ad.id,
                      statuses: channelStatuses,
                      onTap: onTapChannels,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      originLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _EditButton(adId: ad.id, onTap: onEdit),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.adId, required this.onTap});

  final String adId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    // 34dp of paint, 48dp of hit box (UX audit §10.2). The circle is the
    // mockup's `.trow__act` and keeps its size exactly; [TapTarget] adds
    // transparent padding around it and claims the tap before the row's own
    // `onTap` — which matters here specifically, because a near-miss on the
    // edit icon used to open `listing-detail` instead, i.e. the wrong one
    // of two adjacent destinations rather than nothing at all.
    return TapTarget(
      key: ValueKey('myListingEdit-$adId'),
      semanticsLabel: AppLocalizations.of(
        context,
      ).myListingsEditButtonSemanticsLabel,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.sunk, shape: BoxShape.circle),
        child: Icon(Icons.edit_outlined, size: 16, color: colors.ink),
      ),
    );
  }
}
