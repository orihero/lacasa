/// `edit-profile` (SCREENS.md §3.18) — header "Edit Profile", pushed from
/// `profile-buyer`'s "Update Profile" row and `profile-agent`'s "Edit
/// Profile" row onto whichever branch is hosting the Profile tab.
///
/// **Router wiring**: takes a [branchPrefix] constructor argument for the
/// same reason `agent_profile_screen.dart` does — a deep link straight into
/// this screen has nothing to pop, and "up" in that case is the Profile
/// root rather than an error. Unlike `agent-profile`, this screen never
/// pushes a sibling of its own (there is nothing beneath a form to
/// navigate to), so [branchPrefix] only ever matters for that one fallback;
/// it defaults to [RoutePaths.profile], the Profile branch's single fixed
/// route (`route_paths.dart`'s "one route; content switches on role").
///
/// **Submission goes through the auth foundation directly.** [AuthRepository
/// .updateProfile] (`PATCH /api/users/me`) is the wire call; on success the
/// returned [AuthUser] is handed to
/// `AuthSessionNotifier.signIn` so every other screen reading
/// `authSessionProvider` (the profile screens this one was pushed from,
/// chiefly) sees the new name/phone/email immediately, without a refetch.
/// Only fields that actually changed are sent — `users.js`'s handler
/// applies `PATCH` semantics (an omitted key leaves the column untouched),
/// and sending a same-value `password` would make the server rehash and
/// rewrite it for nothing.
///
/// **Field copy is quoted from §3.18 character for character**, including
/// the spec's own inconsistency: the field is labelled **"Full name"** but
/// its required-error reads **"First name is required"**. That mismatch is
/// the spec's, not a typo introduced here — see this repo's house rule on
/// quoting copy verbatim, and `specDeviations` in this task's report.
/// **Email** gets only the spec's one message ("Email is required" — i.e. a
/// presence check, no client-side format check); an actually-malformed
/// address is caught by the server's `z.string().email()` and surfaces
/// through the generic error toast instead, one round trip later than a
/// format check would have caught it, which is a deliberate reading of
/// "implement it as written," not an oversight.
///
/// **The avatar control is a real picker.** SCREENS.md says tapping it
/// opens a native picker and triggers `permissions-primer` if ungranted —
/// [AvatarUploadControl] (`shared/widgets/avatar_upload_control.dart`) is
/// that picker: `image_picker` raises its own OS permission prompt, so this
/// screen does **not** also go through `PermissionGateway`
/// (`features/permissions/`) — a second, app-level prompt on top of the
/// plugin's own would be a worse experience, and that gateway exists for
/// `permissions-primer`'s own explanatory surface, not for a control that
/// already has a real picker behind it. A denied permission, a cancelled
/// pick, an over-size file, and a failed upload each surface distinctly —
/// see [AvatarUploadControl]'s own doc comment.
///
/// **Discard confirmation** (SCREENS.md §5's "Modals with unsaved form
/// state ... show a discard-confirmation alert" — `edit-profile` is named
/// explicitly): both the header's back arrow/"Cancel" button and the
/// system back gesture funnel through the same check, comparing every
/// field's *current* value against what the form was seeded with. That
/// comparison is why "only when something actually changed" falls out for
/// free — a user who types something and then deletes it back to the
/// original value is, by this check, not dirty, and both exit paths pop
/// with no prompt. [PopScope.canPop] carries that same live boolean so the
/// system back gesture can't bypass the check the on-screen Cancel button
/// enforces.
///
/// **Both save toasts go through [LaCasaToast]** (this run's audit §10.4) —
/// §3.18's "Profile successfully updated!" as a success, "Error updating
/// profile: {message}" as an error, with the status glyph and the 2.5s/4s
/// budgets SCREENS.md §5 specifies. They used to be bare `SnackBar`s, which
/// inherit Material's docked dark-grey bar and no icon: a visibly different
/// component from the one the avatar-upload failures three lines away
/// already rendered, on the same screen, in the same second.
///
/// **The four fields carry no `autofillHints`**, unlike `login`/`register`'s
/// (§7.8) — not an oversight, a missing seam: this screen builds on
/// `shared/widgets/labelled_form_field.dart`'s [LabelledFormField], which
/// exposes no such parameter, and that file is owned outside this feature.
/// Reported rather than reached into; the change is one optional
/// `Iterable<String>? autofillHints` forwarded to its inner [TextField],
/// after which this form wants `name` / `telephoneNumber` / `[username,
/// email]` / `newPassword` and an [AutofillGroup] around [_FormBody], so a
/// password manager can capture a *changed* password the same way it now
/// captures a new one on `register`.
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
import '../../auth/state/auth_repository_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.branchPrefix = RoutePaths.profile});

  /// Fallback destination when this screen has nothing to pop (a deep
  /// link) — see the file doc comment.
  final String branchPrefix;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  /// Read once, in [initState], not watched — the form's own edits must
  /// never be clobbered by a rebuild, and the "what did this field start
  /// as" comparison [_hasChanges] needs a fixed baseline to diff against,
  /// not whatever `authSessionProvider` currently holds (which this very
  /// screen updates on a successful save).
  late final AuthUser? _initialUser;

  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();

  /// Seeded from [_initialUser.avatar]; reassigned once
  /// [AvatarUploadControl.onUploaded] fires. `null` renders the initials
  /// fallback, same as an unset avatar always has.
  String? _avatarUrl;

  bool _obscurePassword = true;
  bool _submitting = false;

  /// Tracks [AvatarUploadControl.onUploadStateChanged] — see that widget's
  /// own doc comment for the race this closes. Checked in [_submit] so a
  /// Save tapped before a pick finishes uploading is refused rather than
  /// silently going out on the stale [_avatarUrl].
  bool _avatarUploading = false;

  String? _fullNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _initialUser = ref.read(authSessionProvider).user;
    _fullName = TextEditingController(text: _initialUser?.fullName ?? '');
    _phone = TextEditingController(text: _initialUser?.phoneNumber ?? '');
    _email = TextEditingController(text: _initialUser?.email ?? '');
    _avatarUrl = _initialUser?.avatar;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Live "is there anything to lose" check — re-evaluated on every
  /// rebuild (each field's `onChanged` calls `setState`), never cached, so
  /// typing something and then deleting it back to the original value
  /// clears the dirty flag exactly like never having typed it.
  bool get _hasChanges {
    final user = _initialUser;
    if (user == null) return false;
    return _fullName.text.trim() != user.fullName ||
        _phone.text.trim() != (user.phoneNumber ?? '') ||
        _email.text.trim() != user.email ||
        _password.text.isNotEmpty ||
        _avatarUrl != user.avatar;
  }

  Future<bool> _confirmDiscard() async {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardLg),
        ),
        title: Text(
          l10n.editProfileDiscardDialogTitle,
          style: type.alertTitle.copyWith(color: colors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.editProfileDiscardDialogCancelButtonLabel,
              style: type.label.copyWith(color: colors.ink2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.editProfileDiscardDialogConfirmButtonLabel,
              style: type.label.copyWith(color: AppStatusColors.errorText),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  /// The header back arrow and the **"Cancel"** button both call this —
  /// they are the same exit, just two hit targets.
  Future<void> _handleCancel() async {
    if (_hasChanges) {
      final discard = await _confirmDiscard();
      if (!discard) return;
    }
    if (!mounted) return;
    _leave();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.branchPrefix);
    }
  }

  /// Validates every field (not just the first that fails) so a user
  /// fixing one mistake doesn't get surprised by a second one the next time
  /// they tap Save. Returns whether the form is submittable.
  bool _validate(AppLocalizations l10n) {
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _fullNameError = fullName.isEmpty
          ? l10n.editProfileFullNameRequiredError
          : null;
      // The spec gives phone exactly one message for both "empty" and
      // "wrong shape" — Formatters.isValidUzPhone('') is false anyway, so
      // this is one check, not two.
      _phoneError = Formatters.isValidUzPhone(phone)
          ? null
          : l10n.editProfilePhoneInvalidError;
      _emailError = email.isEmpty ? l10n.editProfileEmailRequiredError : null;
      // Only validated when the user is actually changing it — an empty
      // password field means "leave it alone," not "six characters short."
      _passwordError = password.isNotEmpty && password.length < 6
          ? l10n.editProfilePasswordLengthError
          : null;
    });

    return _fullNameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // Captured once, up front — this method crosses an `await`, and every
    // later use is after a `mounted` re-check, so the lookup is done while
    // `context` is unambiguously still attached (same reasoning
    // `login_screen.dart`'s `_submit` documents for its own `l10n`).
    final l10n = AppLocalizations.of(context);
    if (!_validate(l10n)) return;
    // A photo mid-upload has no settled URL yet — see
    // `AvatarUploadControl`'s doc comment and `listing_form_fields.dart`'s
    // `hasPendingUploads`, whose "block Save with a message" precedent this
    // mirrors rather than awaiting the upload inline.
    if (_avatarUploading) {
      LaCasaToast.showError(context, l10n.editProfileAvatarUploadingToast);
      return;
    }

    final user = _initialUser;
    if (user == null) return;

    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() => _submitting = true);

    try {
      final updated = await ref
          .read(authRepositoryProvider)
          .updateProfile(
            fullName: fullName != user.fullName ? fullName : null,
            phoneNumber: phone != (user.phoneNumber ?? '') ? phone : null,
            email: email != user.email ? email : null,
            avatar: _avatarUrl != user.avatar ? _avatarUrl : null,
            password: password.isEmpty ? null : password,
          );
      // Refreshes the session so `profile-buyer`/`profile-agent` (and
      // anything else reading `authSessionProvider`) show the new values
      // the moment this screen pops, with no separate refetch.
      ref.read(authSessionProvider.notifier).signIn(updated);

      if (!mounted) return;
      _leave();
      // LaCasaToast, not a bare SnackBar — see the file doc comment's §10.4
      // note. Same swap on the failure path below.
      LaCasaToast.showSuccess(context, l10n.editProfileUpdateSuccessToast);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(
        context,
        l10n.editProfileUpdateErrorToast(_messageFor(l10n, e)),
      );
    }
  }

  /// SCREENS.md's toast is a template — "Error updating profile:
  /// {message}" — and `{message}` is the server's own words wherever there
  /// are any: `emailTaken`'s "Email is already registered", a `validation`
  /// issue's zod message, an `unauthorized` session having gone stale
  /// mid-edit. Only a transport failure with no server response at all
  /// gets copy invented here, matching `contact_sheet.dart`'s identical
  /// call. Takes [AppLocalizations] as a parameter rather than a
  /// `BuildContext` — see `agent_review_sheet.dart`'s identically-shaped
  /// `_messageFor` for why.
  static String _messageFor(AppLocalizations l10n, ApiException e) {
    if (e is ApiErrorException) return e.message;
    if (e is NetworkException) {
      return l10n.editProfileNetworkErrorMessage;
    }
    return l10n.editProfileGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final user = _initialUser;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (discard && mounted) _leave();
      },
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavRow(
                title: AppLocalizations.of(context).editProfileScreenTitle,
                onBack: _handleCancel,
              ),
              Expanded(
                child: user == null
                    ? _SignedOutState(onGoBack: _leave)
                    : _FormBody(
                        fullName: _fullName,
                        phone: _phone,
                        email: _email,
                        password: _password,
                        obscurePassword: _obscurePassword,
                        onTogglePasswordVisibility: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        fullNameError: _fullNameError,
                        phoneError: _phoneError,
                        emailError: _emailError,
                        passwordError: _passwordError,
                        onFieldChanged: () => setState(() {}),
                        avatarUrl: _avatarUrl,
                        onAvatarUploaded: (url) =>
                            setState(() => _avatarUrl = url),
                        onAvatarError: (message) =>
                            LaCasaToast.showError(context, message),
                        onAvatarUploadStateChanged: (busy) =>
                            setState(() => _avatarUploading = busy),
                        submitting: _submitting,
                        onCancel: _handleCancel,
                        onSave: _submit,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A deep link straight into `edit-profile` with no signed-in session is
/// not a state SCREENS.md describes (this screen is only ever reached from
/// `profile-buyer`/`profile-agent`, both of which require a session to be
/// showing at all) — but it is reachable in principle, so it gets an honest
/// answer instead of a form bound to fields that don't exist.
class _SignedOutState extends StatelessWidget {
  const _SignedOutState({required this.onGoBack});

  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: FullWidthState(
        icon: Icons.lock_outline_rounded,
        message: AppLocalizations.of(context).editProfileSignedOutMessage,
        actionLabel: AppLocalizations.of(
          context,
        ).editProfileSignedOutGoBackLabel,
        onAction: onGoBack,
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.fullNameError,
    required this.phoneError,
    required this.emailError,
    required this.passwordError,
    required this.onFieldChanged,
    required this.avatarUrl,
    required this.onAvatarUploaded,
    required this.onAvatarError,
    required this.onAvatarUploadStateChanged,
    required this.submitting,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController fullName;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;

  final String? fullNameError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;

  /// Called on every keystroke purely to re-run [_EditProfileScreenState
  /// ._hasChanges] and repaint (`PopScope.canPop`, the Save button's
  /// enabled look) — no state lives in this widget itself.
  final VoidCallback onFieldChanged;

  final String? avatarUrl;
  final ValueChanged<String> onAvatarUploaded;
  final ValueChanged<String> onAvatarError;
  final ValueChanged<bool> onAvatarUploadStateChanged;

  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.base,
          AppSpacing.screenGutter,
          MediaQuery.of(context).padding.bottom + AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AvatarUploadControl(
                avatarUrl: avatarUrl,
                fullName: fullName.text,
                onUploaded: onAvatarUploaded,
                onError: onAvatarError,
                onUploadStateChanged: onAvatarUploadStateChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            LabelledFormField(
              label: AppLocalizations.of(context).editProfileFullNameFieldLabel,
              controller: fullName,
              errorText: fullNameError,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
              label: AppLocalizations.of(context).editProfilePhoneFieldLabel,
              controller: phone,
              errorText: phoneError,
              hintText: '+998901234567',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              ],
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
              label: AppLocalizations.of(context).editProfileEmailFieldLabel,
              controller: email,
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
              label: AppLocalizations.of(context).editProfilePasswordFieldLabel,
              controller: password,
              errorText: passwordError,
              helperText: AppLocalizations.of(
                context,
              ).editProfilePasswordHelper,
              hintText: AppLocalizations.of(context).editProfilePasswordHint,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onChanged: onFieldChanged,
              trailing: VisibilityToggle(
                obscured: obscurePassword,
                onTap: onTogglePasswordVisibility,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    label: AppLocalizations.of(
                      context,
                    ).editProfileCancelButtonLabel,
                    onTap: onCancel,
                  ),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: _PrimaryButton(
                    label: AppLocalizations.of(
                      context,
                    ).editProfileSaveButtonLabel,
                    submitting: submitting,
                    onTap: onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.submitting,
    required this.onTap,
  });

  final String label;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: submitting ? null : onTap,
        child: Opacity(
          opacity: submitting ? 0.6 : 1,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppAccent.gradient,
              borderRadius: BorderRadius.circular(AppRadii.pillButton),
              boxShadow: const [
                BoxShadow(
                  color: AppAccent.shadowColor,
                  blurRadius: 22,
                  spreadRadius: -8,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: type.rowTitle.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
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
        // `.btn btn--ghost glf` — flat glass with the source's hairline
        // rim and near-black label, not a solid grey fill.
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.pillButton),
          height: 52,
          alignment: Alignment.center,
          child: Text(label, style: type.rowTitle.copyWith(color: colors.ink)),
        ),
      ),
    );
  }
}
