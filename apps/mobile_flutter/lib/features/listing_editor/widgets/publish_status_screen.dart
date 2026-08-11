/// `publish-status` (SCREENS.md §29) — pushed from `edit-listing` (its own
/// "Publish Status" link) and `notifications` (a publish-kind row, per
/// `WORK_TAB_CONTRACT.md`'s routing table) at `RoutePaths.workPublishStatus`
/// (`:id` → [adId]). One row per channel, always exactly the 5
/// [Channel.allChannels] the server returns (PENDING-synthesized for any
/// channel never attempted, per [PublishResource.statusForAd]'s own doc
/// comment) — Telegram/Instagram/YouTube fully shown, OLX grayed with §5's
/// fixed hint.
///
/// **Retry (build contract §7.3, closed).** `POST /publish/ads/:adId/
/// :channel/retry` now exists, so Retry on a [PublishStatus.failed] row is
/// wired for real — but **only** for [Channel.telegram]/[Channel.instagram]
/// ([_isRetryableChannel]), the two channels with a genuine server-to-server
/// call to replay. YouTube/OLX/Realting keep the old visibly-disabled
/// treatment with a stated reason: YouTube has no direct-publish call at
/// all (only [PublishResource.reportYoutube], a report-back for a browser
/// upload), OLX needs the desktop extension `apps/console` ships with no
/// mobile equivalent, and Realting syncs through a scheduled feed, not a
/// per-ad call — see [_nonRetryableReason], which quotes the live server's
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
import '../state/listing_editor_providers.dart';
import '../state/listing_editor_repository_provider.dart';
import 'form/publish_section.dart' show channelLabel, olxUnavailableHint;

/// Only these two channels have a real server-to-server publish call for
/// [PublishResource.retry] to replay — see this file's doc comment.
bool _isRetryableChannel(Channel channel) =>
    channel == Channel.telegram || channel == Channel.instagram;

/// Verbatim from `NON_RETRYABLE_REASONS` in
/// `apps/api/src/services/publishService.js` — shown under a disabled
/// Retry for a FAILED row on a channel [_isRetryableChannel] excludes (in
/// practice this is only ever reachable for YouTube, via
/// [PublishResource.reportYoutube] reporting a failure; OLX rows never
/// reach this far since they render their own always-grayed branch instead,
/// and nothing in this app ever attempts Realting). Takes [l10n] rather than
/// a [BuildContext] — a pure function, not a widget; see
/// `lib/l10n/README.md`'s guidance for threading localization through a
/// non-widget file.
String _nonRetryableReason(AppLocalizations l10n, Channel channel) =>
    switch (channel) {
      Channel.youtube => l10n.listingEditorYoutubeNonRetryableReason,
      Channel.olx => l10n.listingEditorOlxNonRetryableReason,
      Channel.realting => l10n.listingEditorRealtingNonRetryableReason,
      Channel.telegram || Channel.instagram => '',
      Channel.unknown => l10n.listingEditorUnknownChannelReason,
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
      LaCasaToast.showError(context, _messageFor(l10n, e));
    } finally {
      if (mounted) setState(() => _retryingChannels.remove(channel));
    }
  }

  static String _messageFor(AppLocalizations l10n, ApiException e) {
    if (e is ApiErrorException) return e.message;
    if (e is NetworkException) {
      return l10n.listingEditorNetworkErrorMessage;
    }
    return l10n.listingEditorGenericErrorMessage;
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

class _StatusBody extends StatelessWidget {
  const _StatusBody({
    required this.status,
    required this.retryingChannels,
    required this.onRetry,
  });

  final AdPublishStatus status;
  final Set<Channel> retryingChannels;
  final ValueChanged<Channel> onRetry;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.base,
          AppSpacing.screenGutter,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        itemCount: status.channels.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.base),
        itemBuilder: (context, index) {
          final row = status.channels[index];
          return _ChannelRow(
            row: row,
            retrying: retryingChannels.contains(row.channel),
            onRetry: () => onRetry(row.channel),
          );
        },
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

    return Opacity(
      opacity: isOlx ? 0.55 : 1,
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    channelLabel(l10n, row.channel),
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                ),
                if (isOlx)
                  Text(
                    l10n.listingEditorOlxNotAvailableLabel,
                    style: type.caption.copyWith(color: colors.faint),
                  )
                else
                  PublishStatusPill(status: row.status),
              ],
            ),
            if (isOlx) ...[
              const SizedBox(height: 4),
              Text(
                olxUnavailableHint(l10n),
                style: type.caption.copyWith(color: colors.faint),
              ),
            ] else ...[
              if (row.lastAttemptAt case final t?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.listingEditorLastAttemptLabel(Formatters.date(t)),
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
              ],
              if (row.errorMessage case final e?
                  when row.status == PublishStatus.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  e,
                  style: type.bodySmall.copyWith(
                    color: AppStatusColors.errorText,
                  ),
                ),
              ],
              if (row.externalUrl case final url?) ...[
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  key: const ValueKey('publishStatus-viewPost'),
                  // No `url_launcher` in this build (the same app-wide gap
                  // §5.3 documents for the Instagram OAuth URL) — copy to
                  // clipboard and say so, rather than a tap that silently
                  // does nothing.
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
                      Text(
                        l10n.listingEditorViewPostLinkLabel,
                        style: type.label.copyWith(color: AppAccent.color),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: AppAccent.color,
                      ),
                    ],
                  ),
                ),
              ],
              if (row.status == PublishStatus.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                if (_isRetryableChannel(row.channel))
                  _RetryButton(retrying: retrying, onTap: onRetry)
                else ...[
                  _DisabledRetryPill(colors: colors, type: type),
                  const SizedBox(height: 4),
                  Text(
                    _nonRetryableReason(l10n, row.channel),
                    style: type.caption.copyWith(color: colors.faint),
                  ),
                ],
              ],
            ],
          ],
        ),
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

/// The old always-disabled look, kept verbatim for the channels
/// [_isRetryableChannel] excludes — same visual OLX's own always-disabled
/// treatment uses, so a non-retryable FAILED row still reads as "present
/// but genuinely inert," not merely "styled differently for no reason."
class _DisabledRetryPill extends StatelessWidget {
  const _DisabledRetryPill({required this.colors, required this.type});

  final LaCasaColors colors;
  final LaCasaTypography type;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
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
          style: type.label.copyWith(color: colors.muted),
        ),
      ),
    );
  }
}
