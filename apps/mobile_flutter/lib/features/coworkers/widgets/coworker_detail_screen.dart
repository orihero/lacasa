/// `coworker-detail` (SCREENS.md §36) — header "Update coworker", an avatar
/// uploader, the edit form, and Delete.
///
/// **Two-part composition, matching `agent_profile_screen.dart`'s own
/// split**: [CoworkerDetailScreen] itself only resolves
/// `coworkerDetailProvider(coworkerId)`'s loading/error/data states (an
/// unknown/foreign id is a permanent 404 — "Go back", no Retry — a
/// transport failure gets Retry, same distinction that screen's own doc
/// comment explains); the loaded [Coworker] is handed to [_CoworkerForm],
/// a stateful child that seeds its controllers once in `initState` from
/// that fixed snapshot — the identical "read once, diff against for
/// `PopScope`/dirty-check purposes" shape `edit_profile_screen.dart` uses,
/// now via the shared `confirmDiscardChanges` (`shared/shared.dart`)
/// instead of that screen's own pre-promotion private copy.
///
/// **Required-field copy**: §36 quotes only the phone error verbatim
/// ("Invalid Uzbekistan phone number") — Full name/Email's "(required)"
/// notes carry no quoted string of their own. Rather than invent unrelated
/// wording, this file reuses §37's exact strings for the same two fields
/// ("Full Name is required" / "Email is required") — the two coworker forms
/// almost certainly share one validation vocabulary in the real app (the
/// same way `apps/console`'s single `coworkerUpdateSchema`/
/// `coworkerCreateSchema` pair does), and §37 is the one place SCREENS.md
/// actually wrote the words down. Phone gets a **single** combined message
/// for both "empty" and "wrong shape" here (unlike §37's two), matching
/// `edit_profile_screen.dart`'s identical reading of an identically-shaped
/// spec gap: "the spec gives phone exactly one message... `isValidUzPhone
/// ('')` is false anyway, so this is one check, not two."
///
/// **Password is optional here** (§36: "optional on edit... min 6 if
/// provided") — an empty field means "leave the current password alone",
/// sent as an omitted [OptionalField], never as an explicit-clear.
///
/// **The "coworker viewing a sibling" case is real and read-only.**
/// `GET /coworkers/:id` allows it (`apps/api/src/routes/coworkers.js`:
/// "a coworker can list their siblings"); `PATCH`/`DELETE` do not
/// (AGENT-only, no exception). Save/Delete are replaced with a plain note
/// rather than hidden outright, so a coworker who opens this screen still
/// understands *why* there is nothing to press, not just that there isn't.
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

class CoworkerDetailScreen extends ConsumerWidget {
  const CoworkerDetailScreen({super.key, required this.coworkerId});

  final String coworkerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final coworker = ref.watch(coworkerDetailProvider(coworkerId));
    final canManage =
        ref.watch(authSessionProvider.select((s) => s.role)) == UserRole.agent;

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: AppLocalizations.of(context).coworkersDetailScreenTitle,
              onBack: () => _leave(context),
            ),
            Expanded(
              child: coworker.when(
                loading: () => const _FormSkeleton(),
                error: (error, stackTrace) =>
                    _ErrorState(error: error, coworkerId: coworkerId),
                data: (coworker) =>
                    _CoworkerForm(coworker: coworker, canManage: canManage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _leave(BuildContext context) {
    // Same reasoning as `agent_profile_screen.dart`'s: a deep link straight
    // into this screen has nothing to pop, and that is not an error — "up"
    // is just the roster rather than "back".
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.workCoworkers);
    }
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error, required this.coworkerId});

  final Object error;
  final String coworkerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notFound =
        error is ApiErrorException &&
        (error as ApiErrorException).code == ApiErrorCode.notFound;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: notFound
          ? FullWidthState(
              icon: Icons.person_off_outlined,
              message: l10n.coworkersNotFoundMessage,
              actionLabel: l10n.coworkersGoBackLabel,
              onAction: () => context.canPop()
                  ? context.pop()
                  : context.go(RoutePaths.workCoworkers),
            )
          : FullWidthState(
              icon: Icons.cloud_off_rounded,
              message: l10n.coworkersDetailLoadErrorMessage,
              actionLabel: l10n.sharedRetryLabel,
              onAction: () =>
                  ref.invalidate(coworkerDetailProvider(coworkerId)),
            ),
    );
  }
}

