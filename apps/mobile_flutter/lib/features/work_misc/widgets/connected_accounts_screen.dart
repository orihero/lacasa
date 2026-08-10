/// `connected-accounts` (SCREENS.md §21) — header "Connected Accounts", a
/// back arrow, and the three channel sections (Instagram/Telegram/YouTube).
/// OLX/Facebook get no connect row at all (§21: "no persistent account
/// concept exists in web either") — nothing to render for either.
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

import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'instagram_accounts_section.dart';
import 'telegram_section.dart';
import 'youtube_section.dart';

class ConnectedAccountsScreen extends StatelessWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(title: 'Connected Accounts', onBack: () => _pop(context)),
            Expanded(
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  overscroll: false,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenGutter,
                    0,
                    AppSpacing.screenGutter,
                    AppSpacing.xxl,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InstagramAccountsSection(),
                      SizedBox(height: AppSpacing.section),
                      TelegramSection(),
                      SizedBox(height: AppSpacing.section),
                      YoutubeSection(),
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
