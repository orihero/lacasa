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
/// happens next. Facebook Marketplace is omitted entirely, per §5's own
/// instruction (no compliant automation path on any platform).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../api/api.dart';
import '../../../../navigation/route_paths.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import '../publish_channels_sheet.dart';

/// SCREENS.md §5's fixed OLX hint, quoted verbatim so `publish_section.dart`
/// and `publish_channels_sheet.dart` never drift on the exact sentence.
const String kOlxUnavailableHint =
    'OLX cross-posting is only available from the desktop app (requires a '
    'browser extension).';

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
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Publish'),
        _ChannelButton(
          key: const ValueKey('publish-channel-instagram'),
          icon: Icons.camera_alt_outlined,
          label: 'Instagram',
          onTap: () => showPublishChannelsSheet(context, ad: ad),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChannelButton(
          key: const ValueKey('publish-channel-telegram'),
          icon: Icons.send_outlined,
          label: 'Telegram',
          onTap: () => showPublishChannelsSheet(context, ad: ad),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChannelButton(
          key: const ValueKey('publish-channel-youtube'),
          icon: Icons.smart_display_outlined,
          label: 'YouTube',
          enabled: false,
          hint: 'Beta — not available in this build.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChannelButton(
          key: const ValueKey('publish-channel-olx'),
          icon: Icons.storefront_outlined,
          label: 'OLX',
          enabled: false,
          hint: kOlxUnavailableHint,
        ),
        if (showPublishStatusLink) ...[
          const SizedBox(height: AppSpacing.base),
          GestureDetector(
            key: const ValueKey('publish-status-link'),
            onTap: () => context.go(
              RoutePaths.workPublishStatus.replaceFirst(':id', ad.id),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Publish Status',
                  style: type.rowTitle.copyWith(color: AppAccent.color),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.arrow_forward_rounded, size: 14, color: AppAccent.color),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.hint,
  });

  final IconData icon;
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
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: colors.ink2),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Text(
                      label,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                  ),
                  if (!enabled)
                    Icon(Icons.lock_outline_rounded, size: 15, color: colors.faint),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(hint!, style: type.caption.copyWith(color: colors.faint)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