class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: ShimmerBox(
              width: 84,
              height: 84,
              borderRadius: AppRadii.pill,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          for (var i = 0; i < 3; i++) ...[
            ShimmerBox(
              height: 48,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _CoworkerForm extends ConsumerStatefulWidget {
  const _CoworkerForm({required this.coworker, required this.canManage});

  final Coworker coworker;
  final bool canManage;

  @override
  ConsumerState<_CoworkerForm> createState() => _CoworkerFormState();
}

class _CoworkerFormState extends ConsumerState<_CoworkerForm> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();

  /// Seeded from `widget.coworker.avatar`; reassigned once
  /// [AvatarUploadControl.onUploaded] fires — see that widget's own doc
  /// comment for the real pick/upload flow behind it.
  String? _avatarUrl;

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _deleting = false;

  /// See `AvatarUploadControl.onUploadStateChanged`'s doc comment — checked
  /// in [_submit] so a Save tapped before a pick finishes uploading is
  /// refused rather than saving the stale `_avatarUrl`. Only ever set when
  /// `widget.canManage` (the only case an [AvatarUploadControl] is even
  /// rendered below — see `build`).
  bool _avatarUploading = false;

  String? _fullNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.coworker.fullName);
    _phone = TextEditingController(text: widget.coworker.phoneNumber ?? '');
    _email = TextEditingController(text: widget.coworker.email);
    _avatarUrl = widget.coworker.avatar;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _fullName.text.trim() != widget.coworker.fullName ||
      _phone.text.trim() != (widget.coworker.phoneNumber ?? '') ||
      _email.text.trim() != widget.coworker.email ||
      _password.text.isNotEmpty ||
      _avatarUrl != widget.coworker.avatar;

  Future<void> _handleCancel() async {
    if (_hasChanges) {
      final discard = await confirmDiscardChanges(context);
      if (!discard) return;
    }
    if (!mounted) return;
    _leave();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.workCoworkers);
    }
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _fullNameError = fullName.isEmpty
          ? l10n.coworkersFullNameRequiredError
          : null;
      // §36 quotes one combined message for phone — see this file's doc
      // comment.
      _phoneError = Formatters.isValidUzPhone(phone)
          ? null
          : l10n.coworkersPhoneInvalidError;
      _emailError = email.isEmpty ? l10n.coworkersEmailRequiredError : null;
      _passwordError = password.isNotEmpty && password.length < 6
          ? l10n.coworkersPasswordTooShortError
          : null;
    });

    return _fullNameError == null &&
        _phoneError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  Future<void> _submit() async {
    if (_submitting || _deleting) return;
    if (!_validate()) return;
    // A photo mid-upload has no settled URL yet — see
    // `AvatarUploadControl`'s doc comment and `listing_form_fields.dart`'s
    // `hasPendingUploads`, whose "block Save with a message" precedent this
    // mirrors rather than awaiting the upload inline.
    if (_avatarUploading) {
      LaCasaToast.showError(
        context,
        AppLocalizations.of(context).coworkersUploadWaitMessage,
      );
      return;
    }

    final coworker = widget.coworker;
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() => _submitting = true);

    try {
      await ref
          .read(coworkersRepositoryProvider)
          .update(
            coworker.id,
            fullName: fullName != coworker.fullName
                ? OptionalField(fullName)
                : null,
            phoneNumber: phone != (coworker.phoneNumber ?? '')
                ? OptionalField(phone)
                : null,
            email: email != coworker.email ? OptionalField(email) : null,
            avatar: _avatarUrl != coworker.avatar
                ? OptionalField(_avatarUrl)
                : null,
            password: password.isEmpty ? null : OptionalField(password),
          );
      ref.invalidate(coworkersListProvider);
      ref.invalidate(coworkerDetailProvider(coworker.id));
      // See `add_coworker_screen.dart`'s identical invalidation for why
      // Dashboard's own copy needs this too.
      ref.invalidate(dashboardCoworkersProvider);

      if (!mounted) return;
      LaCasaToast.showSuccess(
        context,
        AppLocalizations.of(context).coworkersUpdatedToastMessage,
      );
      _leave();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(
        context,
        AppLocalizations.of(
          context,
        ).coworkersUpdateErrorToastMessage(_messageFor(context, e)),
      );
    }
  }

  Future<void> _delete() async {
    if (_submitting || _deleting) return;
    final confirmed = await confirmDelete(
      context,
      subject: AppLocalizations.of(context).coworkersSubjectNoun,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(coworkersRepositoryProvider).delete(widget.coworker.id);
      ref.invalidate(coworkersListProvider);
      ref.invalidate(dashboardCoworkersProvider);

      if (!mounted) return;
      LaCasaToast.showSuccess(
        context,
        AppLocalizations.of(context).coworkersDeletedToastMessage,
      );
      _leave();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      LaCasaToast.showError(
        context,
        AppLocalizations.of(
          context,
        ).coworkersDeleteErrorToastMessage(_messageFor(context, e)),
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
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await confirmDiscardChanges(context);
        if (discard && mounted) _leave();
      },
      child: ScrollConfiguration(
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
                // Only a managing (AGENT) session can ever persist a new
                // avatar (Save is hidden below for anyone else) — offering
                // a real upload control that can never be saved would let a
                // coworker spend a real upload on a picture that just gets
                // discarded, so a read-only session gets a plain, non-tappable
                // avatar instead.
                child: widget.canManage
                    ? AvatarUploadControl(
                        avatarUrl: _avatarUrl,
                        fullName: _fullName.text,
                        semanticsLabel: l10n.coworkersChangePhotoLabel,
                        onUploaded: (url) => setState(() => _avatarUrl = url),
                        onError: (message) =>
                            LaCasaToast.showError(context, message),
                        onUploadStateChanged: (busy) =>
                            setState(() => _avatarUploading = busy),
                      )
                    : AgentAvatar(
                        avatarUrl: _avatarUrl,
                        fullName: _fullName.text,
                        size: 84,
                      ),
              ),
              const SizedBox(height: AppSpacing.section),
              LabelledFormField(
                label: l10n.coworkersFieldFullNameLabel,
                controller: _fullName,
                errorText: _fullNameError,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabelledFormField(
                label: l10n.coworkersFieldPhoneLabel,
                controller: _phone,
                errorText: _phoneError,
                hintText: '+998901234567',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabelledFormField(
                label: l10n.coworkersFieldEmailLabel,
                controller: _email,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabelledFormField(
                label: l10n.coworkersFieldPasswordLabel,
                controller: _password,
                errorText: _passwordError,
                hintText: l10n.coworkersPasswordHintKeepCurrent,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: () => setState(() {}),
                trailing: VisibilityToggle(
                  obscured: _obscurePassword,
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              if (widget.canManage) ...[
                // `.btns{display:flex;gap:10px}` with `.btns .btn{flex:1}` —
                // Delete, Cancel and Save share one row at equal width.
                Row(
                  children: [
                    Expanded(
                      child: _DeleteButton(deleting: _deleting, onTap: _delete),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SecondaryButton(
                        label: l10n.coworkersCancelButtonLabel,
                        onTap: _handleCancel,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PrimaryButton(
                        label: l10n.coworkersSaveButtonLabel,
                        submitting: _submitting,
                        onTap: _submit,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                _SecondaryButton(
                  label: l10n.coworkersCancelButtonLabel,
                  onTap: _handleCancel,
                ),
                const SizedBox(height: AppSpacing.base),
                _ReadOnlyNote(message: l10n.coworkersReadOnlyNoteMessage),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: colors.faint),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            message,
            style: type.caption.copyWith(color: colors.faint),
          ),
        ),
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

/// `.btn--ghost glf` — `.btn--ghost` contributes only `color:var(--ink)`, so
/// the button's surface is the flat-form glass (white with a hairline rim),
/// not a grey fill.
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
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.pillButton),
          height: 52,
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: type.rowTitle.copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// `.btn--danger glf` — the same flat-form glass as Cancel under a thin pink
/// rim (`box-shadow:inset 0 0 0 1px rgba(224,53,95,.4)`) with a pink label;
/// no fill of its own.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.deleting, required this.onTap});

  final bool deleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final radius = BorderRadius.circular(AppRadii.pillButton);

    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('deleteCoworkerButton'),
        behavior: HitTestBehavior.opaque,
        onTap: deleting ? null : onTap,
        child: Opacity(
          opacity: deleting ? 0.6 : 1,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: AppStatusColors.errorText.withValues(alpha: 0.4),
              ),
            ),
            child: GlassSurface(
              variant: GlassVariant.flatForm,
              borderRadius: radius,
              height: 52,
              alignment: Alignment.center,
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppStatusColors.errorText,
                        ),
                      ),
                    )
                  : Text(
                      AppLocalizations.of(context).coworkersDeleteButtonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowTitle.copyWith(
                        color: AppStatusColors.errorText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
