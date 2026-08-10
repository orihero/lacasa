/// `publish-status` (SCREENS.md §29) — pushed from `edit-listing` (its own
/// "Publish Status" link) and `notifications` (a publish-kind row, per
/// `WORK_TAB_CONTRACT.md`'s routing table) at `RoutePaths.workPublishStatus`
/// (`:id` → [adId]). One row per channel, always exactly the 5
/// [Channel.allChannels] the server returns (PENDING-synthesized for any
/// channel never attempted, per [PublishResource.statusForAd]'s own doc
/// comment) — Telegram/Instagram/YouTube fully shown, OLX grayed with §5's
/// fixed hint.
///
/// **Ruling 7.3's Retry note, applied here.** "Retry" is rendered
/// **visibly present but disabled** on a [PublishStatus.failed] row,
/// mirroring OLX's own always-disabled treatment — it is never wired to
/// re-call `publishInstagram`/`publishTelegram`, since neither endpoint is
/// designed to distinguish "retry this exact failed attempt" from "publish
/// fresh," and this build has no way to honor that distinction faithfully.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/listing_editor_providers.dart';
import 'form/publish_section.dart' show kOlxUnavailableHint;

class PublishStatusScreen extends ConsumerWidget {
  const PublishStatusScreen({super.key, required this.adId});

  final String adId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final statusAsync = ref.watch(publishStatusProvider(adId));

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: 'Publish Status',
              onBack: () => _leave(context),
              backKey: const ValueKey('publishStatus-back'),
            ),
            Expanded(
              child: statusAsync.when(
                loading: () => const _LoadingBody(),
                error: (error, stackTrace) => FullWidthState(
                  icon: Icons.error_outline_rounded,
                  message: "Couldn't load publish status.",
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(publishStatusProvider(adId)),
                ),
                data: (status) => _StatusBody(status: status),
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
            ShimmerBox(height: 76, borderRadius: BorderRadius.circular(AppRadii.card)),
            const SizedBox(height: AppSpacing.base),
          ],
        ],
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  const _StatusBody({required this.status});

  final AdPublishStatus status;

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
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.base),
        itemBuilder: (context, index) => _ChannelRow(row: status.channels[index]),
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.row});

  final ChannelStatus row;

  @override
  Widget build(BuildContext context) {
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
                    _channelLabel(row.channel),
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                ),
                if (isOlx)
                  Text(
                    'Not available on mobile',
                    style: type.caption.copyWith(color: colors.faint),
                  )
                else
                  PublishStatusPill(status: row.status),
              ],
            ),
            if (isOlx) ...[
              const SizedBox(height: 4),
              Text(kOlxUnavailableHint, style: type.caption.copyWith(color: colors.faint)),
            ] else ...[
              if (row.lastAttemptAt case final t?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Last attempt: ${Formatters.date(t)}',
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
              ],
              if (row.errorMessage case final e?
                  when row.status == PublishStatus.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(e, style: type.bodySmall.copyWith(color: AppStatusColors.errorText)),
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
                    LaCasaToast.showSuccess(context, 'Post link copied to clipboard.');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Post', style: type.label.copyWith(color: AppAccent.color)),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.open_in_new_rounded, size: 12, color: AppAccent.color),
                    ],
                  ),
                ),
              ],
              if (row.status == PublishStatus.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                Opacity(
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
                    child: Text('Retry', style: type.label.copyWith(color: colors.muted)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _channelLabel(Channel channel) => switch (channel) {
    Channel.telegram => 'Telegram',
    Channel.instagram => 'Instagram',
    Channel.youtube => 'YouTube',
    Channel.olx => 'OLX',
    Channel.realting => 'Realting',
    Channel.unknown => 'Unknown channel',
  };
}

