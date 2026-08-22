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
///
/// ## …except during a cold start (this run's audit §7.6)
///
/// `role == null` is not always "signed out". On relaunch,
/// `AuthSessionNotifier.build` returns `signedOut(isRestoring: true)` and
/// validates the persisted token against `/me` on a microtask, so for one
/// round trip a returning agent's role is `null` and
/// `profile_role_screen.dart` routes them straight here — to a card telling
/// them to sign in to "manage your business", which they already did. §3.14's
/// copy is a *claim about the user*, and for that window the claim is false.
/// Nothing in `lib/` read [AuthSessionState.isRestoring] before this change.
///
/// While the restore is in flight the prompt card is replaced by
/// [_PromptCardSkeleton] — same footprint, no copy — and both rows below it
/// stay exactly as they are: Language and Contact Us need no session at all,
/// so hiding them would remove working controls to fix a sentence. The header
/// title stays too, for the same reason `saved_listings_screen.dart` keeps
/// its own: a user should know what screen they are on before its content
/// lands.
///
/// **`profile_role_screen.dart` still needs its own version of this.** It is
/// navigation-owned and untouched here, so the tab bar still reflows from 4
/// to 5 tabs when an agent's restore lands (a documented, accepted trade-off
/// — `auth_session.dart`), and `AgentPitchBanner` still pitches "become an
/// agent" to an existing agent for that same window.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../contact/contact.dart';
import '../../language/language.dart';

class ProfileSignedOutScreen extends ConsumerWidget {
  const ProfileSignedOutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    // See the file doc comment's §7.6 section — `role == null` during a
    // startup restore is "we don't know yet", not "you are signed out".
    final isRestoring = ref.watch(
      authSessionProvider.select((state) => state.isRestoring),
    );

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
                  if (isRestoring)
                    const _PromptCardSkeleton(
                      key: ValueKey('profileSignedOutRestoringSkeleton'),
                    )
                  else
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
                    // `.lrow__s` — the active locale's own native name, the
                    // one string that says which language is selected
                    // without opening the sheet.
                    // Same source `settings` and `profile-agent` read for
                    // their own Language row — a still-loading read shows
                    // English, per `language_sheet.dart`.
                    subtitle:
                        (ref.watch(languageProvider).value ?? AppLanguage.en)
                            .nativeName,
                    onTap: () => showLanguageSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileSignedOutContactUsRowTitle,
                    subtitle: AppLocalizations.of(
                      context,
                    ).profileSignedOutContactUsRowSubtitle,
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
                  label: AppLocalizations.of(
                    context,
                  ).profileSignedOutSignInButtonLabel,
                  filled: true,
                  onTap: () => context.push(RoutePaths.login),
                ),
              ),
              // `.btns{gap:10px}`.
              const SizedBox(width: 10),
              Expanded(
                child: _PromptButton(
                  label: AppLocalizations.of(
                    context,
                  ).profileSignedOutSignUpButtonLabel,
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

/// [_SignInPromptCard]'s placeholder while the startup restore decides
/// whether this screen should be on screen at all — see the file doc
/// comment's §7.6 section.
///
/// Built from the same [GlassSurface] with the same padding as the card it
/// stands in for, so the prompt does not jump when it resolves, and from
/// [ShimmerBox]es rather than greyed-out text: a skeleton is the app's
/// established "the answer is in flight" vocabulary (`saved-listings`,
/// `my-listings`, `coworkers`, `search` all use it), and unlike dimmed copy
/// it makes no statement a screen reader could read back as fact.
class _PromptCardSkeleton extends StatelessWidget {
  const _PromptCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
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
          // The 50px icon chip.
          ShimmerBox(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          const SizedBox(height: AppSpacing.base),
          // Two lines standing in for §3.14's wrapped prompt sentence. The
          // width is stated because this [Column] centres its children
          // (matching the card it stands in for), so a box with no width of
          // its own would lay out at zero under those loose constraints —
          // the second line gets its width from [FractionallySizedBox]
          // instead.
          ShimmerBox(
            width: double.infinity,
            height: 12,
            borderRadius: BorderRadius.circular(AppRadii.xs),
          ),
          const SizedBox(height: AppSpacing.sm),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: ShimmerBox(
              height: 12,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // The two 54px CTAs.
          Row(
            children: [
              Expanded(
                child: ShimmerBox(
                  height: 54,
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ShimmerBox(
                  height: 54,
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
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
        // `.btn{height:54px;border-radius:27px;font-size:13.5px;
        // font-weight:600;letter-spacing:.1px}`.
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: filled
              ? BoxDecoration(
                  gradient: AppAccent.gradient,
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                  boxShadow: AppShadows.accentGlow,
                )
              // `.btn--ghost` is a *filled* flat-glass pill, not a
              // transparent outline. Painted opaquely rather than as a
              // nested GlassSurface: this button sits inside the prompt
              // card's own lens, and lenses must not nest.
              : BoxDecoration(
                  color: colors.card,
                  border: Border.all(color: colors.line),
                  borderRadius: BorderRadius.circular(AppRadii.pillButton),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x23201C2E),
                      blurRadius: 16,
                      spreadRadius: -14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
          child: Text(
            label,
            style: type.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: filled ? Colors.white : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
