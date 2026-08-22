/// The per-channel publish buttons shared by `create-listing`'s Step 4
/// (§26: "buttons per connected channel (Instagram/Telegram/YouTube); OLX
/// shown disabled 'Not available on mobile'") and `edit-listing`'s Publish
/// section (§27: "per-channel buttons → `publish-channels-sheet`; link
/// 'Publish Status' → `publish-status`").
///
/// **Ruling 7.3**: every button that opens `publish-channels-sheet` opens
/// the exact same sheet regardless of which was tapped — there is no
/// per-channel-scoped variant, since [showPublishChannelsSheet]'s signature
/// takes only the [Ad], not a channel filter (`WORK_TAB_CONTRACT.md` §3.2).
/// YouTube is rendered visibly-disabled rather than as a working button —
/// the only server call for it is a report-back for an upload this app has
/// no mechanism to perform (`PublishResource.reportYoutube`'s own doc
/// comment), so a working "Publish to YouTube" button would lie about what
/// happens next.
///
/// **Ruling 7.13 — the four display-only channels.** Threads, Facebook
/// Marketplace, X and LinkedIn now each get a row here too, in exactly the
/// visibly-disabled treatment ruling 7.10 gave YouTube: a real brand tile
/// and a real localized name, dimmed, lock instead of caret, and a hint
/// line stating the honest per-channel reason nothing happens
/// ([channelUnavailableHint]). Facebook Marketplace used to be omitted from
/// this file outright, "per §5's own instruction (no compliant automation
/// path on any platform)" — that instruction has not changed and is now
/// *shown* rather than acted on silently: §5's reason is precisely what its
/// hint line says. A named-but-disabled row answers "where is Facebook
/// Marketplace?" where an absent row left the user to guess.
///
/// The row list comes from [Channel.publishSurfaceChannels], **not**
/// [Channel.allChannels] — the latter is the server's
/// `GET /publish/ads/:adId/status` response contract and driving UI off it
/// would grow a permanently-PENDING status row per app-only channel. See
/// that constant's doc comment for the full boundary.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../api/api.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../navigation/route_paths.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import '../channel_tile.dart';
import '../publish_channels_sheet.dart';

/// SCREENS.md §5's fixed OLX hint, reused so `publish_section.dart`,
/// `publish_channels_sheet.dart` and `publish_status_screen.dart` never
/// drift on the exact sentence. Was a top-level `const String` before
/// localization; now a function of [AppLocalizations] since the string can
/// no longer be a compile-time constant.
String olxUnavailableHint(AppLocalizations l10n) =>
    l10n.listingEditorOlxUnavailableHint;

/// Every [Channel] display name — all 10 members, wire and display-only
/// alike — reused across the Publish section, publish-channels-sheet and
/// publish-status so all three never drift on wording. A pure function of
/// [AppLocalizations] (see `lib/l10n/README.md`'s "passing AppLocalizations
/// into a pure function" guidance for a non-widget file needing localized
/// text).
///
/// The four display-only channels are named here for the same reason they
/// have rows at all: a disabled row still has to say *which* channel it is.
/// The label alone never implies the channel works — [channelUnavailableHint]
/// is what each of those rows prints underneath it.
String channelLabel(AppLocalizations l10n, Channel channel) => switch (channel) {
  Channel.telegram => l10n.listingEditorChannelTelegramLabel,
  Channel.instagram => l10n.listingEditorChannelInstagramLabel,
  Channel.youtube => l10n.listingEditorChannelYoutubeLabel,
  Channel.olx => l10n.listingEditorChannelOlxLabel,
  Channel.threads => l10n.listingEditorChannelThreadsLabel,
  Channel.facebookMarketplace =>
    l10n.listingEditorChannelFacebookMarketplaceLabel,
  Channel.x => l10n.listingEditorChannelXLabel,
  Channel.linkedin => l10n.listingEditorChannelLinkedinLabel,
  Channel.unknown => l10n.listingEditorChannelUnknownLabel,
};

/// The one-line "why is this row inert?" sentence a publish surface prints
/// under a channel's name, or `null` for a channel that needs no such line.
///
/// `null` is the *enabled* answer for [Channel.telegram]/[Channel.instagram]
/// (a live button explains itself), and the *not-a-publish-surface* answer
/// for [Channel.unknown] (a decode fallback, never rendered as a row). Callers
/// therefore read a `null` as "print no hint", never as "no reason known".
///
/// Shared by all three surfaces that draw a disabled channel row — this
/// section, `create-listing`'s Step 4 and `publish-channels-sheet` — so the
/// same channel never carries two differently-worded excuses. The
/// [Channel.olx] arm deliberately delegates to [olxUnavailableHint] rather
/// than reading the ARB key directly, so that function's "never drift on the
/// exact sentence" guarantee stays the single source for OLX.
///
/// Each of the four display-only channels (ruling 7.13) has its own
/// client-authored reason, not a shared "not available" — the reasons are
/// genuinely different (a missing Instagram-linked profile, a policy that
/// forbids automation outright, an unpurchased API tier, absent credentials),
/// and flattening them would tell the user less than the app knows.
String? channelUnavailableHint(AppLocalizations l10n, Channel channel) =>
    switch (channel) {
      Channel.telegram || Channel.instagram => null,
      Channel.unknown => null,
      Channel.youtube => l10n.listingEditorYoutubeUnavailableHint,
      Channel.olx => olxUnavailableHint(l10n),
      Channel.threads => l10n.listingEditorThreadsUnavailableHint,
      Channel.facebookMarketplace =>
        l10n.listingEditorFacebookMarketplaceUnavailableHint,
      Channel.x => l10n.listingEditorXUnavailableHint,
      Channel.linkedin => l10n.listingEditorLinkedinUnavailableHint,
    };

