/// The per-row publish-channel badges on `my-listings` (UX audit §9.2).
///
/// **Why a listing row has to carry this.** Publishing to Instagram or
/// Telegram is an irreversible public post, and its entire feedback today
/// is a 2.5-second toast before `publish-channels-sheet` closes. After that
/// toast, "did this ad actually go out, and where?" is answerable only two
/// levels deep: tap the row's edit icon, scroll past the whole listing
/// form, tap the "Publish Status" link. A FAILED channel therefore stays
/// invisible indefinitely — nothing on the list, nothing on the row, no
/// notification. The state of an irreversible public action belongs on the
/// object it was performed on.
///
/// **Batched, not per row.** These badges are fed by
/// [myListingsPublishStatusesProvider], which makes exactly one
/// `GET /publish/status?adIds=…` call for every ad on screen — the route
/// whose own doc comment names it "the lean batched form `my-listings`
/// (§25) needs for its channel badges" ([PublishResource.statusForAds]),
/// and which had zero call sites before this. Reusing `publish-status`'s
/// singular [PublishResource.statusForAd] instead would mean one request
/// per visible row, ten on first paint and growing with every `loadMore`.
///
/// **Which channels get a badge.** [Channel.telegram] and
/// [Channel.instagram] always, because those are the two the agent can
/// actually publish to from this app ([Channel.hasServerPublishPath]) and
/// "never attempted" is a real answer they need; plus any other channel the
/// server reports a row for, so a YouTube/OLX publication done
/// elsewhere still shows up here. Rendering all four unconditionally was
/// rejected: two permanently grey pills per row is noise that makes the
/// two that mean something harder to find. Order follows
/// [Channel.allChannels] so it matches the row order on `publish-status`,
/// which is where a tap lands.
///
/// **Absence means two different things, and only one of them is
/// renderable.** The batch route deliberately does *not* synthesize a
/// PENDING row for an untouched channel (unlike the singular route), so an
/// ad with no attempts maps to an empty list — that is the "never
/// attempted" tint. But an ad missing from the map entirely, or a batch
/// request that failed, is *unknown*, not "not published", and this widget
/// renders nothing at all for it rather than paint a grey badge that
/// asserts something the app does not know. A failed batch therefore costs
/// the badges and nothing else (build contract §6).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
// `channelLabel` lives beside the Publish section rather than in
// `shared/`, and its own doc comment is explicit that every publish surface
// reuses it "so all three never drift on wording". Importing the file
// directly (it is not on `listing_editor`'s barrel, which exports only the
// four screen entry points) is the smaller evil: authoring a fourth
// private copy of the same ten-arm switch is exactly the drift that
// function exists to prevent.
import '../../listing_editor/widgets/form/publish_section.dart';

class MyListingChannelStrip extends StatelessWidget {
  const MyListingChannelStrip({
    super.key,
    required this.adId,
    required this.statuses,
    required this.onTap,
  });

  final String adId;

  /// This ad's rows from [myListingsPublishStatusesProvider]. **`null` is
  /// "unknown"** — the batch is still in flight, failed, or did not name
  /// this ad — and renders nothing; an **empty list** is "the server has no
  /// publish attempt for this ad", which does render, as two
  /// never-attempted badges. See this file's doc comment.
  final List<ChannelStatus>? statuses;

