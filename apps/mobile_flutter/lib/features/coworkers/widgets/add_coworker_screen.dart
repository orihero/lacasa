/// `add-coworker` (SCREENS.md §37) — header "Create coworker", a real
/// avatar uploader ([AvatarUploadControl]), and the create form.
///
/// **Field copy is quoted from §37 character for character**: "Full Name is
/// required", "Phone number is required" (empty) / "Invalid Uzbekistan
/// phone number" (wrong shape — two distinct messages here, unlike
/// `coworker_detail_screen.dart`'s single combined one, see that file's own
/// doc comment for why §36 only quotes one), "Email is required",
/// "Password is required" (empty) / "Password must be at least 6
/// characters" (too short).
///
/// **The avatar uploads eagerly, at pick-time — not deferred to Save.**
/// §37 quotes a generic pending/error pair ("Uploading" / "Something went
/// wrong!") that, read literally, describes an avatar-upload step happening
/// between tapping Save and the `POST /coworkers` call. [AvatarUploadControl]
/// instead uploads (with its own inline progress ring) the moment a photo is
/// picked, matching `edit-profile`/`coworker-detail`'s identical avatar
/// controls rather than inventing a third, deferred-upload shape just for
/// this screen — a failed avatar upload is then a distinct, immediately
/// visible failure the user can retry before ever reaching Save, rather
/// than one bundled into a generic "Something went wrong!" they'd see only
/// after filling in the whole form. §37's "Uploading" pending toast is kept
/// at Save time regardless — by then it accurately describes the
/// `POST /coworkers` call itself (which does upload the form's data), not a
/// dead avatar step; "Something went wrong!" never fires here for that
/// reason and would have described a state this screen can no longer
/// reach — see `_submit`.
///
/// **Gated on the exact same fact `coworkers-list` hides its own entry
/// point over** (WORK_TAB_CONTRACT.md: "check `AuthUser.realtor?.kind`...
/// to hide the '+ Add new coworker' affordance for a solo agent rather than
/// let this 403 surface as a surprise", extended here to the COWORKER-role
/// 403 the same endpoint has). This screen is still reachable directly
/// (`RoutePaths.workAddCoworker` is a real route, not conditionally
/// registered — `app_router.dart` is out of this task's ownership to make
/// conditional), so it re-checks the same condition on its own rather than
/// trusting that every caller remembered to hide its own button, and shows
/// a blocked state — using the API's own real copy for the solo case
/// (`apps/api/src/routes/coworkers.js`'s literal `solo_realtor` message) —
/// instead of letting a submit round-trip end in a surprise 403.
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
import '../../work_dashboard/state/dashboard_providers.dart';
import '../state/coworkers_providers.dart';
import '../state/coworkers_repository_provider.dart';

class AddCoworkerScreen extends ConsumerStatefulWidget {
  const AddCoworkerScreen({super.key});

  @override
  ConsumerState<AddCoworkerScreen> createState() => _AddCoworkerScreenState();
}