class PublishSection extends StatelessWidget {
  const PublishSection({
    super.key,
    required this.ad,
    this.showPublishStatusLink = false,
  });

  final Ad ad;

  /// `true` for `edit-listing` (§27's "link 'Publish Status'"); `false` for
  /// `create-listing`'s Step 4, which has no ad-in-hand publish history to
  /// show yet (the ad the wizard is building doesn't exist server-side
  /// until Create is tapped).
  final bool showPublishStatusLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l10n.listingEditorPublishSectionLabel),
        // One row per [Channel.publishSurfaceChannels] entry, in that list's
        // order (Instagram, Telegram, YouTube, OLX, then the four
        // display-only channels). This replaced four hand-written rows;
        // the generated keys reproduce the previous four exactly
        // (`publish-channel-instagram` / `-telegram` / `-youtube` / `-olx`,
        // since `Channel.name` is the enum member name), so every shipped
        // test keeps matching, and the new rows follow the same shape
        // (`publish-channel-threads` / `-facebookMarketplace` / `-x` /
        // `-linkedin`).
        //
        // Enabled-ness is [Channel.hasServerPublishPath] — a documented fact
        // about which channels `PublishResource` can actually call — rather
        // than eight literal `enabled:` flags that would drift from the API
        // the first time one of them changed. `onTap` is attached only on the
        // enabled rows, so a disabled row is inert in behaviour and not just
        // in appearance.
        for (final channel in Channel.publishSurfaceChannels) ...[
          if (channel != Channel.publishSurfaceChannels.first)
            const SizedBox(height: kChannelRowGap),
          _ChannelButton(
            key: ValueKey('publish-channel-${channel.name}'),
            channel: channel,
            label: channelLabel(l10n, channel),
            enabled: channel.hasServerPublishPath,
            // Ruling 7.3: every enabled button opens the *same* sheet —
            // `showPublishChannelsSheet` takes no channel filter.
            onTap: channel.hasServerPublishPath
                ? () => showPublishChannelsSheet(context, ad: ad)
                : null,
            hint: channelUnavailableHint(l10n, channel),
          ),
        ],
        if (showPublishStatusLink) ...[
          const SizedBox(height: AppSpacing.base),
          GestureDetector(
            key: const ValueKey('publish-status-link'),
            // `push`, never `go`: this link is only ever shown from
            // `edit-listing`, whose form may be dirty. `go` replaces the
            // branch stack, which disposed that form outright — and
            // `EditListingScreen`'s discard guard is a `PopScope`, i.e. a
            // *pop*-only hook, so a replace slipped past it with no
            // "Discard changes?" prompt and no route back to the ad being
            // edited. Pushing keeps the editor mounted underneath, so Back
            // from `publish-status` returns to it with every unsaved edit
            // still in the fields.
            onTap: () => context.push(
              RoutePaths.workPublishStatus.replaceFirst(':id', ad.id),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.listingEditorPublishStatusLinkLabel,
                  style: type.rowTitle.copyWith(color: AppAccent.color),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppAccent.color,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One `.lrow glf` publish row — the same shape `create-listing`'s Step 4
/// draws (`create_listing_screen.dart`'s `_PublishChannelRow`): a
/// [ChannelIconTile] brand tile, the channel name over its optional hint,
/// and a trailing `.lrow__go` caret on the rows that actually open the
/// sheet. A disabled row — YouTube, OLX, and the four display-only channels
/// of ruling 7.13 — is dimmed like the mockup's `.is-off`, drops the caret
/// and shows a lock instead: there is nothing to navigate to.
class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    super.key,
    required this.channel,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.hint,
  });

  final Channel channel;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        // `.lrow{display:flex;align-items:center;gap:12px;
        // border-radius:20px;padding:13px 15px}`
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.card),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              ChannelIconTile(channel: channel),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    // `.lrow__s{margin-top:2px}`
                    if (hint case final h?) ...[
                      const SizedBox(height: 2),
                      Text(
                        h,
                        style: type.specMeta.copyWith(color: colors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (enabled)
                Icon(Icons.chevron_right_rounded, size: 18, color: colors.faint)
              else
                Icon(Icons.lock_outline_rounded, size: 15, color: colors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
