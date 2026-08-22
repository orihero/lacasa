/// `settings` (SCREENS.md §3.19) — header "Settings". Rows: **"Language"**
/// → `language-sheet`; **"Notifications"** toggle (mobile-only);
/// **"Connected Accounts"** (agent only) → `connected-accounts`;
/// **"About"**; **"Logout"** (red, → `delete-confirm`-style confirm).
///
/// **Router wiring**: a PUSHED screen (§1's "Pushed (full-screen,
/// back-stack)" bucket) reached from `profile-agent`, so it takes a
/// [branchPrefix] for the same reason `agent_profile_screen.dart` does —
/// `route_paths.dart` already declares both `/profile/settings` and
/// `/work/settings` as placeholders (agent-profile and the Work tab's own
/// settings entry both land here), so whichever branch pushed this screen
/// hands in its own prefix and the Connected Accounts row it opens
/// (`'$branchPrefix/connected-accounts'`) resolves back into that same back
/// stack, matching `agent_profile_screen.dart`'s listing-push convention.
///
/// ## Judgment calls this file makes, and why
///
/// **The "Connected Accounts" row is agent-only, not agent-or-coworker.**
/// SCREENS.md says so explicitly ("(agent only)") — a coworker session
/// (`UserRole.coworker`) never sees this row, matching §16's identical
/// gating on `profile-agent`'s own Connected Accounts row.
///
/// **The Notifications toggle is a real, persisted, tappable control — not
/// a disabled row.** There is no push infrastructure anywhere in this
/// project (see `data/notifications_preference_repository.dart`'s doc
/// comment for the full inventory: no messaging plugin, no device-token
/// endpoint, `permissions-primer`'s grant path is a documented no-op). A
/// toggle that flips and silently does nothing is a lie told with a
/// control, so the row's subtitle says outright that flipping it does not
/// send anything yet — the same honesty move `language_sheet.dart` makes
/// with its `_LocalisationNote`. A disabled control with a "coming soon"
/// reason was the rejected alternative: it would visually contradict the
/// design mockup (`mockup-e-liquid-glass.html`'s settings section renders
/// this switch fully interactive, `on` by default, not `.ro`) for a
/// preference that is genuinely safe to let a user set now and have honoured
/// later, unlike e.g. a "Connect" button that would imply a live OAuth flow
/// that cannot actually run.
///
/// **This is not the read-only-switch rule.** §5's "Toggle states" bullet —
/// "the Instagram/Telegram/YouTube switches on `connected-accounts` and
/// `settings` are read-only status indicators… never directly tappable" —
/// names the three channel switches by row (Instagram/Telegram/YouTube).
/// None of those rows exist on `settings` at all (only `connected-accounts`
/// has them); `settings`'s own Notifications switch is a different control
/// with a different purpose, and the design mockup confirms the split: the
/// channel switches there carry a `.ro` (read-only) class the Notifications
/// switch does not.
///
/// **"About" has no spec'd content or destination.** §3.19 names the row
/// and nothing else. A dead row that goes nowhere is worse than a small
/// amount of real information, so it shows the app name and a
/// hand-transcribed version string (see `data/app_version.dart` for why
/// that's transcribed rather than read from `PackageInfo` — no new
/// dependency in this slice) via a toast on tap.
///
/// **Both of this screen's toasts go through [LaCasaToast], not a bare
/// [SnackBar]** (this run's audit §10.4). A raw `SnackBar(content: Text(…))`
/// inherits Material's *docked dark-grey* bar with no status glyph, which is
/// a visibly different component from the floating `colors.card` toast
/// SCREENS.md §5 specifies and every other confirmation in this app renders.
/// The About row uses [LaCasaToast.showInfo] rather than `showSuccess`: a
/// green check on "La Casa 1.0.0" claims an operation completed when the row
/// only answered a question. The failed-sign-out message is a genuine
/// [LaCasaToast.showError] — it warns that the account may sign itself back
/// in on next launch, and gets the 4s error budget rather than 2.5s.
///
/// **Logout's confirm copy is not spec'd either.** §3.19 says only "(red, →
/// `delete-confirm`-style confirm)" — `delete-confirm` itself (§3.38) is a
/// *different* screen with its own contextual titles ("Delete listing?" /
/// "Delete lead?" / "Delete coworker?"), none of which fit a sign-out.
/// **Consolidated with `profile-buyer`/`profile-agent`'s identical dialog**
/// (this screen originally shipped its own bespoke `Dialog` matching
/// `mockup-e-liquid-glass.html`'s `.sh--mid` chrome; the profile screens
/// shipped a native [AlertDialog.adaptive] with the same copy — see
/// `shared/widgets/sign_out_confirm.dart`'s doc comment for why the native
/// alert is the one that survived: SCREENS.md §1 itself files
/// `delete-confirm` under "native alert style", which is exactly what this
/// row's own "delete-confirm-style" text is asking for). This screen calls
/// [confirmSignOut] for the dialog, then drives its own "Signing out…" row
/// spinner and [AuthSessionNotifier.signOut] — see `_confirmLogout` — since
/// those two behaviours are specific to a pushed screen, not something the
/// shared dialog should own.
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
import '../data/app_version.dart';
import '../state/notifications_preference_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.branchPrefix = RoutePaths.profile});

  /// The tab branch this screen was pushed into (`/profile` or `/work`) —
  /// used to build the Connected Accounts push target and the post-logout
  /// pop destination in the same back stack. See the file doc comment.
  final String branchPrefix;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final confirmed = await confirmSignOut(context);
    if (!confirmed || !mounted) return;

    setState(() => _loggingOut = true);

    // AuthSessionNotifier.signOut clears the session unconditionally but
    // rethrows if the stored token could not be removed (see its failure
    // contract). Both halves matter here: the `finally` is what stops a
    // failed keystore write from stranding this row on "Signing out…"
    // forever with no way back, and the message is the user's only cue that
    // the account may sign itself back in on next launch.
    var tokenCleared = true;
    try {
      await ref.read(authSessionProvider.notifier).signOut();
    } catch (_) {
      tokenCleared = false;
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }

    if (!mounted) return;
    if (!tokenCleared) {
      // LaCasaToast, not a bare SnackBar — see this file's doc comment on
      // the About row for the same swap and the reason behind both.
      LaCasaToast.showError(
        context,
        AppLocalizations.of(context).settingsSignOutTokenNotClearedMessage,
      );
    }
    // Navigate away either way — the session itself is gone.
    // Same "go, don't pop" reasoning as agent_profile_screen.dart's _pop:
    // once signed out, this branch's root renders differently on its own
    // (ProfileRoleScreen watches authSessionProvider), so returning to it
    // is the correct destination regardless of how deep this screen was
    // pushed.
    context.go(widget.branchPrefix);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final role = ref.watch(authSessionProvider).role;
    final showConnectedAccounts = role == UserRole.agent;

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NavRow(onBack: () => _pop(context)),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _LanguageRow(key: ValueKey('settingsLanguageRow')),
                      const SizedBox(height: AppSpacing.base),
                      const _NotificationsRow(
                        key: ValueKey('settingsNotificationsRow'),
                      ),
                      if (showConnectedAccounts) ...[
                        const SizedBox(height: AppSpacing.base),
                        ListRow(
                          key: const ValueKey('settingsConnectedAccountsRow'),
                          // `stack-fill` — layered sheets, matching
                          // `profile_agent_screen.dart`'s row for the same
                          // destination.
                          icon: Icons.layers_rounded,
                          title: AppLocalizations.of(
                            context,
                          ).settingsConnectedAccountsRowTitle,
                          // A static `.lrow__s` descriptor of the channels
                          // the screen behind it manages — deliberately not
                          // a live "n connected" count, which this screen
                          // watches no provider for.
                          subtitle: AppLocalizations.of(
                            context,
                          ).settingsConnectedAccountsRowSubtitle,
                          onTap: () => context.push(
                            '${widget.branchPrefix}/connected-accounts',
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.base),
                      ListRow(
                        key: const ValueKey('settingsAboutRow'),
                        icon: Icons.info_outline_rounded,
                        title: AppLocalizations.of(
                          context,
                        ).settingsAboutRowTitle,
                        subtitle: AppLocalizations.of(
                          context,
                        ).settingsAboutRowSubtitle(appVersion),
                        onTap: () {
                          // Neutral, not success: tapping About didn't
                          // accomplish anything, it answered a question.
                          LaCasaToast.showInfo(
                            context,
                            AppLocalizations.of(
                              context,
                            ).settingsAboutToastMessage(appName, appVersion),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.section),
                      // ListRowGroupLabel already carries its own bottom
                      // padding (AppSpacing.base) — no extra SizedBox needed
                      // before the row underneath, unlike the plain Text
                      // this replaced.
                      ListRowGroupLabel(
                        AppLocalizations.of(context).settingsSessionGroupLabel,
                      ),
                      _LogoutRow(
                        key: const ValueKey('settingsLogoutRow'),
                        loggingOut: _loggingOut,
                        onTap: _loggingOut ? null : _confirmLogout,
                      ),
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
    // Same reasoning as agent_profile_screen.dart's _pop: a deep link
    // straight into settings has nothing to pop, and "up" is just the
    // branch root rather than an error.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.branchPrefix);
    }
  }
}

LaCasaTypography _type(BuildContext context) =>
    Theme.of(context).extension<LaCasaTypography>()!;

class _NavRow extends StatelessWidget {
  const _NavRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final t = _type(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: AppLocalizations.of(context).settingsNavBackLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              // `.nav .rnd.gl` — a 38px round glass chip inside the 44px
              // tap target, not a bare glyph on the screen background.
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: GlassSurface(
                    variant: GlassVariant.onSurface,
                    borderRadius: AppRadii.pill,
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    distortionWidth: 8,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: colors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              AppLocalizations.of(context).settingsScreenTitle,
              overflow: TextOverflow.ellipsis,
              style: t.navTitle.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// The row shell every `.lrow gl` row on this screen renders through used to
// be this file's own private `_SettingsRow` — now `shared/widgets/
// list_row.dart`'s `ListRow`, consolidated with the identical shape
// `features/profile/`'s three screens independently built. See that file's
// doc comment for the two features it gained in the merge (a `trailing`
// widget override, a nullable `onTap`) and why the glass material won over
// this screen's original solid `colors.card` background.

class _LanguageRow extends ConsumerWidget {
  const _LanguageRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reads the persisted language back out for the row's subtitle, the
    // same source `language_sheet.dart`'s own selected-row highlight reads
    // — see that file for why a still-loading/failed read shows "En".
    final selected = ref.watch(languageProvider).value ?? AppLanguage.en;

    return ListRow(
      icon: Icons.translate_rounded,
      title: AppLocalizations.of(context).settingsLanguageRowTitle,
      // The mockup's subtitle is the language's own name for itself
      // ("English"), not the abbreviated radio-row label ("En") — see
      // `AppLanguage.nativeName`, which the two profile screens' Language
      // rows and the sheet's own second line all read too.
      subtitle: selected.nativeName,
      onTap: () => showLanguageSheet(context),
    );
  }
}

class _NotificationsRow extends ConsumerWidget {
  const _NotificationsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(notificationsPreferenceProvider);
    // Defaults the switch to "on" while the storage read is in flight,
    // matching SecureNotificationsPreferenceRepository.load's own default —
    // no visible flash to a different position once the read resolves.
    final enabled = enabledAsync.value ?? true;

    return ListRow(
      icon: Icons.notifications_none_rounded,
      title: AppLocalizations.of(context).settingsNotificationsRowTitle,
      subtitle: AppLocalizations.of(context).settingsNotificationsRowSubtitle,
      trailing: _NotificationsSwitch(
        // `_SettingsRow`'s own outer `Semantics(label: title)` merges this
        // switch's nested `Semantics(label: 'Notifications toggle')` into
        // itself (they share the same semantics boundary — there's no
        // `container: true`/scrollable/button-boundary between them), so
        // `find.bySemanticsLabel('Notifications toggle')` cannot address it
        // on its own. A plain key is what the widget test actually finds it
        // by instead.
        key: const ValueKey('settingsNotificationsSwitch'),
        value: enabled,
        onChanged: (value) => ref
            .read(notificationsPreferenceProvider.notifier)
            .setEnabled(value),
      ),
    );
  }
}

/// A hand-built `.sw` pill switch — `mockup-e-liquid-glass.html`'s
/// dimensions (46×28, 14 radius, 22px white thumb translating 18px) — since
/// no shared switch widget exists in `lib/shared/` yet and this build must
/// not add a dependency. Deliberately **not** the read-only `.sw.ro` variant
/// `connected-accounts`'s channel switches use — this one is a real,
/// tappable [GestureDetector], not a status indicator.
class _NotificationsSwitch extends StatelessWidget {
  const _NotificationsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      // Distinct from the row's own "Notifications" label (that Semantics
      // wraps the whole row and carries no `button: true`, since the row
      // itself has no `onTap` — only this switch is interactive) so a test
      // or screen reader can address the control unambiguously rather than
      // finding two nodes with the same label.
      button: true,
      toggled: value,
      label: AppLocalizations.of(context).settingsNotificationsToggleLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: value ? AppAccent.gradient : null,
            color: value ? null : colors.sunk,
            border: value ? null : Border.all(color: colors.line, width: 1),
          ),
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x47140F20),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({super.key, required this.loggingOut, required this.onTap});

  final bool loggingOut;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListRow(
      icon: Icons.logout_rounded,
      title: AppLocalizations.of(context).settingsLogoutRowTitle,
      subtitle: loggingOut
          ? AppLocalizations.of(context).settingsLoggingOutLabel
          : AppLocalizations.of(context).settingsLogoutRowSubtitle,
      danger: true,
      onTap: onTap,
      // `.lrow--danger` never pairs with a trailing chevron (`ListRow`'s
      // own doc comment) — explicit here since this row's `onTap` is
      // non-null, which would otherwise default to one.
      trailingIcon: null,
      trailing: loggingOut
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppStatusColors.errorText),
              ),
            )
          : null,
    );
  }
}

// The Logout confirm dialog itself now lives in
// `shared/widgets/sign_out_confirm.dart` (`confirmSignOut`) — consolidated
// with `profile-buyer`/`profile-agent`'s identical dialog rather than kept
// as this screen's own bespoke `Dialog`. See that file's doc comment for
// why `AlertDialog.adaptive` is the one that survived the merge.