  /// Opens `publish-status` for [adId] — the screen that carries what a
  /// tint cannot: the error message on a FAILED row, the external URL on a
  /// PUBLISHED one, and the Retry button.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rows = statuses;
    if (rows == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final byChannel = {for (final row in rows) row.channel: row.status};
    // Driven by [Channel.allChannels], which is the server's own response
    // order and deliberately excludes both the four display-only channels
    // and [Channel.unknown]. A row that decoded to `unknown` (a channel
    // this build's `Channel.fromWire` does not recognize yet) is therefore
    // dropped rather than rendered as a badge reading "Unknown" — the badge
    // would name nothing an agent could act on, and `publish-status`, one
    // tap away, shows the raw wire value.
    final channels = [
      for (final channel in Channel.allChannels)
        if (channel.hasServerPublishPath || byChannel.containsKey(channel))
          channel,
    ];
    // Unreachable while Telegram and Instagram both have a server publish
    // path, and kept anyway: [TapTarget] requires a non-empty semantics
    // label, so if that ever stops being true this degrades to no strip
    // instead of an unlabelled 48dp button in the middle of every row.
    if (channels.isEmpty) return const SizedBox.shrink();

    final descriptions = [
      for (final channel in channels)
        l10n.myListingsChannelBadgeSemanticsLabel(
          channelLabel(l10n, channel),
          _statusLabel(l10n, byChannel[channel]),
        ),
    ];

    return TapTarget(
      // One target for the whole strip, not one per badge. Every badge
      // leads to the same destination (`publish-status` shows all five
      // channels on one screen), so per-badge targets would be four 48dp
      // boxes doing one job — and [TapTarget] excludes its child's
      // semantics, so the per-badge labels would be lost either way. The
      // joined description is what a screen reader reads instead, and it
      // is strictly more useful than any single badge's: "Telegram —
      // Published, Instagram — Failed" is the whole answer in one utterance.
      semanticsLabel: descriptions.join(', '),
      onTap: onTap,
      // A [Wrap], not a [Row]: a `Row` hands its non-flex children an
      // unbounded main axis, so three badges beside a 52dp thumbnail and a
      // 48dp edit target on a 360dp screen overflow rather than shrink —
      // and shrinking is the wrong answer anyway, since an ellipsized
      // "Instag…" badge is worse than a second line. Same idiom the status
      // pill + spec line one row up already uses.
      child: Wrap(
        key: ValueKey('myListingChannels-$adId'),
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final channel in channels)
            StatusPill(
              key: ValueKey('myListingChannel-$adId-${channel.name}'),
              label: channelLabel(l10n, channel),
              tone: _tone(byChannel[channel]),
            ),
        ],
      ),
    );
  }
}

/// The tint a badge carries, from the same five-tone palette every other
/// status vocabulary in this build reduces to ([StatusPill]).
///
/// `null` — no row for this channel — is [StatusTone.mute], the same grey
/// "Sold" and "Could Not Connect" use: nothing has happened here.
/// [PublishStatus.draftedAwaitingReview] shares [PublishStatus.pending]'s
/// amber because from this row's altitude both mean the same thing, "in
/// flight, not landed"; the distinction between them (a human is
/// mid-review) is a `publish-status` concern and is a tap away.
StatusTone _tone(PublishStatus? status) => switch (status) {
  null => StatusTone.mute,
  PublishStatus.published => StatusTone.ok,
  PublishStatus.failed => StatusTone.err,
  PublishStatus.pending ||
  PublishStatus.draftedAwaitingReview => StatusTone.warn,
  // A status this build's [PublishStatus.fromWire] does not recognize yet.
  // Grey rather than a guess — the same forward-compatibility default every
  // `unknown` arm in this codebase takes.
  PublishStatus.unknown => StatusTone.mute,
};

/// The word a screen reader gets for a badge's tint.
///
/// These are **not** `publish-status`' own pills. Those deliberately print
/// the raw wire enums (`PENDING`/`PUBLISHED`/`FAILED`) as a documented
/// passthrough — see `sharedPublishStatus*Label`'s `@description` blocks —
/// which is defensible on a screen dedicated to publish plumbing and is not
/// on a listings table an agent reads at a glance. Do not conflate the two
/// key sets.
String _statusLabel(AppLocalizations l10n, PublishStatus? status) =>
    switch (status) {
      null => l10n.myListingsChannelNotPublishedLabel,
      PublishStatus.published => l10n.myListingsChannelPublishedLabel,
      PublishStatus.failed => l10n.myListingsChannelFailedLabel,
      PublishStatus.pending ||
      PublishStatus.draftedAwaitingReview =>
        l10n.myListingsChannelPendingLabel,
      PublishStatus.unknown => l10n.myListingsChannelNotPublishedLabel,
    };
