/// `register` (SCREENS.md §3.13) — "Sign Up". A root-navigator modal, same
/// bucket as `login`, reached at `RoutePaths.register` from `login`'s own
/// link, `profile-signed-out`'s "Sign Up" button, and `home-feed`'s
/// signed-out "Get Started" banner (§3.3).
///
/// **Field labels, button labels and the realtor note/toast are quoted from
/// §3.13 character for character**: "Full name", "Phone number", "Email",
/// "Password", "I'm signing up as", "Buyer", "Realtor", "Realtor type",
/// "Solo agent", "Agency", "Agency name", "Office phone", "Team size" (with
/// its four option labels — "Just me for now" / "2–5" / "6–15" / "16+",
/// copied from `apps/web/src/routes/register/register.jsx`'s own
/// `TEAM_SIZE_LABELS`, the one other place in this monorepo that already
/// turns `@lacasa/domain`'s `TEAM_SIZE` keys into this exact text), "Sign
/// up" / "Create realtor account", and the realtor verification note/toast.
/// Two sentences accompanying "Solo agent"/"Agency" in §13's prose
/// ("no extra fields…", "may invite coworkers…") are **not** quoted in the
/// spec source — no quotation marks around them, unlike the note that
/// follows — so they read as designer-facing explanation, not literal UI
/// copy; the on-screen hint text under each realtor-kind pane is this
/// screen's own judgment call (kept close to that prose, not copied from
/// `mockup-e-liquid-glass.html` verbatim), same category of decision
/// `permissions_primer_screen.dart` already makes for its icon choices.
///
/// **The "Already have an account? Sign in" footer link is NOT in §3.13.**
/// §3.12 gives `login` a link to `register`; §13's own text names no
/// reciprocal link back. It is added here anyway: `register` is also
/// reachable straight from `home-feed`'s "Get Started" banner (§3.3), a
/// path with no `login` on the back stack for the close "X" to return to,
/// so without this link a user who lands here by mistake has no way back
/// to `login` short of leaving the flow entirely. Flagged as a deliberate,
/// non-spec addition rather than folded in silently.
///
/// **Client-side validation** (full name/phone/email/password non-empty,
/// agency name non-empty when agency is chosen, phone shape via
/// `Formatters.isValidUzPhone`) runs before any request, same reasoning
/// `contact_sheet.dart` documents and reusing that file's own "Required
/// fields are not filled" / "Invalid phone number format" wording — §3.13
/// specifies no client-validation copy of its own, and this is the one
/// convention already established for exactly this class of message.
/// Password length (server minimum: 6 — `registerSchema`,
/// `@lacasa/domain`) is deliberately **not** pre-checked here: the spec's
/// only stated password-related copy is a placeholder ("At least 6
/// characters", in the mockup, not this task's field list), so a too-short
/// password is left to the server's own `validation` (400) message,
/// exactly like `edit_profile_screen.dart`'s email-format decision ("implement
/// it as written").
///
/// **`ApiErrorCode.emailTaken` (409) renders under the Email field**
/// specifically (`_emailError`), mirroring `mockup-e-liquid-glass.html`'s
/// `.err` placement — every other [ApiErrorException] (`validation`, 400)
/// renders as a form-level [AuthErrorBanner] instead, since a bad
/// `agencyName`/`officePhone`/`password` isn't an Email-field problem.
///
/// **Full-screen spinner while submitting**: §3.13's literal instruction
/// (contrast §3.12's `login`, which has no such line and uses
/// [AuthPrimaryButton]'s own inline spinner instead) — see
/// [AuthFullScreenSpinner].
///
/// **Success**: role is always `"user"` even for a realtor application —
/// approving one is a separate, manual back-office act (see
/// `auth_repository.dart`'s doc comment) — so §3.13's "dismiss to
/// `home-feed`" applies uniformly regardless of which toast fires.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'auth_form_widgets.dart';

enum _AccountType { buyer, realtor }

enum _RealtorKind { solo, agency }

