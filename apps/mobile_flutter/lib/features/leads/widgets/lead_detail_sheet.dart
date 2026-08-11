/// `lead-detail` (SCREENS.md §32) — the **one** cross-feature dependency in
/// this build that isn't a route (contract §3.4): `leads-list`,
/// `leads-kanban` (both this feature's own screens) and `work_misc`'s
/// `NotificationsScreen` all call [showLeadDetailSheet] directly, importing
/// `package:lacasa_mobile/features/leads/leads.dart`. The signature below
/// is fixed by contract §3.4 — do not change it without re-checking every
/// caller.
///
/// **No discard-confirmation on close.** SCREENS.md §5's discard-confirm
/// list names six *pushed/modal* screens explicitly and does not include
/// `lead-detail` — a *sheet* per §1's own bucketing, same as `contact-sheet`
/// (which also closes without confirming). Close "X"/swipe-down/Cancel all
/// dismiss immediately here, matching that precedent rather than inventing
/// a rule SCREENS.md never states for this screen.
///
/// **Delete is AGENT-only, and this screen says so by omission, not by
/// disabled button.** `LeadsResource.delete`/`CoworkersResource.delete`-style
/// server rule: a COWORKER session's `DELETE /leads/:id` 403s. Rather than
/// show a Delete button that would fail for a coworker, this screen hides
/// it entirely for a non-agent session — the same honest-omission choice
/// `FavouriteButton` makes for an agent viewing a buyer-only control, just
/// mirrored.
///
/// **The "Coworker" field is real-but-inert** — see
/// `lead_form_controls.dart#LeadCoworkerField`'s doc comment: it resolves
/// and displays [Lead.coworkerId] (a real field) but cannot write a new
/// selection, because `LeadWriteInput` carries no `coworkerId` at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/leads_providers.dart';
import 'lead_form_controls.dart';

/// Opens the sheet for [leadId] — see contract §3.4 for the exact,
/// fixed signature every caller (including `work_misc`'s
/// `NotificationsScreen`) depends on.
Future<void> showLeadDetailSheet(BuildContext context, {required String leadId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => _LeadDetailSheet(leadId: leadId),
  );
}

class _LeadDetailSheet extends ConsumerWidget {
  const _LeadDetailSheet({required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadByIdProvider(leadId));
    final l10n = AppLocalizations.of(context);

    return leadAsync.when(
      loading: () => const _StatusSheet(child: CircularProgressIndicator()),
      error: (error, _) => _StatusSheet(
        child: FullWidthState(
          icon: Icons.error_outline_rounded,
          message: l10n.leadsDetailLoadErrorMessage,
          actionLabel: l10n.sharedRetryLabel,
          onAction: () => ref.invalidate(leadByIdProvider(leadId)),
        ),
      ),
      data: (lead) => _LeadDetailForm(lead: lead),
    );
  }
}

/// A fixed-height sheet shell for the loading/error states — the form
/// itself (once loaded) sizes to its content instead.
class _StatusSheet extends StatelessWidget {
  const _StatusSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          _GrabHandle(colors: colors),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle({required this.colors});

  final LaCasaColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(color: colors.line, borderRadius: AppRadii.pill),
    );
  }
}

class _LeadDetailForm extends ConsumerStatefulWidget {
  const _LeadDetailForm({required this.lead});

  final Lead lead;

  @override
  ConsumerState<_LeadDetailForm> createState() => _LeadDetailFormState();
}

class _LeadDetailFormState extends ConsumerState<_LeadDetailForm> {
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _budget;
  late final TextEditingController _commit;
  late final TextEditingController _source;
  late LeadStatus _status;
  DateTime? _callbackDate;

  bool _submitting = false;
  bool _deleting = false;

  String? _fullNameError;
  String? _phoneError;
  String? _budgetError;

