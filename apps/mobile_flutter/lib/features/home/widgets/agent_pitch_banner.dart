/// The signed-out-only agent pitch banner (build spec, "Signed-out agent
/// pitch banner"). Visible only for `role == null` — a fully signed-out
/// session, not merely "not agent" — matching the mockup's own
/// `matchWhen('signed-out')` rule, which the build spec explicitly calls
/// out must also hide this for a signed-in buyer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';

class AgentPitchBanner extends ConsumerWidget {
  const AgentPitchBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedOut = ref.watch(authSessionProvider).role == null;
    if (!isSignedOut) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you a real estate agent?',
                    style: type.panelHeading.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Manage your listings, leads and team in one app.',
                    style: type.bodySmall.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            GestureDetector(
              key: const ValueKey('getStartedAgentPitch'),
              onTap: () => context.push(RoutePaths.register),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: AppAccent.gradient,
                  borderRadius: AppRadii.pill,
                  boxShadow: AppShadows.accentGlow,
                ),
                child: Text(
                  'Get Started',
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
