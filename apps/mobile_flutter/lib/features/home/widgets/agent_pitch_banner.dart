/// The signed-out-only agent pitch banner (build spec, "Signed-out agent
/// pitch banner"). Visible only for `role == null` — a fully signed-out
/// session, not merely "not agent" — matching the mockup's own
/// `matchWhen('signed-out')` rule, which the build spec explicitly calls
/// out must also hide this for a signed-in buyer.
///
/// ## Why `role == null` is not enough on a cold start
/// `navigation/auth_session.dart` deliberately returns
/// `AuthSessionState.signedOut(isRestoring: true)` from `build()` and
/// validates the persisted token against `/me` on a microtask, so that the
/// first frame paints immediately rather than blocking on a network call
/// with no bound. For the length of that round trip a *returning agent* is
/// indistinguishable, by `role` alone, from a visitor who has never signed
/// in — and this banner is the loudest thing on the screen that acts on
/// the difference. Left unguarded it spends that window telling an agent
/// with fifty live listings to "become an agent", with a button that would
/// take them to Register.
///
/// So this widget reads [AuthSessionState.isRestoring] and renders nothing
/// while it is `true`. Nothing, not a skeleton: this is a pitch, not
/// content the user is waiting on, and a shimmering placeholder would
/// announce "something is coming here" for a banner that is about to be
/// correct to omit for most of the sessions that see it. Rendering nothing
/// also keeps the collapse identical to the signed-in case below, which the
/// surrounding feed's spacing already accounts for.
///
/// This is the first reader of `isRestoring` in the app — that field's own
/// doc comment still says nothing reads it. A splash/gate that hides the
/// whole reflow (including the tab bar's 4→5 reshuffle) is the real fix and
/// lives in `lib/navigation/`, which this task does not own; guarding the
/// one widget that makes a *false claim about the user* is the part that
/// can be done from here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';

class AgentPitchBanner extends ConsumerWidget {
  const AgentPitchBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    // Order matters only for readability — both branches render nothing —
    // but they are different facts: "we know you are signed out" versus
    // "we do not know yet". See this file's doc comment.
    if (session.isRestoring) return const SizedBox.shrink();
    final isSignedOut = session.role == null;
    if (!isSignedOut) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    // `.pitch{margin-top:16px}` belongs to the banner itself, so the gap
    // above it must disappear with it — otherwise a signed-in feed keeps
    // both of the caller's section spacers and shows 40dp of dead air
    // between the promo rail and "Featured Listings" instead of 20dp.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.lg,
        AppSpacing.screenGutter,
        0,
      ),
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        // A full-width panel, not a chip: widen the refraction band back out
        // from the small-first `.gl` default so the edge reads as a thick
        // pane rather than a hairline.
        distortionWidth: 18,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // `.pitch h3{font-size:13px;font-weight:700;
                  // color:var(--ink);letter-spacing:-.2px}` — a rule of its
                  // own, one step below `.panel__h h3`'s 15.5, so this
                  // starts from the nearest named role (`cardTitle`,
                  // 13.5/700/-0.2) and takes only the size down.
                  Text(
                    l10n.homeAgentPitchHeading,
                    style: type.cardTitle.copyWith(
                      color: colors.ink,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // `.pitch p{margin-top:4px;font-size:11px;line-height:1.5;
                  // color:var(--muted)}`.
                  Text(
                    l10n.homeAgentPitchSubtitle,
                    style: type.bodySmall.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            GestureDetector(
              key: const ValueKey('getStartedAgentPitch'),
              onTap: () => context.push(RoutePaths.register),
              // `.btn--sm{height:44px;border-radius:22px;font-size:12.5px;
              // width:auto;padding:0 18px}` — a fixed 44dp pill sized to its
              // label, not vertical padding around it, which also keeps the
              // tap target at the 44dp minimum.
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: AppAccent.gradient,
                  borderRadius: AppRadii.pill,
                  boxShadow: AppShadows.accentGlow,
                ),
                child: Text(
                  l10n.homeAgentPitchButtonLabel,
                  style: type.rowTitle.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
