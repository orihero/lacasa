/// The YouTube half of `connected-accounts` (§21). Ruling 7.10: YouTube has
/// **zero** backing data or OAuth route anywhere in `apps/api` — no
/// connected-channel concept, no token, nothing. This renders the read-only
/// toggle permanently off and both buttons visibly-but-permanently
/// disabled with a "Beta — not available in this build" note, the same
/// always-disabled treatment this app already gives OLX elsewhere
/// (contract §7.3/SCREENS.md §5's OLX bullet) rather than pretending a
/// native Google Sign-In flow exists.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'channel_toggle_row.dart';

class YoutubeSection extends StatelessWidget {
  const YoutubeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ChannelToggleRow(
          key: ValueKey('connectedAccountsYoutubeToggle'),
          title: 'Create Youtube post',
          on: false,
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: const _DisabledButton(
                key: ValueKey('connectedAccountsYoutubeAdd'),
                label: 'Add account',
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: const _DisabledButton(
                key: ValueKey('connectedAccountsYoutubeSignOut'),
                label: 'Sign out',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: colors.faint),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Beta — not available in this build.',
                style: type.caption.copyWith(color: colors.faint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DisabledButton extends StatelessWidget {
  const _DisabledButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      enabled: false,
      label: '$label (unavailable in this build)',
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: BorderRadius.circular(AppRadii.pillButton),
          border: Border.all(color: colors.line),
        ),
        child: Text(label, style: type.rowTitle.copyWith(color: colors.faint)),
      ),
    );
  }
}
