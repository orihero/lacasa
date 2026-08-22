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
///
/// ## The realtor application has a state, and this screen now reads it (§7.5)
///
/// The tension above has a sharp edge that was shipping as a bug. §3.13's
/// realtor signup creates a **`role: "user"` account** — approval is a
/// manual back-office act — so a person who picks "Realtor" on `register`
/// sees one transient toast and then lands on *this* screen, the buyer one.
/// Until this revision the only realtor-related thing on it was the
/// "Register as Agent" row, rendered unconditionally, opening the Google
/// Form. The natural reading of that is that the signup did not take, and
/// the natural response is to apply a second time through a channel the
/// office does not correlate with the account. A **rejected** applicant was
/// never told anything at all.
///
/// [RealtorProfile.status] was already parsed off the wire and hung on
/// [AuthUser.realtor] (`api/models/auth_user.dart`) with no reader anywhere
/// in `lib/`. The Account group now branches on it:
///
///  - [RealtorStatus.pending] → a non-tappable [_RealtorApplicationCard]
///    saying the application is under review and naming the number the
///    office will ring ([RealtorProfile.officePhone] when the applicant gave
///    one — an agency's switchboard is what they asked to be called on —
///    otherwise the account's own phone). The Google-Form row is **hidden**:
///    there is nothing useful a second application can do while the first is
///    open, and offering one is what made the screen read as a failure.
///  - [RealtorStatus.rejected] → the same card, saying so, with **"Contact
///    Us"** ([showContactSheet], §3.11) as its action. A rejected applicant
///    needs a human, not the same form that was already turned down.
///  - anything else → today's row, unchanged.
///
/// [RealtorStatus.approved] falls into that last bucket deliberately: an
/// approved application is what promotes the account to `role: "agent"`, so
/// it renders `profile-agent` and never reaches this file. Treating a
/// momentarily-inconsistent session as "no application" keeps the previous
/// behaviour rather than inventing a fourth state for a case that should not
/// occur.
///
/// **This is a deviation from §3.15's row list**, which names "Register as
/// Agent" flatly with no conditions — flagged for the spec owner rather than
/// folded in silently, since three implementations share that section.
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
import '../../contact/contact.dart';
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
    final savedCount = ref.watch(favouriteAdIdsProvider).length;
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
                    // `.lrow__s` — the mockup shows "4 listings" here. The
                    // count comes from [favouriteAdIdsProvider], the
                    // app-wide saved-id set every heart control already
                    // reads, so this row costs no fetch of its own;
                    // `savedListingsProvider` would have pulled the full
                    // listings just to call `.length` on them.
                    subtitle: AppLocalizations.of(
                      context,
                    ).profileBuyerSavedListingsRowSubtitle(savedCount),
                    onTap: () => context.push(RoutePaths.profileSaved),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.edit_outlined,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerUpdateProfileRowTitle,
                    subtitle: AppLocalizations.of(
                      context,
                    ).profileBuyerUpdateProfileRowSubtitle,
                    onTap: () => context.push(RoutePaths.profileEdit),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  ListRow(
                    icon: Icons.translate_rounded,
                    title: AppLocalizations.of(
                      context,
                    ).profileBuyerLanguageRowTitle,
                    // `.lrow__s` — the current selection, in its own name
                    // ("English" / "O‘zbekcha" / "Русский").
                    subtitle: selectedLanguage.nativeName,
                    onTap: () => showLanguageSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  // The realtor slot: an application's status when there is
                  // one, today's Google-Form row when there isn't. See the
                  // file doc comment's §7.5 section.
                  switch (user?.realtor?.status) {
                    RealtorStatus.pending => _RealtorApplicationCard(
                      key: const ValueKey('profileBuyerRealtorPendingCard'),
                      icon: Icons.hourglass_top_rounded,
                      title: AppLocalizations.of(
                        context,
                      ).profileBuyerRealtorPendingRowTitle,
                      body: _pendingSubtitle(context, user),
                      appliedAt: user?.realtor?.appliedAt,
                    ),
                    RealtorStatus.rejected => _RealtorApplicationCard(
                      key: const ValueKey('profileBuyerRealtorRejectedCard'),
                      icon: Icons.info_outline_rounded,
                      title: AppLocalizations.of(
                        context,
                      ).profileBuyerRealtorRejectedRowTitle,
                      body: AppLocalizations.of(
                        context,
                      ).profileBuyerRealtorRejectedRowSubtitle,
                      appliedAt: user?.realtor?.appliedAt,
                      actionLabel: AppLocalizations.of(
                        context,
                      ).profileBuyerRealtorRejectedActionLabel,
                      onAction: () => showContactSheet(context),
                    ),
                    _ => ListRow(
                      key: const ValueKey('profileBuyerRegisterAsAgentRow'),
                      icon: Icons.work_outline_rounded,
                      title: AppLocalizations.of(
                        context,
                      ).profileBuyerRegisterAsAgentRowTitle,
                      subtitle: AppLocalizations.of(
                        context,
                      ).profileBuyerRegisterAsAgentRowSubtitle,
                      trailingIcon: Icons.north_east_rounded,
                      onTap: () => _openRegisterAsAgentLink(context, ref),
                    ),
                  },
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

  /// The pending card's body line. §3.13's own verification note promises
  /// "We'll call the number above", so the card repeats *which* number that
  /// was: an agency applicant's [RealtorProfile.officePhone] when they gave
  /// one (that is the number they asked to be reached on), otherwise the
  /// account's own phone. A user with neither — possible, since `phoneNumber`
  /// is nullable on [AuthUser] — gets the no-phone variant rather than a
  /// sentence with an empty gap where a number should be.
  static String _pendingSubtitle(BuildContext context, AuthUser? user) {
    final l10n = AppLocalizations.of(context);
    final office = user?.realtor?.officePhone?.trim();
    final personal = user?.phoneNumber?.trim();
    final phone = (office != null && office.isNotEmpty)
        ? office
        : (personal != null && personal.isNotEmpty)
        ? personal
        : null;
    return phone == null
        ? l10n.profileBuyerRealtorPendingNoPhoneSubtitle
        : l10n.profileBuyerRealtorPendingRowSubtitle(phone);
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

/// The realtor-application status card that stands in for the "Register as
/// Agent" row while an application is open or was turned down — see the file
/// doc comment's §7.5 section for when each variant renders.
///
/// Shaped like a [ListRow] (same [GlassSurface] material, same 36px icon
/// chip, same title step) rather than reusing one, for two reasons a flag on
/// [ListRow] would not have solved cleanly: [body] must **wrap** — "We'll
/// call +998 71 200 10 20 — usually within one business day." is two lines on
/// a phone and [ListRow.subtitle] is a single ellipsized line by design — and
/// this card carries a third line ([appliedAt]) plus an optional inline
/// action, neither of which any list row in this app has.
///
/// It is deliberately **not** tappable as a whole even in the [onAction]
/// variant: the whole point of the pending state is that there is nothing to
/// do yet, and a card-wide gesture on a mostly-informational surface is how
/// you get an accidental Contact Us sheet. Only the action label is a target.
class _RealtorApplicationCard extends StatelessWidget {
  const _RealtorApplicationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.appliedAt,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a callback, or neither.',
       );

  final IconData icon;
  final String title;
  final String body;

  /// [RealtorProfile.appliedAt] — rendered as a quiet trailing line so the
  /// applicant can see *when* the clock they are being asked to wait on
  /// started. Omitted entirely when the wire didn't carry one, rather than
  /// printing an em dash for a date.
  final DateTime? appliedAt;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      // Not `button: true` — see the class doc comment. The label reads the
      // whole card so a screen reader gets the status and the reason in one
      // pass instead of three disconnected fragments.
      label: '$title. $body',
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.base,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // `.lrow__ic` — the same 36px chip every Profile row draws.
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.sunk,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, size: 17, color: colors.ink),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: type.rowTitle.copyWith(color: colors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    // `ink2`, not `muted`: this is the explanation, and
                    // §10.1 of this run's audit records `muted` as failing
                    // WCAG AA against the light palette at this text size.
                    style: type.bodySmall.copyWith(color: colors.ink2),
                  ),
                  if (appliedAt case final applied?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).profileBuyerRealtorAppliedAtLabel(
                        // `.toLocal()` first: the wire carries UTC and
                        // Formatters.date only formats, never converts.
                        Formatters.date(applied.toLocal()),
                      ),
                      style: type.bodySmall.copyWith(color: colors.faint),
                    ),
                  ],
                  if (actionLabel case final label?) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TapTarget(
                      key: const ValueKey('profileBuyerRealtorContactAction'),
                      semanticsLabel: label,
                      onTap: onAction!,
                      child: Text(
                        label,
                        style: type.bodySmall.copyWith(
                          color: AppAccent.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
