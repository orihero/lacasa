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
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../work_dashboard/state/dashboard_providers.dart';
import '../state/coworker_metrics.dart';
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
        ref.watch(authSessionProvider.select((s) => s.role)) ==
        UserRole.agent;
    final adsAsync = ref.watch(coworkerAdsProvider);
    final activityAsync = ref.watch(coworkerActivityProvider);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(title: 'Update coworker', onBack: () => _leave(context)),
            Expanded(
              child: coworker.when(
                loading: () => const _FormSkeleton(),
                error: (error, stackTrace) =>
                    _ErrorState(error: error, coworkerId: coworkerId),
                data: (coworker) => _CoworkerForm(
                  coworker: coworker,
                  canManage: canManage,
                  adsAsync: adsAsync,
                  activityAsync: activityAsync,
                ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: notFound
          ? FullWidthState(
              icon: Icons.person_off_outlined,
              message: 'This coworker is no longer available.',
              actionLabel: 'Go back',
              onAction: () => context.canPop()
                  ? context.pop()
                  : context.go(RoutePaths.workCoworkers),
            )
          : FullWidthState(
              icon: Icons.cloud_off_rounded,
              message: "Couldn't load this coworker",
              actionLabel: 'Retry',
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
            child: ShimmerBox(width: 84, height: 84, borderRadius: AppRadii.pill),
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
  const _CoworkerForm({
    required this.coworker,
    required this.canManage,
    required this.adsAsync,
    required this.activityAsync,
  });

  final Coworker coworker;
  final bool canManage;

  /// Backs [coworkerListingsCount] — see `coworkers_repository.dart`'s doc
  /// comment and WORK_TAB_CONTRACT.md ruling 7.6. Independent of the
  /// coworker fetch itself, so a failed ads/activity fetch degrades only
  /// this read-only summary line, never the editable form beneath it.
  final AsyncValue<List<Ad>> adsAsync;

  /// Backs [coworkerLastActiveAt].
  final AsyncValue<List<ActivityEvent>> activityAsync;

  @override
  ConsumerState<_CoworkerForm> createState() => _CoworkerFormState();
}

class _CoworkerFormState extends ConsumerState<_CoworkerForm> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  final TextEditingController _password = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _deleting = false;

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
      _password.text.isNotEmpty;

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
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _fullNameError = fullName.isEmpty ? 'Full Name is required' : null;
      // §36 quotes one combined message for phone — see this file's doc
      // comment.
      _phoneError = Formatters.isValidUzPhone(phone)
          ? null
          : 'Invalid Uzbekistan phone number';
      _emailError = email.isEmpty ? 'Email is required' : null;
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
    if (_submitting || _deleting) return;
    if (!_validate()) return;

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
            password: password.isEmpty ? null : OptionalField(password),
          );
      ref.invalidate(coworkersListProvider);
      ref.invalidate(coworkerDetailProvider(coworker.id));
      // See `add_coworker_screen.dart`'s identical invalidation for why
      // Dashboard's own copy needs this too.
      ref.invalidate(dashboardCoworkersProvider);

      if (!mounted) return;
      LaCasaToast.showSuccess(context, 'Coworker successfully updated!');
      _leave();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(context, 'Error updating coworker: ${_messageFor(e)}');
    }
  }

  Future<void> _delete() async {
    if (_submitting || _deleting) return;
    final confirmed = await confirmDelete(context, subject: 'coworker');
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(coworkersRepositoryProvider).delete(widget.coworker.id);
      ref.invalidate(coworkersListProvider);
      ref.invalidate(dashboardCoworkersProvider);

      if (!mounted) return;
      LaCasaToast.showSuccess(context, 'Coworker successfully deleted!');
      _leave();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      LaCasaToast.showError(context, 'Error deleting coworker: ${_messageFor(e)}');
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
                child: _AvatarUploader(
                  avatarUrl: widget.coworker.avatar,
                  fullName: _fullName.text,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Center(
                child: _ActivitySummary(
                  coworkerId: widget.coworker.id,
                  adsAsync: widget.adsAsync,
                  activityAsync: widget.activityAsync,
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              LabelledFormField(
                label: 'Full name',
                controller: _fullName,
                errorText: _fullNameError,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabelledFormField(
                label: 'Phone',
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
                label: 'Email',
                controller: _email,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LabelledFormField(
                label: 'Password',
                controller: _password,
                errorText: _passwordError,
                hintText: 'Leave blank to keep the current password',
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
                Row(
                  children: [
                    Expanded(
                      child: _SecondaryButton(
                        label: 'Cancel',
                        onTap: _handleCancel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: _PrimaryButton(
                        label: 'Save',
                        submitting: _submitting,
                        onTap: _submit,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _DeleteButton(deleting: _deleting, onTap: _delete),
              ] else ...[
                _SecondaryButton(label: 'Cancel', onTap: _handleCancel),
                const SizedBox(height: AppSpacing.base),
                _ReadOnlyNote(
                  message: 'Only agents can edit or delete coworkers.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "{N} listings · Active {relative time}" — a read-only summary line, not
/// part of §36's form fields (that section names none), added on top of the
/// spec's literal field set to actually surface the two figures
/// WORK_TAB_CONTRACT.md ruling 7.6 asks screens to derive rather than
/// leaving `coworkerLastActiveAt` (`coworker_metrics.dart`) dead code with
/// no caller anywhere in this cluster. Renders "—" for a figure that could
/// not be determined (loading/error/no data), never a fabricated number —
/// same rule `coworkers_list_screen.dart`'s row trailing follows.
class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({
    required this.coworkerId,
    required this.adsAsync,
    required this.activityAsync,
  });

  final String coworkerId;
  final AsyncValue<List<Ad>> adsAsync;
  final AsyncValue<List<ActivityEvent>> activityAsync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final listingsLabel = adsAsync.when(
      data: (ads) {
        final count = coworkerListingsCount(coworkerId, ads);
        return '$count listing${count == 1 ? '' : 's'}';
      },
      loading: () => '…',
      error: (error, stackTrace) => '—',
    );

    final activeLabel = activityAsync.when(
      data: (events) {
        final latest = coworkerLastActiveAt(coworkerId, events);
        return latest == null ? '—' : coworkerActivityLabel(latest);
      },
      loading: () => '…',
      error: (error, stackTrace) => '—',
    );

    return Text(
      '$listingsLabel · Active $activeLabel',
      style: type.bodySmall.copyWith(color: colors.muted),
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
          child: Text(message, style: type.caption.copyWith(color: colors.faint)),
        ),
      ],
    );
  }
}

class _AvatarUploader extends StatelessWidget {
  const _AvatarUploader({required this.avatarUrl, required this.fullName});

  final String? avatarUrl;
  final String fullName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Change photo — $kMediaUploadUnavailableMessage',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                showMediaUploadUnavailableToast(context, label: 'Avatar upload'),
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

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.deleting, required this.onTap});

  final bool deleting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('deleteCoworkerButton'),
        behavior: HitTestBehavior.opaque,
        onTap: deleting ? null : onTap,
        child: Opacity(
          opacity: deleting ? 0.6 : 1,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppStatusColors.dangerIconBg,
              borderRadius: BorderRadius.circular(AppRadii.pillButton),
            ),
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
                    'Delete',
                    style: type.rowTitle.copyWith(
                      color: AppStatusColors.errorText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
