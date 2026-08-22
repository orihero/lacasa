/// `profile-agent` (SCREENS.md §3.16) — the Profile tab's body for a signed
/// in `role: "agent"` or `role: "coworker"`. Header "Profile", an identity
/// block (role badge, avatar, fullName, phone as a `tel:` link), then Account
/// and Session rows.
///
/// **Router wiring**: reads `authSessionProvider` itself, and takes a
/// [ProfileAgentScreen.branchPrefix] naming the branch root it is mounted
/// under, because it is now mounted in *two* places (see `app_router.dart`'s
/// two-shell note):
///
/// - the buyer shell's Profile tab, via `profile_role_screen.dart` —
///   `const ProfileAgentScreen()`, i.e. the `/profile` default;
/// - the agent shell's own Profile tab — `ProfileAgentScreen(branchPrefix:
///   RoutePaths.workProfile)`.
///
/// Every row below pushes `'$branchPrefix/…'` so it lands in whichever tree
/// the screen is currently in, the same convention `settings_screen.dart`
/// and `listing_detail_screen.dart` already follow. The prefix is also how
/// this screen knows which shell it is in, and therefore which direction the
/// Browse/Work switch below should point.
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
/// **Every row's destination is registered now.** "Connected Accounts" and
/// "Messages" used to push literal, not-yet-declared `/profile/...` strings;
/// both routes exist in both shells today, and both rows build their path
/// from [ProfileAgentScreen.branchPrefix] instead of a literal — which is
/// also what stopped them from being a per-shell special case.
///
/// **The Workspace group is the Browse/Work switch** (see
/// `navigation/workspace_mode.dart`). It is one row whose direction follows
/// the shell this screen is in: in the agent shell it offers Browse ("look at
/// the marketplace like a client"), in the buyer shell it offers the way back
/// to the workspace. Tapping it only calls `setMode` — `app_router.dart`'s
/// redirect listens to that provider and performs the shell swap, so this
/// screen deliberately does not navigate itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../navigation/workspace_mode.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../language/language.dart';

class ProfileAgentScreen extends ConsumerWidget {
  const ProfileAgentScreen({super.key, this.branchPrefix = RoutePaths.profile});

  /// The branch root this screen is mounted under — `/profile` in the buyer
  /// shell (the default), `/work/profile` in the agent shell. Every row
  /// below pushes `'$branchPrefix/…'`; see this file's doc comment.
  final String branchPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final session = ref.watch(authSessionProvider);
    // Which way the Workspace row points. Derived from the prefix rather
    // than from `workspaceModeProvider` itself: the mounted shell *is* the
    // mode as far as this screen is concerned, and reading the shell avoids
    // a frame in which the row offers to take the agent where they already
    // are (the mode flips first, the redirect lands a frame later).
    final inAgentShell = branchPrefix == RoutePaths.workProfile;
    // `role == UserRole.agent` specifically (not just "not coworker") — a
    // `null` role never reaches this screen (`profile_role_screen.dart`
    // only builds it for agent/coworker), but `setRole`'s test/dev escape
    // hatch could in principle leave this screen showing for some other
    // role, and "agent only" should stay false rather than true by default
    // in that case.
    final isAgent = session.role == UserRole.agent;
    // Same source `settings`'s own Language row subtitle reads — see
    // `language_sheet.dart` for why a still-loading read shows English.
    final selectedLanguage =
        ref.watch(languageProvider).value ?? AppLanguage.en;

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
                    subtitle: AppLocalizations.of(
                      context,
                    ).profileAgentEditProfileRowSubtitle,
                    onTap: () => context.push('$branchPrefix/edit'),
                  ),
                  if (isAgent) ...[
                    const SizedBox(height: AppSpacing.base),
                    ListRow(
                      // `stack-fill` in the mockup — layered sheets, one per
                      // connected channel, not a chain link. Matched by
                      // `settings_screen.dart`'s row for the same destination.
                      icon: Icons.layers_rounded,
                      title: AppLocalizations.of(
                        context,
                      ).profileAgentConnectedAccountsRowTitle,
                      subtitle: AppLocalizations.of(
                        context,
                      ).profileAgentConnectedAccountsRowSubtitle,
                      onTap: () =>
                          context.push('$branchPrefix/connected-accounts'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.settings_outlined,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentSettingsRowTitle,
                    subtitle: AppLocalizations.of(
                      context,
                    ).profileAgentSettingsRowSubtitle,
                    onTap: () => context.push('$branchPrefix/settings'),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentMessagesRowTitle,
                    subtitle: AppLocalizations.of(
                      context,
                    ).profileAgentMessagesRowSubtitle,
                    onTap: () => context.push('$branchPrefix/messages'),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.translate_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileAgentLanguageRowTitle,
                    // `.lrow__s` — the current selection, in its own name
                    // ("English" / "O‘zbekcha" / "Русский"), read from the
                    // same provider `language_sheet.dart` writes.
                    subtitle: selectedLanguage.nativeName,
                    onTap: () => showLanguageSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  ListRowGroupLabel(
                    AppLocalizations.of(
                      context,
                    ).profileAgentWorkspaceGroupLabel,
                  ),
                  ListRow(
                    key: const ValueKey('profileAgentWorkspaceModeRow'),
                    icon: inAgentShell
                        ? Icons.travel_explore_rounded
                        : Icons.dashboard_rounded,
                    title: inAgentShell
                        ? AppLocalizations.of(
                            context,
                          ).profileAgentBrowseModeRowTitle
                        : AppLocalizations.of(
                            context,
                          ).profileAgentWorkModeRowTitle,
                    subtitle: inAgentShell
                        ? AppLocalizations.of(
                            context,
                          ).profileAgentBrowseModeRowSubtitle
                        : AppLocalizations.of(
                            context,
                          ).profileAgentWorkModeRowSubtitle,
                    // Sets the mode and nothing else — `app_router.dart`'s
                    // `_AuthRouterRefresh` listens to this provider and the
                    // redirect swaps the shell. Navigating here too would
                    // race that redirect to the same destination.
                    onTap: () => ref
                        .read(workspaceModeProvider.notifier)
                        .setMode(
                          inAgentShell
                              ? WorkspaceMode.browse
                              : WorkspaceMode.work,
                        ),
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
      decoration: BoxDecoration(
        color: AppStatusColors.accentStatusBg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      // `.st{flex:none;display:inline-flex}` — the pill hugs its label. The
      // shrink-wrapping `Align` (rather than the `alignment:` argument this
      // used to pass, which resolves to `constraints.biggest` and stretched
      // the badge across the whole identity card inside the name row's
      // bounded `Wrap`) is also what keeps the label vertically centred in
      // the tight 23px box.
      child: Align(
        widthFactor: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // `.st::before` — a 5px `currentColor` status dot, 5px before
            // the label.
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppAccent.color,
              ),
            ),
            const SizedBox(width: 5),
            Text(role, style: type.caption.copyWith(color: AppAccent.color)),
          ],
        ),
      ),
    );
  }
}
