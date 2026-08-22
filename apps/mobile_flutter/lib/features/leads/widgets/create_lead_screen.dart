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
import '../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    setState(() {
      _fullNameError = fullName.isEmpty
          ? l10n.leadsCreateFullNameRequiredError
          : null;
      _phoneError = phone.isEmpty
          ? l10n.leadsCreatePhoneRequiredError
          : (Formatters.isValidUzPhone(phone)
                ? null
                : l10n.leadsPhoneInvalidError);
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
      await ref
          .read(leadsProvider.notifier)
          .createLead(
            LeadWriteInput(
              fullName: OptionalField(_fullName.text.trim()),
              phone: OptionalField(_phone.text.trim()),
              email: email.isEmpty ? null : OptionalField(email),
              budget: budgetText.isEmpty
                  ? null
                  : OptionalField(double.tryParse(budgetText)),
              comment: commit.isEmpty ? null : OptionalField(commit),
              status: OptionalField(_status),
              source: source.isEmpty ? null : OptionalField(source),
            ),
          );
      if (!mounted) return;
      context.go(RoutePaths.workLeads);
      LaCasaToast.showSuccess(
        context,
        AppLocalizations.of(context).leadsCreatedToastMessage,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(
        context,
        AppLocalizations.of(
          context,
        ).leadsCreateErrorToastMessage(_messageFor(context, e)),
      );
    }
  }

  static String _messageFor(BuildContext context, ApiException e) {
    if (e is ApiErrorException) return e.message;
    final l10n = AppLocalizations.of(context);
    if (e is NetworkException) {
      return l10n.leadsNoConnectionMessage;
    }
    return l10n.sharedGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final isAgent = ref.watch(
      authSessionProvider.select((s) => s.role == UserRole.agent),
    );
    final l10n = AppLocalizations.of(context);

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
              NavRow(title: l10n.leadsCreateScreenTitle, onBack: _handleCancel),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
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
                          label: l10n.leadsFieldFullNameLabel,
                          controller: _fullName,
                          errorText: _fullNameError,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadTextField(
                          label: l10n.leadsFieldPhoneLabel,
                          controller: _phone,
                          errorText: _phoneError,
                          hintText: '+998901234567',
                          hintLine: l10n.leadsPhoneFormatHint,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+]'),
                            ),
                          ],
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // `<div class="two">` — Email and Budget share one
                        // row (`.two{grid-template-columns:1fr 1fr;gap:11px}`),
                        // as do Source and Coworker below. Full name and
                        // Phone stay full width, per the mockup.
                        LeadFieldPair(
                          first: LeadTextField(
                            label: l10n.leadsFieldEmailLabel,
                            controller: _email,
                            hintText: l10n.leadsOptionalFieldHint,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: () => setState(() {}),
                          ),
                          second: LeadTextField(
                            label: l10n.leadsFieldBudgetLabel,
                            controller: _budget,
                            hintText: l10n.leadsOptionalFieldHint,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadTextField(
                          label: l10n.leadsFieldCommitLabel,
                          controller: _commit,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          hintText: l10n.leadsCreateCommitHint,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        LeadStatusField(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Source pairs with Coworker for an agent session;
                        // with no Coworker field to sit beside, it takes the
                        // full width rather than half a row next to a blank.
                        if (isAgent)
                          LeadFieldPair(
                            first: LeadTextField(
                              label: l10n.leadsFieldSourceLabel,
                              controller: _source,
                              textInputAction: TextInputAction.done,
                              onChanged: () => setState(() {}),
                            ),
                            second: const LeadCoworkerField(coworkerName: null),
                          )
                        else
                          LeadTextField(
                            label: l10n.leadsFieldSourceLabel,
                            controller: _source,
                            textInputAction: TextInputAction.done,
                            onChanged: () => setState(() {}),
                          ),
                        const SizedBox(height: AppSpacing.section),
                        Row(
                          children: [
                            Expanded(
                              child: _SecondaryButton(
                                label: l10n.leadsCancelButtonLabel,
                                onTap: _handleCancel,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PrimaryButton(
                                label: l10n.leadsSaveButtonLabel,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassSurface(
        variant: GlassVariant.flatForm,
        borderRadius: BorderRadius.circular(AppRadii.pillButton),
        height: 52,
        alignment: Alignment.center,
        child: Text(label, style: type.rowTitle.copyWith(color: colors.ink)),
      ),
    );
  }
}
