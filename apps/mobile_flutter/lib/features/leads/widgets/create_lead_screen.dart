/// `create-lead` (SCREENS.md §33) — header "Create Lead", back arrow,
/// pushed from `leads-list`/`leads-kanban`'s "+ Add new lead". Builds the
/// full spec field set (Full name, Phone, Email, Budget, Commit, Status,
/// Source, Coworker) rather than console's reduced 4-field create modal —
/// same "build the spec's full set" reasoning as contract ruling 7.4 gives
/// for `create-listing`, applied here to leads' own create form.
///
/// **Copy quoted verbatim from §33**: "Full name (required 'First name is
/// required')" and "Phone (required 'Phone number is required', pattern,
/// error 'Invalid Uzbekistan phone number')" — the same spec-vs-label
/// mismatch `edit_profile_screen.dart` documents and preserves rather than
/// silently correcting.
///
/// **"Cancel → leads-list"** is §33's own literal instruction, not this
/// screen's own choice of "just go back" — so both the header back arrow
/// and the Cancel button funnel to the same fixed destination
/// ([RoutePaths.workLeads]) rather than a natural pop, regardless of
/// whether this screen was reached from `leads-list` or `leads-kanban`.
///
/// **Discard confirmation**: SCREENS.md §5 names `create-lead` explicitly
/// among the screens that must confirm before dismissing unsaved changes —
/// same [PopScope]/[confirmDiscardChanges] shape as
/// `edit_profile_screen.dart`.
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
import '../state/leads_providers.dart';
import 'lead_form_controls.dart';

class CreateLeadScreen extends ConsumerStatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  ConsumerState<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends ConsumerState<CreateLeadScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _budget = TextEditingController();
  final _commit = TextEditingController();
  final _source = TextEditingController();
  LeadStatus _status = LeadStatus.newLead;

  bool _submitting = false;
  String? _fullNameError;
  String? _phoneError;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _budget.dispose();
    _commit.dispose();
    _source.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _fullName.text.isNotEmpty ||
      _phone.text.isNotEmpty ||
      _email.text.isNotEmpty ||
      _budget.text.isNotEmpty ||
      _commit.text.isNotEmpty ||
      _source.text.isNotEmpty ||
      _status != LeadStatus.newLead;

  Future<bool> _confirmDiscard() => confirmDiscardChanges(context);

  Future<void> _handleCancel() async {
    if (_hasChanges) {
      final discard = await _confirmDiscard();
      if (!discard) return;
    }
    if (!mounted) return;
    context.go(RoutePaths.workLeads);
  }

  bool _validate() {
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    setState(() {
      _fullNameError = fullName.isEmpty ? 'First name is required' : null;
      _phoneError = phone.isEmpty
          ? 'Phone number is required'
          : (Formatters.isValidUzPhone(phone) ? null : 'Invalid Uzbekistan phone number');
    });
    return _fullNameError == null && _phoneError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

    final budgetText = _budget.text.trim();
    final email = _email.text.trim();
    final commit = _commit.text.trim();
    final source = _source.text.trim();

    setState(() => _submitting = true);
    try {
      await ref.read(leadsProvider.notifier).createLead(
        LeadWriteInput(
          fullName: OptionalField(_fullName.text.trim()),
          phone: OptionalField(_phone.text.trim()),
          email: email.isEmpty ? null : OptionalField(email),
          budget: budgetText.isEmpty ? null : OptionalField(double.tryParse(budgetText)),
          comment: commit.isEmpty ? null : OptionalField(commit),
          status: OptionalField(_status),
          source: source.isEmpty ? null : OptionalField(source),
        ),
      );
      if (!mounted) return;
      context.go(RoutePaths.workLeads);
      LaCasaToast.showSuccess(context, 'Lead successfully created!');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(context, 'Error creating lead: ${_messageFor(e)}');
    }
  }

  static String _messageFor(ApiException e) {
    if (e is ApiErrorException) return e.message;
    if (e is NetworkException) {
      return 'No connection. Check your network and try again.';
    }
    return 'Something went wrong.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final isAgent = ref.watch(
      authSessionProvider.select((s) => s.role == UserRole.agent),
    );

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscard();
        if (!discard || !context.mounted) return;
        context.go(RoutePaths.workLeads);
      },
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NavRow(title: 'Create Lead', onBack: _handleCancel),
              Expanded(
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
                        LeadTextField(
                          label: 'Full name',
                          controller: _fullName,
                          errorText: _fullNameError,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadTextField(
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
                        LeadTextField(
                          label: 'Email',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadTextField(
                          label: 'Budget',
                          controller: _budget,
                          hintText: '50000',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadTextField(
                          label: 'Commit',
                          controller: _commit,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          hintText: 'What is this lead looking for?',
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadStatusField(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadTextField(
                          label: 'Source',
                          controller: _source,
                          textInputAction: TextInputAction.done,
                          onChanged: () => setState(() {}),
                        ),
                        if (isAgent) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const LeadCoworkerField(coworkerName: null),
                        ],
                        const SizedBox(height: AppSpacing.section),
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

    return GestureDetector(
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
              : Text(label, style: type.rowTitle.copyWith(color: Colors.white)),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.sunk, borderRadius: BorderRadius.circular(AppRadii.pillButton)),
        child: Text(label, style: type.rowTitle.copyWith(color: colors.ink2)),
      ),
    );
  }
}