  @override
  void initState() {
    super.initState();
    final lead = widget.lead;
    _fullName = TextEditingController(text: lead.fullName);
    _phone = TextEditingController(text: lead.phone ?? '');
    _email = TextEditingController(text: lead.email ?? '');
    _budget = TextEditingController(
      text: lead.budget == null ? '' : Formatters.trimNum(lead.budget!),
    );
    _commit = TextEditingController(text: lead.comment ?? '');
    _source = TextEditingController(text: lead.source ?? '');
    _status = lead.status == LeadStatus.unknown ? LeadStatus.newLead : lead.status;
    _callbackDate = lead.callbackDate;
  }

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

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    final fullName = _fullName.text.trim();
    final phone = _phone.text.trim();
    final budgetText = _budget.text.trim();
    setState(() {
      _fullNameError = fullName.isEmpty ? l10n.leadsDetailFullNameRequiredError : null;
      _phoneError = phone.isEmpty || Formatters.isValidUzPhone(phone)
          ? null
          : l10n.leadsPhoneInvalidError;
      _budgetError = budgetText.isEmpty || double.tryParse(budgetText) != null
          ? null
          : l10n.leadsBudgetInvalidError;
    });
    return _fullNameError == null && _phoneError == null && _budgetError == null;
  }

  Future<void> _save() async {
    if (_submitting || _deleting) return;
    if (!_validate()) return;

    final phone = _phone.text.trim();
    final email = _email.text.trim();
    final budgetText = _budget.text.trim();
    final commit = _commit.text.trim();
    final source = _source.text.trim();

    setState(() => _submitting = true);
    try {
      await ref.read(leadsProvider.notifier).updateLead(
        widget.lead.id,
        LeadWriteInput(
          fullName: OptionalField(_fullName.text.trim()),
          phone: OptionalField(phone),
          email: OptionalField(email.isEmpty ? null : email),
          budget: OptionalField(budgetText.isEmpty ? null : double.tryParse(budgetText)),
          comment: OptionalField(commit.isEmpty ? null : commit),
          status: OptionalField(_status),
          source: OptionalField(source.isEmpty ? null : source),
          // Only meaningful for `need_to_call_back` — cleared when the
          // status is anything else, so a stale reminder doesn't linger on
          // a lead that has since moved on.
          callbackDate: OptionalField(
            _status == LeadStatus.needToCallBack ? _callbackDate : null,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      LaCasaToast.showSuccess(context, AppLocalizations.of(context).leadsUpdatedToastMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      LaCasaToast.showError(
        context,
        AppLocalizations.of(context).leadsUpdateErrorToastMessage(_messageFor(context, e)),
      );
    }
  }

  Future<void> _delete() async {
    if (_submitting || _deleting) return;
    final confirmed = await confirmDelete(
      context,
      subject: AppLocalizations.of(context).leadsSubjectNoun,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(leadsProvider.notifier).deleteLead(widget.lead.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      LaCasaToast.showSuccess(context, AppLocalizations.of(context).leadsDeletedToastMessage);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      LaCasaToast.showError(
        context,
        AppLocalizations.of(context).leadsDeleteErrorToastMessage(_messageFor(context, e)),
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

  Future<void> _pickCallbackDate() async {
    final picked = await pickLeadDateTime(context, initial: _callbackDate);
    if (picked == null || !mounted) return;
    setState(() => _callbackDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isAgent = ref.watch(
      authSessionProvider.select((s) => s.role == UserRole.agent),
    );
    final coworkerName = ref
        .watch(leadCoworkersProvider)
        .maybeWhen(
          data: (coworkers) => coworkers
              .where((c) => c.id == widget.lead.coworkerId)
              .firstOrNull
              ?.fullName,
          orElse: () => null,
        );
    final busy = _submitting || _deleting;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.base,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GrabHandle(colors: colors),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.lead.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: type.sheetTitle.copyWith(color: colors.ink),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: l10n.leadsDetailCloseLabel,
                    child: GestureDetector(
                      key: const ValueKey('leadDetail-close'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close_rounded, size: 20, color: colors.ink2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.section),
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
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                ],
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LeadTextField(
                label: l10n.leadsFieldEmailLabel,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LeadTextField(
                label: l10n.leadsFieldBudgetLabel,
                controller: _budget,
                errorText: _budgetError,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LeadTextField(
                label: l10n.leadsFieldCommitLabel,
                controller: _commit,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              LeadStatusField(
                value: _status,
                onChanged: (v) => setState(() => _status = v),
              ),
              if (_status == LeadStatus.needToCallBack) ...[
                const SizedBox(height: AppSpacing.lg),
                KeyedSubtree(
                  key: const ValueKey('leadDetail-callTime'),
                  child: LeadDateTimeField(value: _callbackDate, onTap: _pickCallbackDate),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              LeadTextField(
                label: l10n.leadsFieldSourceLabel,
                controller: _source,
                textInputAction: TextInputAction.done,
                onChanged: () => setState(() {}),
              ),
              if (isAgent) ...[
                const SizedBox(height: AppSpacing.lg),
                LeadCoworkerField(coworkerName: coworkerName),
              ],
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      key: const ValueKey('leadDetail-cancel'),
                      label: l10n.leadsCancelButtonLabel,
                      onTap: busy ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: _SheetButton(
                      key: const ValueKey('leadDetail-save'),
                      label: l10n.leadsSaveButtonLabel,
                      primary: true,
                      submitting: _submitting,
                      onTap: busy ? null : _save,
                    ),
                  ),
                ],
              ),
              if (isAgent) ...[
                const SizedBox(height: AppSpacing.base),
                Center(
                  child: GestureDetector(
                    key: const ValueKey('leadDetail-delete'),
                    onTap: busy ? null : _delete,
                    child: Opacity(
                      opacity: busy ? 0.5 : 1,
                      child: _deleting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppStatusColors.errorText,
                              ),
                            )
                          : Text(
                              l10n.leadsDeleteLeadButtonLabel,
                              style: type.label.copyWith(color: AppStatusColors.errorText),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.submitting = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: primary ? AppAccent.gradient : null,
            color: primary ? null : colors.sunk,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
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
                  style: type.rowTitle.copyWith(color: primary ? Colors.white : colors.ink2),
                ),
        ),
      ),
    );
  }
}