/// §3.13's four `Team size` options, display text copied from
/// `apps/web/src/routes/register/register.jsx`'s `TEAM_SIZE_LABELS` — see
/// this file's doc comment. `enums.dart` (owned outside this task) has no
/// display-label getter of its own, only [TeamSize.wire], so this mapping
/// lives here rather than being invented a second time elsewhere. Takes
/// [AppLocalizations] rather than a `BuildContext` — a pure function fed the
/// `l10n` its one call site (this screen's `build`) already has in hand.
String _teamSizeLabel(AppLocalizations l10n, TeamSize size) => switch (size) {
  TeamSize.justMe => l10n.authRegisterTeamSizeJustMeLabel,
  TeamSize.twoToFive => l10n.authRegisterTeamSizeTwoToFiveLabel,
  TeamSize.sixToFifteen => l10n.authRegisterTeamSizeSixToFifteenLabel,
  TeamSize.sixteenPlus => l10n.authRegisterTeamSizeSixteenPlusLabel,
  TeamSize.unknown => throw StateError('TeamSize.unknown has no label'),
};

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _agencyName = TextEditingController();
  final TextEditingController _officePhone = TextEditingController();

  _AccountType _accountType = _AccountType.buyer;
  _RealtorKind _realtorKind = _RealtorKind.solo;
  TeamSize _teamSize = TeamSize.justMe;

  bool _obscurePassword = true;
  bool _submitting = false;

  /// Every failure except `emailTaken` — required fields, phone shape, the
  /// generic 400 fallback, network errors. See the file doc comment for why
  /// `emailTaken` gets its own field-level line instead.
  String? _formError;
  String? _emailError;

  bool get _isRealtor => _accountType == _AccountType.realtor;
  bool get _isAgency => _isRealtor && _realtorKind == _RealtorKind.agency;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _agencyName.dispose();
    _officePhone.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  /// Validates every field the way `contact_sheet.dart` does: emptiness
  /// before format, one form-level message for whichever check fails
  /// first — §3.13 gives no per-field copy of its own to split them by.
  bool _validate(AppLocalizations l10n) {
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final agencyName = _agencyName.text.trim();
    final officePhone = _officePhone.text.trim();

    if (fullName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        (_isAgency && agencyName.isEmpty)) {
      setState(() {
        _formError = l10n.authRegisterRequiredFieldsError;
        _emailError = null;
      });
      return false;
    }
    if (!Formatters.isValidUzPhone(phone)) {
      setState(() {
        _formError = l10n.authRegisterInvalidPhoneError;
        _emailError = null;
      });
      return false;
    }
    if (_isAgency && officePhone.isNotEmpty && !Formatters.isValidUzPhone(officePhone)) {
      setState(() {
        _formError = l10n.authRegisterInvalidPhoneError;
        _emailError = null;
      });
      return false;
    }
    setState(() {
      _formError = null;
      _emailError = null;
    });
    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // Captured once, up front — this method crosses an `await`, and the
    // toast fires right after a `context.go`, so the lookup happens while
    // `context` is unambiguously still attached (same reasoning
    // `login_screen.dart`'s `_submit` documents for its own `l10n`).
    final l10n = AppLocalizations.of(context);
    if (!_validate(l10n)) return;

    final isRealtor = _isRealtor;
    final RealtorApplicationInput? realtor = !isRealtor
        ? null
        : _realtorKind == _RealtorKind.solo
        ? const RealtorApplicationInput.solo()
        : RealtorApplicationInput.agency(
            agencyName: _agencyName.text.trim(),
            officePhone: _officePhone.text.trim().isEmpty
                ? null
                : _officePhone.text.trim(),
            teamSize: _teamSize,
          );

    setState(() => _submitting = true);

    try {
      await ref
          .read(authSessionProvider.notifier)
          .registerAccount(
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            phoneNumber: _phone.text.trim(),
            realtor: realtor,
          );
      if (!mounted) return;
      context.go(RoutePaths.home);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRealtor
                ? l10n.authRegisterRealtorSuccessToast
                : l10n.authRegisterBuyerSuccessToast,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (e is ApiErrorException && e.code == ApiErrorCode.emailTaken) {
          _emailError = e.message;
          _formError = null;
        } else {
          _formError = _messageFor(l10n, e);
          _emailError = null;
        }
      });
    }
  }

  /// Takes [AppLocalizations] as a parameter rather than a `BuildContext` —
  /// see `agent_review_sheet.dart`'s identically-shaped `_messageFor` for why.
  static String _messageFor(AppLocalizations l10n, ApiException e) {
    if (e is ApiErrorException) return e.message;
    if (e is NetworkException) {
      return l10n.authRegisterNetworkErrorMessage;
    }
    return l10n.authRegisterGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: AuthCloseButton(onTap: _dismiss),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const AuthHeroIcon(icon: Icons.person_outline_rounded),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.authRegisterHeading,
                    style: type.displayLead.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: AppSpacing.section),

                  Text(
                    l10n.authRegisterAccountTypeLabel.toUpperCase(),
                    style: type.label.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AuthPickCard(
                          icon: Icons.house_rounded,
                          title: l10n.authRegisterBuyerCardTitle,
                          subtitle: l10n.authRegisterBuyerCardSubtitle,
                          selected: !_isRealtor,
                          onTap: () =>
                              setState(() => _accountType = _AccountType.buyer),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AuthPickCard(
                          icon: Icons.work_outline_rounded,
                          title: l10n.authRegisterRealtorCardTitle,
                          subtitle: l10n.authRegisterRealtorCardSubtitle,
                          selected: _isRealtor,
                          onTap: () => setState(
                            () => _accountType = _AccountType.realtor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),

                  AuthField(
                    label: l10n.authRegisterFullNameFieldLabel,
                    controller: _fullName,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AuthField(
                    label: l10n.authRegisterPhoneFieldLabel,
                    controller: _phone,
                    hintText: '+998901234567',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AuthField(
                    label: l10n.authRegisterEmailFieldLabel,
                    controller: _email,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  AuthField(
                    label: l10n.authRegisterPasswordFieldLabel,
                    controller: _password,
                    hintText: l10n.authRegisterPasswordHint,
                    obscureText: _obscurePassword,
                    textInputAction: _isRealtor
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onSubmitted: _isRealtor ? null : (_) => _submit(),
                    trailing: AuthVisibilityToggle(
                      obscured: _obscurePassword,
                      onTap: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),

                  if (_isRealtor) ...[
                    const SizedBox(height: AppSpacing.section),
                    Text(
                      l10n.authRegisterRealtorTypeLabel.toUpperCase(),
                      style: type.label.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // `Wrap`, not `Row` — matches the team-size chip row
                    // below (same file). A bare `Row` fit both chips'
                    // English labels ("Solo agent"/"Agency") at every
                    // supported width, but Russian's "Частный
                    // риелтор"/"Агентство" overflows the 360px-wide layout
                    // by 16px (found by this run's ru/uz overflow pass —
                    // see `test/features/auth/widgets/register_screen_test
                    // .dart`'s "under ru/uz" group); `Wrap` lets the second
                    // chip drop to its own line instead of clipping.
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        AuthChip(
                          label: l10n.authRegisterSoloAgentChipLabel,
                          selected: !_isAgency,
                          onTap: () => setState(
                            () => _realtorKind = _RealtorKind.solo,
                          ),
                        ),
                        AuthChip(
                          label: l10n.authRegisterAgencyChipLabel,
                          selected: _isAgency,
                          onTap: () => setState(
                            () => _realtorKind = _RealtorKind.agency,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.base),
                    if (!_isAgency)
                      Text(
                        l10n.authRegisterSoloAgentHint,
                        style: type.bodySmall.copyWith(color: colors.muted),
                      )
                    else ...[
                      AuthField(
                        label: l10n.authRegisterAgencyNameFieldLabel,
                        controller: _agencyName,
                        helperText: l10n.authRegisterAgencyNameHelperText,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.base),
                      AuthField(
                        // "Office phone", not "Office phone (optional)".
                        // §3.13 writes it as **"Office phone"** (optional,
                        // same rule) — the bolded string is the label and
                        // the parenthetical is the spec describing the
                        // field, exactly as it does for **"Agency name"**
                        // (required; …) right above, which is rendered bare.
                        // Appending one and not the other was inconsistent
                        // with both the spec and its own sibling.
                        label: l10n.authRegisterOfficePhoneFieldLabel,
                        controller: _officePhone,
                        hintText: '+998712001020',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        l10n.authRegisterTeamSizeLabel.toUpperCase(),
                        style: type.label.copyWith(color: colors.muted),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final size in TeamSize.values)
                            if (size != TeamSize.unknown)
                              AuthChip(
                                label: _teamSizeLabel(l10n, size),
                                selected: _teamSize == size,
                                onTap: () =>
                                    setState(() => _teamSize = size),
                              ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        l10n.authRegisterAgencyOwnerHint,
                        style: type.bodySmall.copyWith(color: colors.muted),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.base),
                    AuthCallout(
                      message: l10n.authRegisterVerificationCalloutMessage,
                    ),
                  ],

                  if (_formError case final error?) ...[
                    const SizedBox(height: AppSpacing.base),
                    AuthErrorBanner(message: error),
                  ],

                  const SizedBox(height: AppSpacing.section),
                  AuthPrimaryButton(
                    label: _isRealtor
                        ? l10n.authRegisterRealtorSubmitButtonLabel
                        : l10n.authRegisterBuyerSubmitButtonLabel,
                    submitting: _submitting,
                    onTap: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: AuthFooterLink(
                      text: l10n.authRegisterFooterLinkText,
                      onTap: () => context.push(RoutePaths.login),
                    ),
                  ),
                ],
              ),
            ),
            if (_submitting) const AuthFullScreenSpinner(),
          ],
        ),
      ),
    );
  }
}
