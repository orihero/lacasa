/// `add-coworker` (SCREENS.md §37) — header "Create coworker", an avatar
/// uploader (default placeholder, per §5.2 always
/// [MediaUploadUnavailableNotice] in this build), and the create form.
///
/// **Field copy is quoted from §37 character for character**: "Full Name is
/// required", "Phone number is required" (empty) / "Invalid Uzbekistan
/// phone number" (wrong shape — two distinct messages here, unlike
/// `coworker_detail_screen.dart`'s single combined one, see that file's own
/// doc comment for why §36 only quotes one), "Email is required",
/// "Password is required" (empty) / "Password must be at least 6
/// characters" (too short).
///
/// **The two-error-string toast is deliberate, not a spec inconsistency to
/// resolve away.** §37 quotes a generic pending/error pair ("Uploading" /
/// "Something went wrong!") *and* a specific catch pair ("Error creating
/// coworker: {message}") — read as two different failure surfaces of one
/// flow: an avatar-upload step (this build's [MediaUploadUnavailableNotice]
/// seam, §5.2 — never reachable here since there is no picker to produce
/// bytes for [UploadsResource] in the first place) ahead of the real
/// `POST /coworkers` call. [_submit] keeps both branches in the code rather
/// than quietly dropping the unreachable one, so the day a real picker
/// lands, only the upload step itself needs filling in — see
/// [_uploadAvatarIfAny]'s own doc comment.
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

  bool _obscurePassword = true;
  bool _submitting = false;

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
      _password.text.isNotEmpty;

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
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? 'Full Name is required' : null;
      _phoneError = phone.isEmpty
          ? 'Phone number is required'
          : (Formatters.isValidUzPhone(phone)
                ? null
                : 'Invalid Uzbekistan phone number');
      _emailError = email.isEmpty ? 'Email is required' : null;
      _passwordError = password.isEmpty
          ? 'Password is required'
          : (password.length < 6
                ? 'Password must be at least 6 characters'
                : null);
    });

    return _fullNameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  /// This build's honest empty half of the upload step §37's "Uploading" /
  /// "Something went wrong!" toast pair implies — see the file doc comment.
  /// There is no picker anywhere in this build (§5.2) that could ever hand
  /// this a byte to upload, so this always returns `null` (no avatar) and
  /// never throws; kept as its own method, rather than inlined away, so the
  /// day a real picker lands this is the one place that starts doing
  /// something.
  Future<String?> _uploadAvatarIfAny() async => null;

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

    setState(() => _submitting = true);
    LaCasaToast.showPending(context, 'Uploading');

    try {
      final avatar = await _uploadAvatarIfAny();
      await ref
          .read(coworkersRepositoryProvider)
          .create(
            fullName: _fullName.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            phoneNumber: _phone.text.trim(),
            avatar: avatar,
          );
      ref.invalidate(coworkersListProvider);
      // Dashboard owns an independent copy of this same list
      // (`dashboardCoworkersProvider`) and stays mounted for the whole
      // Work-tab session — without this its "Coworkers" tile and
      // "Workspace" subtitle would silently keep showing the pre-create
      // count.
      ref.invalidate(dashboardCoworkersProvider);

      if (!mounted) return;
      LaCasaToast.showSuccess(context, 'Coworker successfully created');
      _leaveToCoworkersList();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(context, 'Error creating coworker: ${_messageFor(e)}');
    }
  }

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
    final session = ref.watch(authSessionProvider);

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
              NavRow(title: 'Create coworker', onBack: _handleCancel),
              Expanded(child: _bodyFor(session)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bodyFor(AuthSessionState session) {
    if (!session.isSignedIn) {
      return _BlockedState(
        message: 'Sign in to manage your team.',
        actionLabel: 'Sign In',
        onAction: () => context.push(RoutePaths.login),
      );
    }
    if (session.role != UserRole.agent) {
      return _BlockedState(
        message: 'Only agents can add coworkers.',
        actionLabel: 'Go back',
        onAction: _leaveToCoworkersList,
      );
    }
    if (session.user?.realtor?.kind == RealtorKind.solo) {
      return _BlockedState(
        // The API's own literal copy — `apps/api/src/routes/coworkers.js`'s
        // `solo_realtor` error message — rather than an invented paraphrase,
        // shown pre-emptively instead of only after a submit round-trip.
        message:
            "Solo agents don't have a team. Switch to an agency account "
            'to add coworkers.',
        actionLabel: 'Go back',
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
            const Center(child: _AvatarPlaceholder()),
            const SizedBox(height: AppSpacing.section),
            LabelledFormField(
              label: 'Full name',
              controller: fullName,
              errorText: fullNameError,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
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
            LabelledFormField(
              label: 'Email',
              controller: email,
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: onFieldChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            LabelledFormField(
              label: 'Password',
              controller: password,
              errorText: passwordError,
              hintText: 'At least 6 characters',
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

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Add photo — $kMediaUploadUnavailableMessage',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                showMediaUploadUnavailableToast(context, label: 'Avatar upload'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const AgentAvatar(avatarUrl: null, fullName: '', size: 84),
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
        const MediaUploadUnavailableNotice(label: 'Avatar upload'),
      ],
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
