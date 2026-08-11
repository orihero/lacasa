/// `profile-buyer` (SCREENS.md §3.15) — the Profile tab's body for a signed
/// in `role: "user"` (or `"unknown"`, which `profile_role_screen.dart`
/// routes here too — see that file's switch). Header "Profile", an info
/// card (avatar/fullName/email/phone), then Account and Session rows.
///
/// **Router wiring**: takes no constructor arguments; reads
/// `authSessionProvider` itself. `profile_role_screen.dart`'s buyer branch
/// becomes `const ProfileBuyerScreen()`.
///
/// **`user` can be `null`.** [AuthSessionState.role] and `.user` are set
/// together by every real sign-in path
/// ([AuthSessionNotifier.signIn]/`signInWithPassword`/`registerAccount`), but
/// [AuthSessionNotifier.setRole] — the test/dev-only escape hatch its own doc
/// comment names — can set a role with no user behind it. Every field below
/// degrades to an em dash rather than a null-check crash, the same call
/// `agent_info_block.dart` makes for a missing phone.
///
/// **"Register as Agent" opens the form via [LinkLauncher.open]** — a real
/// external-browser launch, no longer a copy-to-clipboard stand-in. The URL
/// itself, `https://forms.gle/1Kr71PzWjqqCQcVTA`, is not invented for this
/// task: it's the exact Google Form `apps/web/src/routes/profilePage/
/// profilePage.jsx`'s own "Register as Agent" link already points real
/// buyers at, so mobile opens the same real form a desktop user would have
/// reached. If nothing on the device can open it, this falls back to
/// copying the link instead, with the toast saying so honestly.
///
/// **The tension SCREENS.md leaves unresolved, worth flagging explicitly**:
/// §3.13 (`register`) now builds a full realtor-signup flow into account
/// creation itself — "Buyer"/"Realtor" cards, solo/agency fields, the whole
/// pending-verification path — for a brand-new signup. §3.15's "Register as
/// Agent" row is unchanged by that and still only offers an *existing* buyer
/// the old Google-Form path with no equivalent in-app upgrade flow. Section
/// 13's own copy confirms this is intentional ("§15's 'Register as Agent' row
/// still covers an existing buyer upgrading in place, and is unchanged") but
/// it does mean a signed-in buyer who wants to become a realtor gets a worse,
/// external-form experience than a brand-new signup gets — implementing
/// §3.15 as written rather than silently pointing this row at `register`'s
/// in-app flow instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/platform/link_launcher.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../language/language.dart';

/// `apps/web/src/routes/profilePage/profilePage.jsx`'s live "Register as
/// Agent" link — see this file's doc comment.
const String _registerAsAgentFormUrl = 'https://forms.gle/1Kr71PzWjqqCQcVTA';

class ProfileBuyerScreen extends ConsumerWidget {
  const ProfileBuyerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final user = ref.watch(authSessionProvider).user;

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
                AppLocalizations.of(context).profileBuyerScreenTitle,
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
                  _BuyerInfoCard(user: user),
                  const SizedBox(height: AppSpacing.section),
                  ListRowGroupLabel(
                    AppLocalizations.of(context).profileBuyerAccountGroupLabel,
                  ),
                  ListRow(
                    icon: Icons.bookmark_border_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerSavedListingsRowTitle,
                    onTap: () => context.push(RoutePaths.profileSaved),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.edit_outlined,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerUpdateProfileRowTitle,
                    onTap: () => context.push(RoutePaths.profileEdit),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.translate_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerLanguageRowTitle,
                    onTap: () => showLanguageSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.work_outline_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerRegisterAsAgentRowTitle,
                    trailingIcon: Icons.north_east_rounded,
                    onTap: () => _openRegisterAsAgentLink(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  ListRowGroupLabel(
                    AppLocalizations.of(context).profileBuyerSessionGroupLabel,
                  ),
                  ListRow(
                    icon: Icons.logout_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerLogoutRowTitle,
                    danger: true,
                    trailingIcon: null,
                    onTap: () => confirmAndSignOut(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRegisterAsAgentLink(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final opened = await ref
        .read(linkLauncherProvider)
        .open(Uri.parse(_registerAsAgentFormUrl));
    if (!context.mounted || opened) return;

    // No browser on this device, or the OS declined the launch — fall back
    // to the previous copy-and-toast behaviour rather than a tap that
    // looks like it did nothing.
    await Clipboard.setData(const ClipboardData(text: _registerAsAgentFormUrl));
    if (!context.mounted) return;
    LaCasaToast.showSuccess(
      context,
      AppLocalizations.of(context).profileBuyerRegisterLinkCopiedToast,
    );
  }
}

/// `.me gl` — avatar, fullName, email, phone. §3.15's exact field list, in
/// that order.
class _BuyerInfoCard extends StatelessWidget {
  const _BuyerInfoCard({required this.user});

  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final fullName = user?.fullName;
    final email = user?.email;
    final phone = user?.phoneNumber?.trim();

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.cardXl),
      distortionWidth: 18,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          AgentAvatar(
            avatarUrl: user?.avatar,
            fullName: fullName ?? '',
            size: 54,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (fullName == null || fullName.isEmpty) ? '—' : fullName,
                  overflow: TextOverflow.ellipsis,
                  style: type.identityName.copyWith(color: colors.ink),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  (email == null || email.isEmpty) ? '—' : email,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  (phone == null || phone.isEmpty) ? '—' : phone,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
