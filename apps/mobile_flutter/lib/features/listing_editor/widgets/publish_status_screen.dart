/// `publish-status` (SCREENS.md §29) — pushed from `edit-listing` (its own
/// "Publish Status" link) and `notifications` (a publish-kind row, per
/// `WORK_TAB_CONTRACT.md`'s routing table) at `RoutePaths.workPublishStatus`
/// (`:id` → [adId]). One row per channel: all 4 [Channel.allChannels] the
/// server returns (PENDING-synthesized for any channel never attempted, per
/// [PublishResource.statusForAd]'s own doc comment) —
/// Telegram/Instagram/YouTube fully shown, OLX grayed, carrying
/// the same status pill as every other row with §29's short "Not available
/// on mobile" line where the others print their last-attempt stamp (§5's
/// full desktop-extension sentence lives on `publish-channels-sheet` and
/// the Publish section, which have room for it).
///
/// **Retry (build contract §7.3, closed).** `POST /publish/ads/:adId/
/// :channel/retry` now exists, so Retry on a [PublishStatus.failed] row is
/// wired for real — but **only** for [Channel.telegram]/[Channel.instagram]
/// ([_isRetryableChannel]), the two channels with a genuine server-to-server
/// call to replay. YouTube and OLX keep the old visibly-disabled treatment
/// with a stated reason: YouTube has no direct-publish call at all (only
/// [PublishResource.reportYoutube], a report-back for a browser upload),
/// and OLX needs the desktop extension `apps/console` ships with no mobile
/// equivalent — see [_nonRetryableReason], which quotes the live server's
/// own `NON_RETRYABLE_REASONS` verbatim so fixture mode never invents
/// different copy for the same situation.
///
/// The server's [ApiErrorException.code] on a retry failure is a genuinely
/// different situation depending on the value — `alreadyPublished` (retry
/// would double-post), `awaitingReview` (a human may be mid-flight),
/// `notFailed` (nothing to retry — a stale screen), `retryUnavailable` (a
/// pre-retry-support FAILED row with nothing stored to replay),
/// `retryInProgress` (a concurrent retry already won). [_retry] surfaces
/// [ApiException]'s own message for every one of these — the server already
/// writes each as a distinct, user-legible sentence (see
/// `PublishResource.retry`'s own doc comment) — rather than collapsing them
/// into one generic "failed" toast.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../listing_editor_error_message.dart';
import '../state/listing_editor_providers.dart';
import '../state/listing_editor_repository_provider.dart';
import 'channel_tile.dart';
import 'form/publish_section.dart' show channelLabel;

/// Only these two channels have a real server-to-server publish call for
/// [PublishResource.retry] to replay — see this file's doc comment.
bool _isRetryableChannel(Channel channel) =>
    channel == Channel.telegram || channel == Channel.instagram;

/// Verbatim from `NON_RETRYABLE_REASONS` in
/// `apps/api/src/services/publishService.js` — shown under a disabled
/// Retry for a FAILED row on a channel [_isRetryableChannel] excludes (in
/// practice this is only ever reachable for YouTube, via
/// [PublishResource.reportYoutube] reporting a failure; OLX rows never
/// reach this far since they render their own always-grayed branch
/// instead). Takes [l10n] rather than
/// a [BuildContext] — a pure function, not a widget; see
/// `lib/l10n/README.md`'s guidance for threading localization through a
/// non-widget file.
///
/// The four display-only channels (ruling 7.13) share [Channel.unknown]'s
/// arm rather than getting reason strings of their own. They are formally
/// unreachable here: this function only ever sees a channel that came off
/// `GET /publish/ads/:adId/status`, [Channel.fromWire] has no case that
/// produces any of them, and [Channel.allChannels] — the list the server
/// synthesizes PENDING placeholders from — excludes them by construction.
/// Writing four server-shaped "why this can't retry" strings would mean
/// quoting a `NON_RETRYABLE_REASONS` entry that does not exist in
/// `publishService.js`, so the generic unknown-channel copy is the honest
/// fallback for a row that can only appear if the server contract changes.
String _nonRetryableReason(AppLocalizations l10n, Channel channel) =>
    switch (channel) {
      Channel.youtube => l10n.listingEditorYoutubeNonRetryableReason,
      Channel.olx => l10n.listingEditorOlxNonRetryableReason,
      Channel.telegram || Channel.instagram => '',
      Channel.unknown ||
      Channel.threads ||
      Channel.facebookMarketplace ||
      Channel.x ||
      Channel.linkedin => l10n.listingEditorUnknownChannelReason,
    };

