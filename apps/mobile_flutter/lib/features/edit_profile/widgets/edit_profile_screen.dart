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
/// **The avatar control cannot open a picker in this build.** SCREENS.md
/// says tapping it opens a native picker and triggers `permissions-primer`
/// if ungranted; there is no `image_picker` dependency here (this task may
/// not add one) and `features/permissions/data/permission_gateway.dart`'s
/// [UnavailablePermissionGateway] is the documented reason nothing behind a
/// real OS permission works yet. Rather than push `permissions-primer` —
/// which exists to explain *why an OS prompt is about to appear* and would
/// dead-end here with no prompt to show and no picker waiting on the other
/// side of "Continue" — the avatar tap goes straight through the same
/// [PermissionGateway] seam that screen uses, gets back
/// [PermissionOutcome.unavailable] (the only outcome this build can ever
/// produce), and says so plainly: a caption under the avatar always reads
/// "Photo upload isn't available in this build yet," and the tap surfaces
/// the identical sentence as a toast so a user who taps expecting something
/// to happen gets an honest answer rather than silence. When photo upload
/// gets a real implementation (this file's avatar section, plus a real
/// [PermissionGateway] and an upload endpoint), this is the one place that
/// changes.
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
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../auth/state/auth_repository_provider.dart';
import '../../permissions/permissions.dart';

/// The one sentence this build can honestly say about the avatar control —
/// see this file's doc comment. Shared by the always-visible caption and
/// the tap-triggered toast so the two never drift apart.
const String _avatarUnavailableMessage =
    "Photo upload isn't available in this build yet.";

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

  bool _obscurePassword = true;
  bool _submitting = false;

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
        _password.text.isNotEmpty;
  }

  Future<bool> _confirmDiscard() async {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.cardLg),
        ),
        title: Text(
          'Discard changes?',
          style: type.alertTitle.copyWith(color: colors.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: type.label.copyWith(color: colors.ink2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Discard',
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

  Future<void> _requestAvatarChange() async {
    // Always resolves to `unavailable` in this build — see the file doc
    // comment. Routed through the real gateway seam (rather than a literal
    // `unavailable` short-circuit here) so the day a real
    // `PermissionGateway` is wired up, this call starts doing something
    // without this screen changing at all.
    await ref.read(permissionGatewayProvider).request(AppPermission.cameraAndPhotos);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_avatarUnavailableMessage)),
    );
  }

  /// Validates every field (not just the first that fails) so a user
  /// fixing one mistake doesn't get surprised by a second one the next time
  /// they tap Save. Returns whether the form is submittable.
  bool _validate() {
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? 'First name is required' : null;
      // The spec gives phone exactly one message for both "empty" and
      // "wrong shape" — Formatters.isValidUzPhone('') is false anyway, so
      // this is one check, not two.
      _phoneError = Formatters.isValidUzPhone(phone)
          ? null
          : 'Invalid Uzbekistan phone number';
      _emailError = email.isEmpty ? 'Email is required' : null;
      // Only validated when the user is actually changing it — an empty
      // password field means "leave it alone," not "six characters short."
      _passwordError = password.isNotEmpty && password.length < 6
          ? 'Password must be at least 6 characters'
          : null;
    });

    return _fullNameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

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
            password: password.isEmpty ? null : password,
          );
      // Refreshes the session so `profile-buyer`/`profile-agent` (and
      // anything else reading `authSessionProvider`) show the new values
      // the moment this screen pops, with no separate refetch.
      ref.read(authSessionProvider.notifier).signIn(updated);

      if (!mounted) return;
      _leave();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile successfully updated!')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${_messageFor(e)}')),
      );
    }
  }

  /// SCREENS.md's toast is a template — "Error updating profile:
  /// {message}" — and `{message}` is the server's own words wherever there
  /// are any: `emailTaken`'s "Email is already registered", a `validation`
  /// issue's zod message, an `unauthorized` session having gone stale
  /// mid-edit. Only a transport failure with no server response at all
  /// gets copy invented here, matching `contact_sheet.dart`'s identical
  /// call.
  static String _messageFor(ApiException e) {
    if (e is ApiErrorException) return e.message;
    if (e is NetworkException) {
      return 'No connection. Check your network and try again.';
    }
    return 'Something went wrong';
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
              _NavRow(onBack: _handleCancel),
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
                        avatarUrl: user.avatar,
                        onAvatarTap: _requestAvatarChange,
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
        message: 'Sign in to edit your profile.',
        actionLabel: 'Go back',
        onAction: onGoBack,
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

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
            label: 'Back',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Edit Profile',
              overflow: TextOverflow.ellipsis,
              style: type.navTitle.copyWith(color: colors.ink),
            ),
          ),
        ],
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
    required this.onAvatarTap,
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
  final VoidCallback onAvatarTap;

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
              child: _AvatarUploader(
                avatarUrl: avatarUrl,
                fullName: fullName.text,
                onTap: onAvatarTap,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            _FormField(
              label: 'Full name',
              controller: fullName,
              errorText: fullNameError,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormField(
              label: 'Phone',
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
            _FormField(
              label: 'Email',
              controller: email,
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            _FormField(
              label: 'Password',
              controller: password,
              errorText: passwordError,
              hintText: 'Leave blank to keep your current password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onChanged: onFieldChanged,
              trailing: _VisibilityToggle(
                obscured: obscurePassword,
                onTap: onTogglePasswordVisibility,
              ),
            ),
            const SizedBox(height: AppSpacing.section),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(label: 'Cancel', onTap: onCancel),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: _PrimaryButton(
                    label: 'Save',
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

class _AvatarUploader extends StatelessWidget {
  const _AvatarUploader({
    required this.avatarUrl,
    required this.fullName,
    required this.onTap,
  });

  final String? avatarUrl;
  final String fullName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Change photo — $_avatarUnavailableMessage',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AgentAvatar(avatarUrl: avatarUrl, fullName: fullName, size: 84),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.sunk,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.screen, width: 2),
                    ),
                    // Muted, not accent-colored: this badge cannot start a
                    // real upload in this build, and an accent-colored
                    // control implies otherwise — see the file doc comment.
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: 14,
                      color: colors.faint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _avatarUnavailableMessage,
          textAlign: TextAlign.center,
          style: type.bodySmall.copyWith(color: colors.faint),
        ),
      ],
    );
  }
}

/// A labelled input on the `.glf` flat-glass material, matching
/// `contact_sheet.dart`'s `_Field` — extended with a per-field [errorText]
/// line (§3.18 gives each field its own message, unlike `contact-sheet`'s
/// single form-level error) and an optional [trailing] widget (the
/// password show/hide toggle).
class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.inputFormatters,
    this.trailing,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  inputFormatters: inputFormatters,
                  onChanged: (_) => onChanged(),
                  style: type.body.copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: type.body.copyWith(color: colors.faint),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppStatusColors.errorText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  errorText!,
                  style: type.bodySmall.copyWith(
                    color: AppStatusColors.errorText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: obscured ? 'Show password' : 'Hide password',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: colors.muted,
          ),
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