class _AddCoworkerScreenState extends ConsumerState<AddCoworkerScreen> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  /// Set once [AvatarUploadControl.onUploaded] fires — `null` (the default
  /// placeholder avatar) is a perfectly valid create-time value, per §37.
  String? _avatarUrl;

  bool _obscurePassword = true;
  bool _submitting = false;

  /// See `AvatarUploadControl.onUploadStateChanged`'s doc comment — checked
  /// in [_submit] so a Save tapped before a pick finishes uploading is
  /// refused rather than creating the coworker on a stale (or absent)
  /// `_avatarUrl`.
  bool _avatarUploading = false;

  String? _fullNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _fullName.text.trim().isNotEmpty ||
      _phone.text.trim().isNotEmpty ||
      _email.text.trim().isNotEmpty ||
      _password.text.isNotEmpty ||
      _avatarUrl != null;

  Future<void> _handleCancel() async {
    if (_hasChanges) {
      final discard = await confirmDiscardChanges(context);
      if (!discard) return;
    }
    if (!mounted) return;
    _leaveToCoworkersList();
  }

  void _leaveToCoworkersList() {
    // §37: "Cancel" → `coworkers-list`, unconditionally (unlike a bare
    // `pop`, matching the spec's explicit target rather than "wherever the
    // back stack happens to lead").
    context.go(RoutePaths.workCoworkers);
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? l10n.coworkersFullNameRequiredError : null;
      _phoneError = phone.isEmpty
          ? l10n.coworkersPhoneRequiredError
          : (Formatters.isValidUzPhone(phone)
                ? null
                : l10n.coworkersPhoneInvalidError);
      _emailError = email.isEmpty ? l10n.coworkersEmailRequiredError : null;
      _passwordError = password.isEmpty
          ? l10n.coworkersPasswordRequiredError
          : (password.length < 6
                ? l10n.coworkersPasswordTooShortError
                : null);
    });

    return _fullNameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;
    // A photo mid-upload has no settled URL yet — see
    // `AvatarUploadControl`'s doc comment and `listing_form_fields.dart`'s
    // `hasPendingUploads`, whose "block Save with a message" precedent this
    // mirrors rather than awaiting the upload inline.
    if (_avatarUploading) {
      LaCasaToast.showError(context, AppLocalizations.of(context).coworkersUploadWaitMessage);
      return;
    }

    setState(() => _submitting = true);
    // See the file doc comment: by the time Save is reachable, any avatar
    // upload already finished (or was never started) — this now describes
    // the create call itself, not a deferred avatar step.
    LaCasaToast.showPending(context, AppLocalizations.of(context).coworkersUploadingToastLabel);

    try {
      await ref
          .read(coworkersRepositoryProvider)
          .create(
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            phoneNumber: _phone.text.trim(),
            avatar: _avatarUrl,
          );
      ref.invalidate(coworkersListProvider);
      // Dashboard owns an independent copy of this same list
      // (`dashboardCoworkersProvider`) and stays mounted for the whole
      // Work-tab session — without this its "Coworkers" tile and
      // "Workspace" subtitle would silently keep showing the pre-create
      // count.
      ref.invalidate(dashboardCoworkersProvider);

      if (!mounted) return;
      LaCasaToast.showSuccess(context, AppLocalizations.of(context).coworkersCreatedToastMessage);
      _leaveToCoworkersList();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(
        context,
        AppLocalizations.of(context).coworkersCreateErrorToastMessage(_messageFor(context, e)),
      );
    }
  }

  static String _messageFor(BuildContext context, ApiException e) {
    if (e is ApiErrorException) return e.message;
    final l10n = AppLocalizations.of(context);
    if (e is NetworkException) {
      return l10n.coworkersNoConnectionMessage;
    }
    return l10n.coworkersGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final session = ref.watch(authSessionProvider);
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await confirmDiscardChanges(context);
        if (discard && mounted) _leaveToCoworkersList();
      },
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavRow(title: l10n.coworkersCreateScreenTitle, onBack: _handleCancel),
              Expanded(child: _bodyFor(l10n, session)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bodyFor(AppLocalizations l10n, AuthSessionState session) {
    if (!session.isSignedIn) {
      return _BlockedState(
        message: l10n.coworkersSignInPromptMessage,
        actionLabel: l10n.coworkersSignInActionLabel,
        onAction: () => context.push(RoutePaths.login),
      );
    }
    if (session.role != UserRole.agent) {
      return _BlockedState(
        message: l10n.coworkersAgentOnlyMessage,
        actionLabel: l10n.coworkersGoBackLabel,
        onAction: _leaveToCoworkersList,
      );
    }
    if (session.user?.realtor?.kind == RealtorKind.solo) {
      return _BlockedState(
        // The API's own literal copy — `apps/api/src/routes/coworkers.js`'s
        // `solo_realtor` error message — rather than an invented paraphrase,
        // shown pre-emptively instead of only after a submit round-trip.
        message: l10n.coworkersSoloAgentMessage,
        actionLabel: l10n.coworkersGoBackLabel,
        onAction: _leaveToCoworkersList,
      );
    }

    return _FormBody(
      fullName: _fullName,
      phone: _phone,
      email: _email,
      password: _password,
      obscurePassword: _obscurePassword,
      onTogglePasswordVisibility: () =>
          setState(() => _obscurePassword = !_obscurePassword),
      fullNameError: _fullNameError,
      phoneError: _phoneError,
      emailError: _emailError,
      passwordError: _passwordError,
      onFieldChanged: () => setState(() {}),
      avatarUrl: _avatarUrl,
      onAvatarUploaded: (url) => setState(() => _avatarUrl = url),
      onAvatarError: (message) => LaCasaToast.showError(context, message),
      onAvatarUploadStateChanged: (busy) => setState(() => _avatarUploading = busy),
      submitting: _submitting,
      onCancel: _handleCancel,
      onSave: _submit,
    );
  }
}

class _BlockedState extends StatelessWidget {
  const _BlockedState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: FullWidthState(
        icon: Icons.groups_outlined,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
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
    final l10n = AppLocalizations.of(context);
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
                semanticsLabel: l10n.coworkersAddPhotoLabel,
                onUploaded: onAvatarUploaded,
                onError: onAvatarError,
                onUploadStateChanged: onAvatarUploadStateChanged,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            LabelledFormField(
              label: l10n.coworkersFieldFullNameLabel,
              controller: fullName,
              errorText: fullNameError,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
              label: l10n.coworkersFieldPhoneLabel,
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
              label: l10n.coworkersFieldEmailLabel,
              controller: email,
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
              label: l10n.coworkersFieldPasswordLabel,
              controller: password,
              errorText: passwordError,
              hintText: l10n.coworkersPasswordHint,
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
                  child: _SecondaryButton(label: l10n.coworkersCancelButtonLabel, onTap: onCancel),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: _PrimaryButton(
                    label: l10n.coworkersSaveButtonLabel,
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
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
          ),
          child: Text(
            label,
            style: type.rowTitle.copyWith(color: colors.ink2),
          ),
        ),
      ),
    );
  }
}
