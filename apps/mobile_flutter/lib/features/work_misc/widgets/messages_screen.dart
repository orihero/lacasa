/// `messages` (SCREENS.md §23) — header "Messages", and nothing else but
/// the banner SCREENS.md itself specifies: **"Messaging is coming soon.
/// For now, contact leads by phone."** §23's own text is explicit that
/// this stays a placeholder — "Web's Chat component is a static, unwired
/// mock — this screen intentionally stays a placeholder" — so, unlike
/// every other screen in this feature, there is no `data/`, `state/`, or
/// `*_mode.dart` here at all: there is nothing to fetch, fixture or live,
/// and inventing a repository for a screen with no data would be pure
/// ceremony over a banner. The one honest control this screen can offer —
/// "contact leads by phone" — already exists on `lead-detail` (feature D's
/// own phone affordance), not duplicated here.
///
/// **Router wiring**: reached from `RoutePaths.workMessages` and (the
/// integration pass's job) `RoutePaths.profileMessages` — same
/// no-`branchPrefix` shape as `ConnectedAccountsScreen`/`NotificationsScreen`
/// (contract §8's "known risks" note: this screen never pushes anything
/// further, so it doesn't need to know which branch mounted it).
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: AppLocalizations.of(context).messagesScreenTitle,
              onBack: () => _pop(context),
            ),
            const Expanded(child: _ComingSoonBanner()),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }
}

class _ComingSoonBanner extends StatelessWidget {
  const _ComingSoonBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Center(
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(AppRadii.cardLg),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            key: const ValueKey('messagesComingSoonBanner'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: colors.faint,
                size: 36,
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                AppLocalizations.of(context).messagesComingSoonBanner,
                textAlign: TextAlign.center,
                style: type.body.copyWith(color: colors.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
