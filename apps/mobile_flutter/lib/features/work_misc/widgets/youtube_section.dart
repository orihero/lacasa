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

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import 'channel_toggle_row.dart';

class YoutubeSection extends StatelessWidget {
  const YoutubeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelToggleRow(
          key: const ValueKey('connectedAccountsYoutubeToggle'),
          title: l10n.connectedAccountsYoutubeToggleTitle,
          on: false,
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: _DisabledButton(
                key: const ValueKey('connectedAccountsYoutubeAdd'),
                label: l10n.connectedAccountsYoutubeAddAccountLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _DisabledButton(
                key: const ValueKey('connectedAccountsYoutubeSignOut'),
                label: l10n.connectedAccountsYoutubeSignOutLabel,
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
                l10n.connectedAccountsYoutubeBetaNoteMessage,
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
      label: AppLocalizations.of(context).connectedAccountsUnavailableSemanticsSuffix(label),
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
