/// `messages` (SCREENS.md §23) — header "Messages", and nothing else but
/// the banner SCREENS.md itself specifies: **"Messaging is coming soon.
/// For now, contact leads by phone."** §23's own text is explicit that
/// this stays a placeholder — "Web's Chat component is a static, unwired
/// mock — this screen intentionally stays a placeholder" — so, unlike
/// every other screen in this feature, there is no `data/`, `state/`, or
/// `*_mode.dart` here at all: there is nothing to fetch, fixture or live,
/// and inventing a repository for a screen with no data would be pure
/// ceremony over a banner. The one honest control this screen can offer —
/// "contact leads by phone" — is the mockup's own `Open Leads` pill
/// (`mockup-e-liquid-glass.html`'s `messages` section), a route out to the
/// Leads list where feature D's tap-to-call affordance lives. It routes
/// rather than dialling, so nothing is duplicated.
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
        // The floating [GlassTabBar] paints over the body (`TabShellScaffold`
        // sets `extendBody: true`), so the scroller reserves its own
        // clearance below instead of a bottom safe-area inset here.
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: AppLocalizations.of(context).messagesScreenTitle,
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
                    // `.empty{margin-top:26px}` — the card sits right under
                    // the header, not centred in the viewport.
                    26,
                    AppSpacing.screenGutter,
                    // `.body{padding-bottom:var(--pb,104px)}` — the same
                    // tab-bar clearance the sibling list screens reserve.
                    MediaQuery.of(context).padding.bottom + 100,
                  ),
                  child: const _ComingSoonBanner(),
                ),
              ),
            ),
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

    final l10n = AppLocalizations.of(context);

    return SizedBox(
      // `.empty` is a block-level div inside the 20px gutters — it fills the
      // column rather than shrink-wrapping its widest line.
      width: double.infinity,
      // `.empty{padding:34px 22px;border-radius:24px;gap:9px}`.
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: BorderRadius.circular(AppRadii.cardXl),
        // Card-sized rather than the small-first `.gl` default, so the lens
        // band reads as one continuous distortion across the card.
        distortionWidth: 18,
        padding: const EdgeInsets.symmetric(
          vertical: 34,
          horizontal: AppSpacing.xxl,
        ),
        child: Column(
          key: const ValueKey('messagesComingSoonBanner'),
          mainAxisSize: MainAxisSize.min,
          children: [
            // `.empty .i{font-size:28px;color:var(--faint)}`.
            Icon(
              Icons.mark_unread_chat_alt_rounded,
              color: colors.faint,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.md),
            // `.empty h3{font-size:13.5px;font-weight:600;color:var(--ink)}`.
            Text(
              l10n.messagesComingSoonTitle,
              textAlign: TextAlign.center,
              style: type.pickSubtitle.copyWith(color: colors.ink),
            ),
            const SizedBox(height: AppSpacing.md),
            // `.empty p{font-size:11.5px;line-height:1.6;color:var(--muted);
            // max-width:230px}`.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 230),
              child: Text(
                l10n.messagesComingSoonBody,
                textAlign: TextAlign.center,
                style: type.bodySmall.copyWith(
                  height: 1.6,
                  color: colors.muted,
                ),
              ),
            ),
            // `.empty{gap:9px}` + the button's own `margin-top:6px`.
            const SizedBox(height: 15),
            const _OpenLeadsButton(),
          ],
        ),
      ),
    );
  }
}

/// `.btn.btn--sm.btn--ink` — the one control the mockup gives this screen.
/// It routes to Leads, which is where the "tap-to-call number" the
/// paragraph promises actually lives.
class _OpenLeadsButton extends StatelessWidget {
  const _OpenLeadsButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final label = AppLocalizations.of(context).messagesOpenLeadsAction;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const ValueKey('messagesOpenLeads'),
        behavior: HitTestBehavior.opaque,
        // `go`, not `push`: Leads is a Work-branch concept and this screen
        // is also mounted under `/profile/messages`.
        onTap: () => context.go(RoutePaths.workLeads),
        // `.btn--sm{height:44px;border-radius:22px;font-size:12.5px;
        // width:auto;padding:0 18px}` + `.btn--ink`.
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colors.pill,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.selectedPillLarge,
          ),
          child: Text(
            label,
            style: type.rowTitle.copyWith(
              fontSize: 12.5,
              letterSpacing: 0.1,
              color: colors.pillInk,
            ),
          ),
        ),
      ),
    );
  }
}
