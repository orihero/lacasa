/// `profile-signed-out` (SCREENS.md §3.14) — the Profile tab's body when
/// `authSessionProvider.role == null`. Header "Profile", a sign-in prompt
/// card, and two rows that need no session at all.
///
/// **Router wiring**: takes no constructor arguments and reads no path
/// params. `lib/navigation/profile_role_screen.dart`'s `role == null` branch
/// becomes `const ProfileSignedOutScreen()` — see this feature's barrel doc
/// comment for the other two branches.
///
/// Every string here is quoted character-for-character from §3.14: the
/// prompt sentence, both button labels, both row titles.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../contact/contact.dart';
import '../../language/language.dart';

class ProfileSignedOutScreen extends StatelessWidget {
  const ProfileSignedOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                0,
              ),
              child: Text(
                AppLocalizations.of(context).profileSignedOutScreenTitle,
                style: type.navTitle.copyWith(color: colors.ink),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  0,
                  AppSpacing.screenGutter,
                  MediaQuery.of(context).padding.bottom + 100,
                ),
                children: [
                  const _SignInPromptCard(),
                  const SizedBox(height: AppSpacing.section),
                  ListRowGroupLabel(
                    AppLocalizations.of(
                      context,
                    ).profileSignedOutPreferencesGroupLabel,
                  ),
                  ListRow(
                    icon: Icons.translate_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileSignedOutLanguageRowTitle,
                    onTap: () => showLanguageSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileSignedOutContactUsRowTitle,
                    onTap: () => showContactSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.prompt gl` — the sign-in-or-sign-up card. Its heading is §3.14's exact
/// sentence: "Sign in to save listings, message agents, and manage your
/// business."
class _SignInPromptCard extends StatelessWidget {
  const _SignInPromptCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.cardXl),
      distortionWidth: 18,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenGutter,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          // `.hero-ic--sm` painted as a plain tinted chip, not a nested
          // GlassSurface — see glass_surface.dart's "Don't nest
          // GlassSurfaces" rule; this icon already sits on top of the card's
          // own lens.
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sunk,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              size: 26,
              color: AppAccent.color,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            AppLocalizations.of(context).profileSignedOutPromptMessage,
            textAlign: TextAlign.center,
            style: type.pickSubtitle.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PromptButton(
                  label: AppLocalizations.of(context).profileSignedOutSignInButtonLabel,
                  filled: true,
                  onTap: () => context.push(RoutePaths.login),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: _PromptButton(
                  label: AppLocalizations.of(context).profileSignedOutSignUpButtonLabel,
                  filled: false,
                  onTap: () => context.push(RoutePaths.register),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `.btn--acc` (filled accent gradient) / `.btn--ghost glf` (outlined) —
/// the prompt card's two side-by-side CTAs.
class _PromptButton extends StatelessWidget {
  const _PromptButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: filled
              ? BoxDecoration(
                  gradient: AppAccent.gradient,
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                  boxShadow: AppShadows.accentGlow,
                )
              : BoxDecoration(
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
          child: Text(
            label,
            style: type.label.copyWith(
              color: filled ? Colors.white : colors.ink,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