class PublishStatusScreen extends ConsumerStatefulWidget {
  const PublishStatusScreen({super.key, required this.adId});

  final String adId;

  @override
  ConsumerState<PublishStatusScreen> createState() =>
      _PublishStatusScreenState();
}

class _PublishStatusScreenState extends ConsumerState<PublishStatusScreen> {
  // Per-channel, not a single screen-wide flag — Telegram and Instagram can
  // each be mid-retry independently, and one row's spinner must not block
  // the other's tap.
  final Set<Channel> _retryingChannels = {};

  Future<void> _retry(Channel channel) async {
    if (_retryingChannels.contains(channel)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _retryingChannels.add(channel));

    try {
      await ref
          .read(listingEditorRepositoryProvider)
          .retryPublish(adId: widget.adId, channel: channel);
      ref.invalidate(publishStatusProvider(widget.adId));
      if (!mounted) return;
      // SCREENS.md quotes no retry-specific copy (the endpoint didn't
      // exist yet when it was written) — extrapolating
      // `publish-channels-sheet.dart`'s own "{channel} post published!"
      // pattern for a fresh attempt, documented here rather than presented
      // as spec'd text, same convention that file's own doc comment uses.
      LaCasaToast.showSuccess(
        context,
        l10n.listingEditorRetrySuccessMessage(channelLabel(l10n, channel)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // Was a private `_messageFor` here; lifted to
      // `listing_editor_error_message.dart` unchanged so `create-listing`'s
      // Create and `edit-listing`'s Save/Delete stop reporting every
      // failure as "Something went wrong." — see that file's own doc
      // comment.
      LaCasaToast.showError(context, listingEditorErrorMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _retryingChannels.remove(channel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final statusAsync = ref.watch(publishStatusProvider(widget.adId));

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: l10n.listingEditorPublishStatusNavTitle,
              onBack: () => _leave(context),
              backKey: const ValueKey('publishStatus-back'),
            ),
            Expanded(
              child: statusAsync.when(
                loading: () => const _LoadingBody(),
                error: (error, stackTrace) => FullWidthState(
                  icon: Icons.error_outline_rounded,
                  message: l10n.listingEditorPublishStatusLoadErrorMessage,
                  actionLabel: l10n.sharedRetryLabel,
                  onAction: () =>
                      ref.invalidate(publishStatusProvider(widget.adId)),
                ),
                data: (status) => _StatusBody(
                  adId: widget.adId,
                  status: status,
                  retryingChannels: _retryingChannels,
                  onRetry: _retry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
          vertical: AppSpacing.base,
        ),
        children: [
          for (var i = 0; i < 5; i++) ...[
            ShimmerBox(
              height: 76,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
        ],
      ),
    );
  }
}

class _StatusBody extends ConsumerWidget {
  const _StatusBody({
    required this.adId,
    required this.status,
    required this.retryingChannels,
    required this.onRetry,
  });

  final String adId;
  final AdPublishStatus status;
  final Set<Channel> retryingChannels;
  final ValueChanged<Channel> onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The mockup opens this screen with a `.prefill` identity card naming
    // the ad being published. It reads a *second*, independent provider —
    // rendered only in its data branch, so a failed ad fetch leaves the
    // channel list (this screen's actual subject) fully usable.
    final ad = ref.watch(editListingAdProvider(adId)).value;

    // Every channel the server sends — [Channel.allChannels] is the whole
    // list and each entry is a row an agent can act on or a row with an
    // honest stated reason why not, so nothing is filtered here.
    final rows = status.channels;

    // **Pull-to-refresh (UX audit §9.3).** This is the screen the whole
    // finding is sharpest on: an agent lands here *specifically* to watch
    // an in-flight publish, and every row that says PENDING is a row that
    // is expected to change on its own. Nothing on this screen polls, and
    // [publishStatusProvider] is a plain `FutureProvider` that resolves
    // once — so before this, a PENDING pill could not change without
    // killing the app, and the only `ref.invalidate` in the file lived on
    // the error state's Retry, which by definition never renders while the
    // fetch is succeeding.
    //
    // The identity card's own fetch is invalidated alongside it: one
    // gesture, everything the screen shows. It is `invalidate`d rather
    // than awaited because it is decorative — [_StatusBody] renders `.value`
    // only, so a slow or failing ad fetch must not hold the refresh
    // spinner up or fail the gesture. The awaited half is the channel
    // list, which is the screen's actual subject.
    //
    // `.when`'s `skipLoadingOnRefresh` defaults to true, so the rows stay
    // on screen under the spinner instead of collapsing back to
    // [_LoadingBody] mid-gesture.
    return RefreshIndicator(
      key: const ValueKey('publishStatus-refresh'),
      onRefresh: () {
        ref.invalidate(editListingAdProvider(adId));
        return ref.refresh(publishStatusProvider(adId).future);
      },
      child: ScrollConfiguration(
        behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
        child: ListView.separated(
          // Five rows no longer overflow every phone this app targets, so
          // the list must stay explicitly draggable or pull-to-refresh
          // silently stops existing on the taller devices.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.base,
            AppSpacing.screenGutter,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
          ),
          itemCount: rows.length + (ad == null ? 0 : 1),
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.base),
          itemBuilder: (context, index) {
            if (ad != null) {
              if (index == 0) return _AdIdentityCard(ad: ad);
              index -= 1;
            }
            final row = rows[index];
            return _ChannelRow(
              row: row,
              retrying: retryingChannels.contains(row.channel),
              onRetry: () => onRetry(row.channel),
            );
          },
        ),
      ),
    );
  }
}

/// `.prefill glf` — a 28px thumbnail, the ad title in bold, and
/// `#{id} · {district}, {city}` beneath it.
class _AdIdentityCard extends StatelessWidget {
  const _AdIdentityCard({required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.flatForm,
      borderRadius: BorderRadius.circular(AppRadii.md),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              width: 28,
              height: 28,
              child: ListingPhoto(url: ad.photos.firstOrNull),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ad.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
                Text(
                  '${Formatters.adIdBadge(ad.id)} · ${ad.district}, ${ad.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.specMeta.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.row,
    required this.retrying,
    required this.onRetry,
  });

  final ChannelStatus row;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isOlx = row.channel == Channel.olx;

    // `.pst{display:flex;align-items:flex-start;gap:12px}` — brand tile,
    // then the title/meta column, then a right-aligned `.pst__r` column
    // holding the status pill above the "View Post" link.
    //
    // **The dimming is scoped, not global (UX audit §10.5).** This used to
    // be one `Opacity(0.55)` around the whole card, which took the "Not
    // available on mobile" line down with it — the line that *explains*
    // the dimming, already drawn in `muted` (3.75:1 on white before any
    // fade) and landing near 1.9:1 after it. The rule this row now follows
    // is the one that finding argues for: fade the parts that say "this
    // channel is off" (the brand tile and its name), and render the part
    // that says *why* at full strength. `ink2` rather than `muted`,
    // because it is now the only thing on the row carrying information the
    // user does not already have.
    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Dimmed(
            dim: isOlx,
            child: ChannelIconTile(channel: row.channel),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dimmed(
                  dim: isOlx,
                  child: Text(
                    channelLabel(l10n, row.channel),
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                ),
                if (isOlx) ...[
                  // `<span class="pst__m">Not available on mobile</span>`
                  // — the short line goes in the meta slot every other
                  // row uses for its last-attempt stamp; §5's long
                  // desktop-extension sentence stays on the surfaces that
                  // have room for it (the publish sheet and the Publish
                  // section).
                  const SizedBox(height: 3),
                  Text(
                    key: const ValueKey('publishStatus-olxReason'),
                    l10n.listingEditorOlxNotAvailableLabel,
                    style: type.specMeta.copyWith(color: colors.ink2),
                  ),
                ] else ...[
                  if (row.lastAttemptAt case final t?) ...[
                    const SizedBox(height: 3),
                    Text(
                      l10n.listingEditorLastAttemptLabel(Formatters.date(t)),
                      style: LaCasaTypography.tabular(
                        type.specMeta,
                      ).copyWith(color: colors.muted),
                    ),
                  ],
                  if (row.errorMessage case final e?
                      when row.status == PublishStatus.failed) ...[
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 12,
                          color: AppStatusColors.errorText,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            e,
                            style: type.specMeta.copyWith(
                              color: AppStatusColors.errorText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (row.status == PublishStatus.failed) ...[
                    const SizedBox(height: AppSpacing.sm),
                    if (_isRetryableChannel(row.channel))
                      _RetryButton(retrying: retrying, onTap: onRetry)
                    else ...[
                      _DisabledRetryPill(colors: colors, type: type),
                      const SizedBox(height: 4),
                      // `ink2`, not `faint` — same §10.5 rule the OLX
                      // row follows above. This sentence is the entire
                      // reason the pill next to it is inert, and `faint`
                      // is 2.53:1 on white at this size.
                      Text(
                        _nonRetryableReason(l10n, row.channel),
                        style: type.caption.copyWith(color: colors.ink2),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          // `.pst__r{flex:none}` in the mockup — but `flex:none` is only
          // safe there because every status the mockup draws is short
          // (PUBLISHED/PENDING/FAILED). §29 has this pill quote the raw
          // wire enum in caps, and the longest real one,
          // `DRAFTED_AWAITING_REVIEW`, wants ~250dp — more
          // than the ~230dp of free space this Row has to give away at
          // 360dp once the 38dp brand tile and its two 12dp gaps are
          // taken out.
          //
          // **Why this column is [Flexible] (finding: "Instagram" wrapped
          // mid-word).** A `Row` sizes its *non-flexible* children first,
          // at whatever width they ask for, and only then splits what is
          // left among the flexible ones. This column used to be
          // non-flexible: it took its full intrinsic width, that came to
          // more than the row had, and the free space the `Expanded` name
          // column then divided up was clamped to zero — the name was
          // laid out at 0dp and wrapped a character per line. Wrapping
          // this column in [Flexible] puts it into the same split
          // instead.
          //
          // **[Flexible] and [Expanded] are the same widget with
          // different [FlexFit]s** — `Expanded` is
          // `Flexible(fit: FlexFit.tight)`, and `fit` decides whether the
          // child is *forced* to fill its share (tight) or merely allowed
          // to (loose). It is not an ordering or a priority: both
          // children here carry the default `flex: 1`, so neither is
          // measured "first" and each is offered exactly half the free
          // space — ~115dp at 360dp, ~335dp at 800dp. The name column
          // keeps its half, and when the pill's half is too narrow it
          // ellipsizes through [StatusPill]'s own `Flexible` +
          // `maxLines: 1`, which is what that is there for.
          //
          // **No fixed `maxWidth` on this column.** A 120dp cap did
          // nothing at all on a phone (the flex split already stops at
          // ~115dp there) while on a tablet, in landscape, or on an
          // unfolded foldable it truncated `DRAFTED_AWAITING_REVIEW` for
          // no reason — half the free space is ~335dp at 800dp, which
          // prints it in full.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // `<span class="pst__r"><span class="st st--mute">
                // PENDING</span></span>` — OLX carries a status pill
                // like every other row (the server synthesizes PENDING
                // for a channel never attempted); the faded brand tile
                // and the meta line say why it never will be.
                //
                // Not inside [_Dimmed]: this pill is the row's status,
                // not a control, and it is the one place a user checks to
                // answer "did this go out?". Fading the answer to that
                // question is the same mistake as fading the reason.
                PublishStatusPill(status: row.status),
                if (row.externalUrl case final url? when !isOlx) ...[
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    key: const ValueKey('publishStatus-viewPost'),
                    // No `url_launcher` in this build (the same app-wide
                    // gap §5.3 documents for the Instagram OAuth URL) —
                    // copy to clipboard and say so, rather than a tap
                    // that silently does nothing.
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: url));
                      LaCasaToast.showSuccess(
                        context,
                        l10n.listingEditorPostLinkCopiedMessage,
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The mockup puts the link glyph *before* its
                        // label.
                        const Icon(
                          Icons.link_rounded,
                          size: 12,
                          color: AppAccent.color,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.listingEditorViewPostLinkLabel,
                          style: type.specMeta.copyWith(color: AppAccent.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The real, tappable Retry affordance — [Channel.telegram]/
/// [Channel.instagram] FAILED rows only (see this file's doc comment).
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.retrying, required this.onTap});

  final bool retrying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      key: const ValueKey('publishStatus-retry'),
      // Disabled mid-flight rather than left tappable — a second tap while
      // the first retry is still in the air would race the same "did this
      // already post?" question the whole endpoint exists to avoid.
      onTap: retrying ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppAccent.color.withValues(alpha: 0.12),
          borderRadius: AppRadii.pill,
        ),
        child: retrying
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppAccent.color),
                ),
              )
            : Text(
                AppLocalizations.of(context).sharedRetryLabel,
                style: type.label.copyWith(color: AppAccent.color),
              ),
      ),
    );
  }
}

/// The always-disabled Retry, for the channels [_isRetryableChannel]
/// excludes — a non-retryable FAILED row still shows the affordance so it
/// reads as "present but genuinely inert," not merely "missing."
///
/// **It is a different control, not a faded one (UX audit §10.5).** This
/// used to be `Opacity(0.5)` over `muted`-on-`sunk` text, which is 3.75:1
/// before the fade and under 2:1 after it — illegible on the one word that
/// names what is unavailable. It now drops the opacity entirely and takes
/// its "disabled" from the two things that carry it honestly: a `sunk`
/// fill with `ink2` text, which shares nothing with [_RetryButton]'s
/// accent tint, and [Semantics] `enabled: false`, which the bare `Opacity`
/// never told a screen reader at all.
class _DisabledRetryPill extends StatelessWidget {
  const _DisabledRetryPill({required this.colors, required this.type});

  final LaCasaColors colors;
  final LaCasaTypography type;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      child: Container(
        key: const ValueKey('publishStatus-retry'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: AppRadii.pill,
        ),
        child: Text(
          AppLocalizations.of(context).sharedRetryLabel,
          style: type.label.copyWith(color: colors.ink2),
        ),
      ),
    );
  }
}

/// Fades [child] when [dim] and does nothing at all when it does not —
/// the one place this file expresses "this channel is switched off."
///
/// Exists so that a disabled row's *explanation* can sit outside it (UX
/// audit §10.5): the previous code wrapped the whole card in a single
/// [Opacity], which is exactly the mistake — the sentence that tells you
/// why a thing is faded must not itself be faded. Wrapping the two parts
/// that mean "off" (the brand tile and the channel name) keeps the
/// treatment where it belongs and makes it impossible to widen by
/// accident.
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.dim, required this.child});

  /// The mockup's own value for the grayed OLX row.
  static const double _opacity = 0.55;

  final bool dim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!dim) return child;
    return Opacity(opacity: _opacity, child: child);
  }
}
