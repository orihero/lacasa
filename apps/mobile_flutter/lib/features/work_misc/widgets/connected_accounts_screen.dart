/// `connected-accounts` (SCREENS.md §21) — header "Connected Accounts", a
/// back arrow, and seven channel sections: the two that actually connect
/// (Instagram/Telegram), then five that are rendered but permanently
/// disconnected — YouTube, Threads, Facebook Marketplace, X and LinkedIn.
///
/// The five disabled blocks are ruling 7.10's visibly-disabled treatment, not
/// placeholders: `apps/api` has no OAuth route, no token and no publish call
/// for any of them, so each is shown with its own brand tile, its own honest
/// reason in the `.lrow__s` slot, and a read-only switch that is off. YouTube
/// keeps `youtube_section.dart` (it has two disabled buttons to render); the
/// four added by ruling 7.13 share `unavailable_channel_section.dart`, which
/// documents why one parameterized section is the right shape for them.
///
/// OLX is the one channel with no block at all — §21's "no persistent account
/// concept exists in web either" applies to it and only to it, so there is
/// literally nothing to render, and the footer hint says so. Facebook
/// Marketplace was named in that same footer hint until it gained a block of
/// its own; the hint's copy was corrected with this change.
///
/// **Router wiring**: reached from two different routes,
/// `RoutePaths.workConnectedAccounts` and `RoutePaths.profileConnectedAccounts`
/// (contract §2, table row for §21) — the integration pass wires both to
/// this same class. Unlike `AgentProfileScreen`/`EditProfileScreen`, this
/// widget takes **no `branchPrefix`**: per the contract's §8 "known risks"
/// note, it never pushes anything further (every control here is either a
/// read-only status or a same-screen action — Disconnect, Connect
/// Instagram's clipboard copy, the YouTube buttons), so there is no child
/// route that would need to resolve back into "whichever branch this was
/// opened from."
///
/// That does leave one small judgment call: **where "back" goes on a cold
/// deep link with nothing to pop.** With no `branchPrefix` telling this
/// screen which of the two branches mounted it, there is no way to answer
/// that correctly in both cases — the fallback below goes to
/// [RoutePaths.work] (this screen's primary, Settings-driven entry point;
/// `settings_screen.dart`'s own Connected Accounts row is agent-only and
/// always reachable through Work for an agent session). A deep link
/// through the Profile branch specifically would fall back to the wrong
/// tab in this one edge case — flagged for the integration pass rather
/// than silently guessed around.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'instagram_accounts_section.dart';
import 'telegram_section.dart';
import 'unavailable_channel_section.dart';
import 'youtube_section.dart';

class ConnectedAccountsScreen extends StatelessWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        // The floating [GlassTabBar] paints over the body (`TabShellScaffold`
        // sets `extendBody: true`), so the scroller reserves its own
        // clearance below instead of a bottom safe-area inset here.
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: l10n.connectedAccountsScreenTitle,
              onBack: () => _pop(context),
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    0,
                    AppSpacing.screenGutter,
                    // `.body{padding-bottom:var(--pb,104px)}` — the same
                    // tab-bar clearance `profile_agent_screen.dart` and
                    // `leads_list_screen.dart` already reserve.
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ChannelCard(child: InstagramAccountsSection()),
                      // `.chan{margin-bottom:12px}`.
                      const SizedBox(height: AppSpacing.base),
                      const _ChannelCard(child: TelegramSection()),
                      const SizedBox(height: AppSpacing.base),
                      const _ChannelCard(child: YoutubeSection()),
                      // The four display-only channels (ruling 7.13), in
                      // `Channel.publishSurfaceChannels` order so this screen
                      // lists them in the same sequence the publish surfaces
                      // do. Each is a plain [UnavailableChannelSection] —
                      // brand tile, title, its own reason, switch off — and
                      // carries the `connectedAccounts<Name>Toggle` key on the
                      // section itself (see that file on why the key does not
                      // move down onto the row).
                      const SizedBox(height: AppSpacing.base),
                      _ChannelCard(
                        child: UnavailableChannelSection(
                          key: const ValueKey('connectedAccountsThreadsToggle'),
                          title: l10n.connectedAccountsThreadsToggleTitle,
                          note: l10n
                              .connectedAccountsThreadsUnavailableNoteMessage,
                          icon: Icons.alternate_email_rounded,
                          iconGradient: kThreadsBrandGradient,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _ChannelCard(
                        child: UnavailableChannelSection(
                          key: const ValueKey(
                            'connectedAccountsFacebookMarketplaceToggle',
                          ),
                          title: l10n
                              .connectedAccountsFacebookMarketplaceToggleTitle,
                          note: l10n
                              .connectedAccountsFacebookMarketplaceUnavailableNoteMessage,
                          icon: Icons.shopping_bag_rounded,
                          iconGradient: kFacebookMarketplaceBrandGradient,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _ChannelCard(
                        child: UnavailableChannelSection(
                          key: const ValueKey('connectedAccountsXToggle'),
                          title: l10n.connectedAccountsXToggleTitle,
                          note: l10n.connectedAccountsXUnavailableNoteMessage,
                          // `Icons.close_rounded` is the brand wordmark X, not
                          // a dismiss control — the tile is decorative and the
                          // whole block is inert, so there is nothing a
                          // "close" reading could trigger. Same reasoning
                          // `channel_tile.dart`'s `channelGlyph` records.
                          icon: Icons.close_rounded,
                          iconGradient: kXBrandGradient,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      _ChannelCard(
                        child: UnavailableChannelSection(
                          key: const ValueKey(
                            'connectedAccountsLinkedinToggle',
                          ),
                          title: l10n.connectedAccountsLinkedinToggleTitle,
                          note: l10n
                              .connectedAccountsLinkedinUnavailableNoteMessage,
                          icon: Icons.business_center_rounded,
                          iconGradient: kLinkedinBrandGradient,
                        ),
                      ),
                      // `<p class="hint" style="margin-top:16px">` —
                      // `.hint{padding-left:3px;font-size:10.5px;
                      // line-height:1.5;color:var(--faint)}`.
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.lg,
                          left: 3,
                        ),
                        child: Text(
                          l10n.connectedAccountsOtherChannelsHint,
                          style: type.bodySmall.copyWith(
                            color: colors.faint,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    // See the file doc comment's note on why the fallback (no back stack to
    // pop) can only pick one of the two branches that can mount this
    // screen.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }
}

/// `.chan{border-radius:24px;padding:16px}` on the `.gl` glass material —
/// the rounded panel each of the seven channel sections lives in. Every
/// surface *inside* one of these is painted opaquely rather than as its own
/// [GlassSurface], since lenses must not nest.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.cardXl),
      // Card-sized rather than the small-first `.gl` default, so the lens
      // band reads as one continuous distortion across the panel.
      distortionWidth: 18,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}
