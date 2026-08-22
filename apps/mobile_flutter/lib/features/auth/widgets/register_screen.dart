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
/// ## Client-side validation reports per field, not in one banner (§7.7)
///
/// This form used to collapse every client-side failure into a single
/// `_formError` string ("Required fields are not filled") rendered directly
/// above the submit button — i.e. *after* all seven fields on the Agency
/// branch. An empty **"Agency name"** is four fields and a chip row above
/// that banner, entirely off screen on a phone, so the message named a
/// problem the user could not see and did not say which field had it. Worse,
/// nothing validated until submit, so a mistyped phone surfaced only after
/// the whole form had been typed.
///
/// Every check now writes into its own field's `errorText` ([AuthField]
/// already renders one — it was used only for the server's `emailTaken`),
/// [_validate] evaluates **all** fields rather than returning at the first
/// failure (so fixing one mistake doesn't reveal a second on the next tap —
/// the shape `edit_profile_screen.dart`'s own `_validate` established), and
/// [_RegisterScreenState._revealFirstError] scrolls the first errored field
/// into view. The banner ([_formError]) is now reserved for **server and
/// network failures only**: a message with no field to attach it to.
///
/// Copy comes from the `authRegister*Error` ARB family. §3.13 specifies no
/// client-validation copy of its own — it names only the 409 and "server
/// validation message" — so these strings are this app's, not the spec's,
/// and the previously shared "Required fields are not filled" wording
/// (`authRegisterRequiredFieldsError`) is now unused by this screen.
///
/// Two checks are new rather than merely relocated, and both are deliberate
/// reversals of an earlier decision recorded here:
///  - **Password length** (server minimum 6 — `registerSchema`,
///    `@lacasa/domain`) was left to the server on the argument that §3.13
///    states no copy for it. But `authRegisterPasswordHint` already promises
///    "At least 6 characters" *in the field itself*, so the app states the
///    rule and then declines to check it, spending a round trip to repeat
///    its own hint back. §3.18 (`edit-profile`) spells the identical rule
///    out as spec'd copy; matching it here is consistency, not invention.
///  - **Email shape** is checked with a deliberately permissive
///    `something@something.something` test — enough to catch a missing `@`
///    or a trailing comma, never enough to reject a valid exotic address,
///    which is the failure mode that makes client-side email regexes a bad
///    idea. Anything subtler is still the server's `z.string().email()` to
///    reject.
///
/// **`ApiErrorCode.emailTaken` (409) renders under the Email field**
/// specifically (`_emailError`), mirroring `mockup-e-liquid-glass.html`'s
/// `.err` placement — every other [ApiErrorException] (`validation`, 400)
/// renders as a form-level [AuthErrorBanner] instead, since a bad
/// `agencyName`/`officePhone`/`password` isn't an Email-field problem.
///
/// ## Password managers (§7.8)
///
/// The whole form is an [AutofillGroup] and every field the platform can
/// meaningfully store carries [AutofillHints] — see `auth_form_widgets.dart`'s
/// [AuthField.autofillHints] doc comment for why that parameter, and not
/// `keyboardType`, is the thing that registers a field with iOS Keychain /
/// Android Autofill / 1Password / Bitwarden. **"Office phone" carries no
/// hint on purpose**: it is the agency's switchboard, not the signing-up
/// person's own number, and a second `telephoneNumber` field in one group
/// makes the platform guess which of the two to save.
/// [TextInput.finishAutofillContext] fires only after the server has
/// accepted the account — prompting to save a credential that was just
/// rejected teaches users to store a password that doesn't work.
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

  /// One per field, so [Scrollable.ensureVisible] can bring the first
  /// errored field into view — see [_revealFirstError]. Attached to the
  /// [AuthField] itself rather than to its inner [TextField]: the label and
  /// the error line are part of what the user needs to see, and scrolling to
  /// the input alone can leave both off screen.
  final GlobalKey _fullNameFieldKey = GlobalKey();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _agencyNameFieldKey = GlobalKey();
  final GlobalKey _officePhoneFieldKey = GlobalKey();

  bool _obscurePassword = true;
  bool _submitting = false;

  /// **Server and network failures only** — a `validation` (400) message
  /// with no field to hang it on, a [NetworkException], the generic
  /// fallback. Every client-side check writes into its own field's error
  /// instead; see the file doc comment's §7.7 section for why a single
  /// banner under seven fields was the defect.
  String? _formError;

  String? _fullNameError;
  String? _phoneError;

  /// Doubles as the server's `emailTaken` (409) line — same field, same
  /// slot, so the two never stack.
  String? _emailError;
  String? _passwordError;
  String? _agencyNameError;
  String? _officePhoneError;

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

  /// Validates **every** field, not just the first that fails, and writes
  /// each result under the field it belongs to — see the file doc comment's
  /// §7.7 section. Emptiness is checked before shape on every field so a
  /// blank one never reads "Invalid …format", which describes something the
  /// user hasn't typed yet.
  ///
  /// Clears [_formError] as well: a stale server message left standing next
  /// to fresh field errors would claim the round trip that produced it just
  /// happened.
  bool _validate(AppLocalizations l10n) {
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final agencyName = _agencyName.text.trim();
    final officePhone = _officePhone.text.trim();

    setState(() {
      _formError = null;

      _fullNameError = fullName.isEmpty
          ? l10n.authRegisterFullNameRequiredError
          : null;

      _phoneError = phone.isEmpty
          ? l10n.authRegisterPhoneRequiredError
          : Formatters.isValidUzPhone(phone)
          ? null
          : l10n.authRegisterInvalidPhoneError;

      _emailError = email.isEmpty
          ? l10n.authRegisterEmailRequiredError
          : _looksLikeEmail(email)
          ? null
          : l10n.authRegisterEmailInvalidError;

      _passwordError = password.isEmpty
          ? l10n.authRegisterPasswordRequiredError
          : password.length < _minPasswordLength
          ? l10n.authRegisterPasswordTooShortError
          : null;

      // Both agency-only fields are hidden on the Buyer and Solo branches;
      // validating them there would attach an error to a field that isn't
      // on screen, which is the exact failure §7.7 is about.
      _agencyNameError = _isAgency && agencyName.isEmpty
          ? l10n.authRegisterAgencyNameRequiredError
          : null;

      // §3.13: "Office phone" (optional, same `^\+998\d{9}$` rule) — empty
      // is valid, malformed is not.
      _officePhoneError =
          _isAgency &&
              officePhone.isNotEmpty &&
              !Formatters.isValidUzPhone(officePhone)
          ? l10n.authRegisterInvalidPhoneError
          : null;
    });

    if (_firstErroredFieldKey == null) return true;
    _revealFirstError();
    return false;
  }

  /// The topmost field currently carrying an error, in the order they are
  /// laid out on screen — `null` when the form is clean. Agency fields come
  /// last because they render last.
  GlobalKey? get _firstErroredFieldKey {
    if (_fullNameError != null) return _fullNameFieldKey;
    if (_phoneError != null) return _phoneFieldKey;
    if (_emailError != null) return _emailFieldKey;
    if (_passwordError != null) return _passwordFieldKey;
    if (_agencyNameError != null) return _agencyNameFieldKey;
    if (_officePhoneError != null) return _officePhoneFieldKey;
    return null;
  }

  /// Brings the first errored field into view. Deferred to the next frame
  /// because the error line is laid out by the [setState] that just ran —
  /// scrolling before that frame targets the field's *old* rect, which is
  /// off by the height of the message being scrolled to.
  void _revealFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _firstErroredFieldKey?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        // Leaves a little breathing room above the field rather than
        // pinning it flush against the top edge of the viewport.
        alignment: 0.1,
      );
    });
  }

  /// `registerSchema`'s (`@lacasa/domain`) own minimum, and the number
  /// `authRegisterPasswordHint` already promises in the field itself.
  static const int _minPasswordLength = 6;

  /// Deliberately permissive — see the file doc comment. This exists to
  /// catch "dilnoza@" and "dilnoza.lacasa.dev", not to adjudicate RFC 5322;
  /// anything it lets through is still the server's `z.string().email()` to
  /// reject, and a false rejection here would block a real account with no
  /// way around it.
  static final RegExp _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool _looksLikeEmail(String value) => _emailShape.hasMatch(value);

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
      // Only after the server accepted the account — see the file doc
      // comment on why a rejected credential must never reach the platform's
      // save prompt.
      TextInput.finishAutofillContext();
      context.go(RoutePaths.home);
      // LaCasaToast, not a bare SnackBar: SCREENS.md §5's toast is floating,
      // on `colors.card`, with a status glyph. A raw bar rendered Material's
      // docked dark-grey default, a visibly different component from the one
      // every other confirmation in this app uses.
      LaCasaToast.showSuccess(
        context,
        isRealtor
            ? l10n.authRegisterRealtorSuccessToast
            : l10n.authRegisterBuyerSuccessToast,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final emailTaken =
          e is ApiErrorException && e.code == ApiErrorCode.emailTaken;
      setState(() {
        _submitting = false;
        if (emailTaken) {
          _emailError = e.message;
          _formError = null;
        } else {
          _formError = _messageFor(l10n, e);
        }
      });
      // A 409 lands on a field that may well be scrolled past by now — the
      // Email box is the fourth of up to seven — so it gets the same
      // scroll-into-view treatment a client-side error does.
      if (emailTaken) _revealFirstError();
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
              // Everything below is one credential as far as the platform
              // password manager is concerned — see the file doc comment's
              // §7.8 section.
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthHeroIcon(icon: Icons.person_outline_rounded),
                    // `.hero-ic{margin-bottom:20px}`
                    const SizedBox(height: AppSpacing.section),
                    Text(
                      l10n.authRegisterHeading,
                      style: type.displayLead.copyWith(color: colors.ink),
                    ),
                    // `.lead__p{margin-top:10px}` — 12/400 in `--muted`.
                    const SizedBox(height: 10),
                    Text(
                      l10n.authRegisterLeadBody,
                      style: type.body.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: AppSpacing.section),

                    Text(
                      l10n.authRegisterAccountTypeLabel.toUpperCase(),
                      style: type.label.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // `.picks{display:grid;grid-template-columns:1fr 1fr;
                    // gap:10px}` — a grid, so its default `align-items:stretch`
                    // gives both tiles the taller one's height when a locale
                    // wraps one subtitle to two lines. A bare `Row` centres
                    // them instead, so the intrinsic pass is stated here;
                    // `stretch` alone would not do it inside the screen's
                    // scroll view, where the cross axis is unbounded.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: AuthPickCard(
                              icon: Icons.house_rounded,
                              title: l10n.authRegisterBuyerCardTitle,
                              subtitle: l10n.authRegisterBuyerCardSubtitle,
                              selected: !_isRealtor,
                              onTap: () => setState(
                                () => _accountType = _AccountType.buyer,
                              ),
                            ),
                          ),
                          // `.picks{gap:10px}` — between AppSpacing.md (8) and
                          // AppSpacing.base (12), so stated outright.
                          const SizedBox(width: 10),
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
                    ),
                    const SizedBox(height: AppSpacing.section),

                    AuthField(
                      key: _fullNameFieldKey,
                      label: l10n.authRegisterFullNameFieldLabel,
                      controller: _fullName,
                      hintText: l10n.authRegisterFullNameHint,
                      errorText: _fullNameError,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                    ),
                    // `.field{margin-top:15px}` — AppSpacing.lg's documented
                    // 14–16px band, not the 12px list-row gap.
                    const SizedBox(height: AppSpacing.lg),
                    AuthField(
                      key: _phoneFieldKey,
                      label: l10n.authRegisterPhoneFieldLabel,
                      controller: _phone,
                      hintText: '+998901234567',
                      errorText: _phoneError,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthField(
                      key: _emailFieldKey,
                      label: l10n.authRegisterEmailFieldLabel,
                      controller: _email,
                      hintText: l10n.authEmailHint,
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      // `username` first, for the same reason `login`'s email
                      // field leads with it — see that screen's own note.
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthField(
                      key: _passwordFieldKey,
                      label: l10n.authRegisterPasswordFieldLabel,
                      controller: _password,
                      hintText: l10n.authRegisterPasswordHint,
                      errorText: _passwordError,
                      obscureText: _obscurePassword,
                      textInputAction: _isRealtor
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onSubmitted: _isRealtor ? null : (_) => _submit(),
                      // `newPassword`, not `password`: this field creates a
                      // credential rather than recalling one, which is what
                      // tells the platform to offer to *generate* and then
                      // save it instead of filling an existing one.
                      autofillHints: const [AutofillHints.newPassword],
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
                          key: _agencyNameFieldKey,
                          label: l10n.authRegisterAgencyNameFieldLabel,
                          controller: _agencyName,
                          helperText: l10n.authRegisterAgencyNameHelperText,
                          errorText: _agencyNameError,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.organizationName],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AuthField(
                          // "Office phone", not "Office phone (optional)".
                          // §3.13 writes it as **"Office phone"** (optional,
                          // same rule) — the bolded string is the label and
                          // the parenthetical is the spec describing the
                          // field, exactly as it does for **"Agency name"**
                          // (required; …) right above, which is rendered bare.
                          // Appending one and not the other was inconsistent
                          // with both the spec and its own sibling.
                          key: _officePhoneFieldKey,
                          label: l10n.authRegisterOfficePhoneFieldLabel,
                          controller: _officePhone,
                          hintText: '+998712001020',
                          errorText: _officePhoneError,
                          // No `autofillHints` — see the file doc comment's
                          // §7.8 note on why the switchboard number is not
                          // the signing-up person's telephone number.
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]'),
                            ),
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
                                  onTap: () => setState(() => _teamSize = size),
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
                      AuthErrorBanner(
                        key: const ValueKey('registerErrorBanner'),
                        message: error,
                      ),
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
            ),
            // `.modal__x` — positioned over the hero icon's band rather
            // than laid out in a row above it (same as `login`).
            Positioned(
              top: 0,
              right: AppSpacing.screenGutter,
              child: AuthCloseButton(onTap: _dismiss),
            ),
            if (_submitting) const AuthFullScreenSpinner(),
          ],
        ),
      ),
    );
  }
}
