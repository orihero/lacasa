/// `profile-agent` (SCREENS.md §3.16) — the Profile tab's body for a signed
/// in `role: "agent"` or `role: "coworker"`. Header "Profile", an identity
/// block (role badge, avatar, fullName, phone as a `tel:` link), then Account
/// and Session rows.
///
/// **Router wiring**: takes no constructor arguments; reads
/// `authSessionProvider` itself. `profile_role_screen.dart`'s agent/coworker
/// branch becomes `const ProfileAgentScreen()`.
///
/// **The role badge shows the RAW wire string** — `"agent"` or `"coworker"`,
/// lowercase, un-prettified — because §3.16 says "Role badge (raw string
/// `"agent"` or `"coworker"`)" in exactly those words. `UserRole.name` is
/// used rather than a hand-written switch because Dart's enum member names
/// (`agent`, `coworker`) already are the wire strings
/// (`api/models/enums.dart`'s `UserRole.fromWire`) — no separate `.wire`
/// getter exists on this enum the way it does on `AdType`, so `.name` is the
/// one source of truth for "the raw string", not a coincidence to rely on.
///
/// **Connected Accounts is agent-only**, per §3.16's own "(agent only)"
/// annotation — hidden for `role: "coworker"`, matching web's
/// coworkers-can't-manage-channels rule this app inherits throughout (the
/// same gate `map_view`/`work` branches apply elsewhere).
///
/// **Phone dials via [LinkLauncher.dial]** — §3.16's `tel:` link, now real.
/// When there's no dialer on the device (or the OS declines to launch it),
/// it falls back to copying the number instead, with the toast saying so
/// honestly rather than pretending the tap did nothing.
///
/// **Two rows have no route yet** — "Connected Accounts" and "Messages".
/// `route_paths.dart` already has `RoutePaths.profileEdit`/`profileSaved`/
/// `profileSettings` (used below) but no Profile-branch equivalent of
/// `RoutePaths.workConnectedAccounts` or a Messages path at all. This isn't
/// solved by reusing `RoutePaths.workConnectedAccounts`: that path lives
/// under the *Work* shell branch, and `route_paths.dart`'s own comment on
/// `agentsListingDetail` explains why a pushed screen needs its own copy of
/// the route per branch it can be pushed from ("a pushed screen stays in the
/// back stack of the tab it was opened from") — pushing a `/work/...` path
/// from the Profile tab would switch the visible tab to Work, which is not
/// what tapping a Profile row should do. So both rows below push a literal,
/// not-yet-registered path (`/profile/connected-accounts`,
/// `/profile/messages`) that follows the exact naming `profileEdit`/
/// `profileSaved`/`profileSettings` already use. Per this task's brief
/// ("Rows pointing at screens that do not exist yet ... must still be
/// rendered and must navigate — the integration step wires the routes"),
/// wiring these up is: add `RoutePaths.profileConnectedAccounts =
/// '/profile/connected-accounts'` and `RoutePaths.profileMessages =
/// '/profile/messages'`, register both routes in `app_router.dart`'s Profile
/// branch, and (optionally, purely mechanical) swap the two literal strings
/// below for the new constants.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../language/language.dart';

class ProfileAgentScreen extends ConsumerWidget {
  const ProfileAgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final session = ref.watch(authSessionProvider);
    // `role == UserRole.agent` specifically (not just "not coworker") — a
    // `null` role never reaches this screen (`profile_role_screen.dart`
    // only builds it for agent/coworker), but `setRole`'s test/dev escape
    // hatch could in principle leave this screen showing for some other
    // role, and "agent only" should stay false rather than true by default
    // in that case.
    final isAgent = session.role == UserRole.agent;

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
                AppLocalizations.of(context).profileAgentScreenTitle,
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
                  _AgentIdentityCard(
                    user: session.user,
                    roleRaw: session.role?.name,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  ListRowGroupLabel(
                    AppLocalizations.of(context).profileAgentAccountGroupLabel,
                  ),
                  ListRow(
                    icon: Icons.edit_outlined,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentEditProfileRowTitle,
                    onTap: () => context.push(RoutePaths.profileEdit),
                  ),
                  if (isAgent) ...[
                    const SizedBox(height: AppSpacing.base),
                    ListRow(
                      icon: Icons.link_rounded,
                      title: AppLocalizations.of(
                        context,
                      ).profileAgentConnectedAccountsRowTitle,
                      // Not yet in RoutePaths — see this file's doc comment.
                      onTap: () => context.push('/profile/connected-accounts'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.settings_outlined,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentSettingsRowTitle,
                    onTap: () => context.push(RoutePaths.profileSettings),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentMessagesRowTitle,
                    // Not yet in RoutePaths — see this file's doc comment.
                    onTap: () => context.push('/profile/messages'),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.translate_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentLanguageRowTitle,
                    onTap: () => showLanguageSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  ListRowGroupLabel(
                    AppLocalizations.of(context).profileAgentSessionGroupLabel,
                  ),
                  ListRow(
                    icon: Icons.logout_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentLogoutRowTitle,
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
}

/// `.me gl` — role badge + avatar, fullName, phone (`tel:` stand-in). §3.16
/// doesn't list email in the identity block (unlike §3.15's buyer card), so
/// none is shown here — not an omission, the spec's own field list is
/// shorter for this variant.
class _AgentIdentityCard extends ConsumerWidget {
  const _AgentIdentityCard({required this.user, required this.roleRaw});

  final AuthUser? user;

  /// The raw wire role string ("agent"/"coworker"), already resolved by the
  /// caller from `AuthSessionState.role` rather than `user?.role` so the
  /// badge still renders correctly in the `setRole`-without-`user` edge case
  /// this file's doc comment describes.
  final String? roleRaw;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final fullName = user?.fullName;
    final phone = user?.phoneNumber?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;

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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      (fullName == null || fullName.isEmpty) ? '—' : fullName,
                      style: type.identityName.copyWith(color: colors.ink),
                    ),
                    if (roleRaw case final role?) _RoleBadge(role),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (hasPhone)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => dialOrCopyPhone(context, ref, phone),
                    child: Text(
                      phone,
                      style: type.bodySmall.copyWith(
                        color: AppAccent.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Text(
                    '—',
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

/// `.st st--acc` — the raw-string role pill. Deliberately not capitalized or
/// relabeled; see this file's doc comment.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge(this.role);

  final String role;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      height: 23,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppStatusColors.accentStatusBg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(role, style: type.caption.copyWith(color: AppAccent.color)),
    );
  }
}
