/// The YouTube half of `connected-accounts` (§21). Ruling 7.10: YouTube has
/// **zero** backing data or OAuth route anywhere in `apps/api` — no
/// connected-channel concept, no token, nothing. This renders the read-only
/// toggle permanently off and both buttons visibly-but-permanently
/// disabled, with the "Beta — not available in this build" note in the
/// header subtitle the mockup puts a bare "Beta" in — the same
/// always-disabled treatment this app already gives OLX elsewhere
/// (contract §7.3/SCREENS.md §5's OLX bullet) rather than pretending a
/// native Google Sign-In flow exists. The disabled state is expressed as
/// opacity over each button's real material, not by flattening both into
/// one shape: "unavailable" is a state, not a different button.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import 'channel_toggle_row.dart';

/// `.chan__ic.yt{background:linear-gradient(135deg,#f45b5b,#e02020)}` —
/// YouTube's own brand gradient, deliberately not a theme token (see
/// `channel_toggle_row.dart`).
const LinearGradient kYoutubeBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF45B5B), Color(0xFFE02020)],
);

class YoutubeSection extends StatelessWidget {
  const YoutubeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelToggleRow(
          key: const ValueKey('connectedAccountsYoutubeToggle'),
          title: l10n.connectedAccountsYoutubeToggleTitle,
          // The mockup's `.lrow__s` here is a bare "Beta"; this build's own
          // note says the same thing and more, and lands in the same slot,
          // so it is reused verbatim rather than shortened — and it is no
          // longer repeated as a separate row under the buttons.
          subtitle: l10n.connectedAccountsYoutubeBetaNoteMessage,
          icon: Icons.play_arrow_rounded,
          iconGradient: kYoutubeBrandGradient,
          on: false,
        ),
        // `<div class="btns" style="margin-top:11px">` with `.btns{gap:10px}`
        // — Sign out (ghost) first, Add account (ink) second.
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _DisabledButton(
                key: const ValueKey('connectedAccountsYoutubeSignOut'),
                label: l10n.connectedAccountsYoutubeSignOutLabel,
                filled: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DisabledButton(
                key: const ValueKey('connectedAccountsYoutubeAdd'),
                label: l10n.connectedAccountsYoutubeAddAccountLabel,
                filled: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One of the two YouTube buttons. Ruling 7.10's always-disabled behaviour
/// is expressed as reduced opacity over the button's *correct* material
/// (`.btn[disabled]{opacity:.42}`), not by flattening both into identical
/// sunk chips — the shape is a separate concern from the state.
class _DisabledButton extends StatelessWidget {
  const _DisabledButton({super.key, required this.label, required this.filled});

  final String label;

  /// `true` for `.btn--ink` (Add account), `false` for `.btn--ghost glf`
  /// (Sign out).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      enabled: false,
      label: AppLocalizations.of(
        context,
      ).connectedAccountsUnavailableSemanticsSuffix(label),
      child: Opacity(
        opacity: 0.42,
        // `.btn{height:54px;border-radius:27px;font-size:13.5px;
        // font-weight:600;letter-spacing:.1px}`.
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: filled
              ? BoxDecoration(
                  color: colors.pill,
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                  boxShadow: AppShadows.selectedPillLarge,
                )
              // `.btn--ghost glf` is a *filled* flat-glass pill, not a
              // transparent outline. Painted opaquely because it sits
              // inside the `.chan` lens, and lenses must not nest — same
              // treatment `profile_signed_out_screen.dart` documents.
              : BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
          child: Text(
            label,
            style: type.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: filled ? colors.pillInk : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
