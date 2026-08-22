/// Shared field primitives for `create-lead` (§33) and `lead-detail` (§32)
/// — the two full lead forms in this feature, which share most of their
/// field set (Full name, Phone, Email, Budget, Commit, Status, Source,
/// Coworker). Pulled out once a second screen needed the identical shapes,
/// matching `contact_sheet.dart`/`edit_profile_screen.dart`'s own labelled-
/// field look (`GlassVariant.flatForm`) rather than inventing a third.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

/// Two-step date-then-time picker shared by `kanban-move-sheet`'s "Call
/// time" field and `lead-detail`'s conditional "Call time" field — built on
/// plain Flutter `showDatePicker`/`showTimePicker` (no new dependency, see
/// `WORK_TAB_CONTRACT.md` §5). Returns `null` if the user backs out of
/// either step.
///
/// **[initial] is converted to local time before it seeds either picker.**
/// `lead-detail` passes `Lead.callbackDate` straight through, and that field
/// is decoded by `DateTime.tryParse` from a `Z`-suffixed ISO string — so it
/// carries the UTC flag, and `showDatePicker`/`TimeOfDay.fromDateTime` read
/// *UTC* calendar and clock fields off it. Re-opening a 09:00 Tashkent
/// (UTC+5) call-back would have offered 04:00 as its starting point, and a
/// pre-05:00 one would have opened on the previous day. `.toLocal()` on an
/// already-local value (the picker's own previous result, `kanban-move-
/// sheet`'s `_callTime`) is a no-op, so this is safe for every caller.
Future<DateTime?> pickLeadDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final seed = initial?.toLocal() ?? now;
  final date = await showDatePicker(
    context: context,
    initialDate: seed,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 2),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(seed),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// `<div class="two">` — two `.field`s side by side at equal width
/// (`.two{grid-template-columns:1fr 1fr;gap:11px}`), tops aligned so an error
/// or hint line under one half doesn't shift the other. Used by `lead-detail`
/// and `create-lead`, which both pair Email+Budget and Source+Coworker.
class LeadFieldPair extends StatelessWidget {
  const LeadFieldPair({super.key, required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 11),
        Expanded(child: second),
      ],
    );
  }
}

/// `.sh__h .rnd` — the filled 34px close circle every bottom sheet in the
/// mockup carries at the top-right of its title row. Shared by `lead-detail`,
/// `kanban-move-sheet` and the "Move to…" sheet rather than copied three
/// times.
class LeadSheetCloseButton extends StatelessWidget {
  const LeadSheetCloseButton({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.sunk, shape: BoxShape.circle),
          child: Icon(Icons.close_rounded, size: 16, color: colors.ink),
        ),
      ),
    );
  }
}

/// The select-shaped "Call time" tap target both callers of
/// [pickLeadDateTime] render around it.
///
/// [value] is rendered `.toLocal()` for the same reason [pickLeadDateTime]
/// seeds itself that way — see that function's doc comment: `lead-detail`'s
/// value can arrive straight off `Lead.callbackDate`, which carries the UTC
/// flag, and `Formatters.date` reads calendar/clock fields off whatever
/// zone the [DateTime] is in.
class LeadDateTimeField extends StatelessWidget {
  const LeadDateTimeField({
    super.key,
    this.label,
    required this.value,
    required this.onTap,
  });

  /// Defaults to [AppLocalizations.leadsCallTimeLabel] — kept nullable
  /// (rather than a `'CALL TIME'` compile-time default) purely so the
  /// fallback can go through localization; every current caller leaves this
  /// unset.
  final String? label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? l10n.leadsCallTimeLabel,
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          child: GlassSurface(
            variant: GlassVariant.flatForm,
            borderRadius: BorderRadius.circular(AppRadii.control),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.base,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null
                        ? l10n.leadsSelectDateLabel
                        : Formatters.date(value!.toLocal()),
                    style: type.body.copyWith(
                      color: value == null ? colors.faint : colors.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: colors.muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `LeadStatus` display label, matching `LeadStatusPill`'s own copy exactly
/// — reuses the same `AppLocalizations.shared*` keys `LeadStatusPill`
/// itself reads (`shared/widgets/status_pill.dart`) rather than a
/// second, independently-translated set of ARB entries for the identical
/// five strings (SCREENS.md §30's exact display copy).
String leadStatusLabel(AppLocalizations l10n, LeadStatus status) =>
    switch (status) {
      LeadStatus.newLead => l10n.sharedLeadStatusNewLabel,
      LeadStatus.couldNotConnect => l10n.sharedLeadStatusCouldNotConnectLabel,
      LeadStatus.needToCallBack => l10n.sharedLeadStatusNeedToCallBackLabel,
      LeadStatus.rejected => l10n.sharedLeadStatusRejectedLabel,
      LeadStatus.accepted => l10n.sharedLeadStatusAcceptedLabel,
      LeadStatus.unknown => l10n.sharedStatusUnknownLabel,
    };

/// A labelled text input on the flat-glass form material, with an optional
/// per-field [errorText] line (matching `shared/widgets/
/// labelled_form_field.dart`'s `LabelledFormField`, née
/// `edit_profile_screen.dart`'s `_FormField`). Kept as its own widget
/// rather than reusing `LabelledFormField` directly — see that file's doc
/// comment for why: this form's fields (Commit's `maxLines: 3`, a fixed
/// vertical padding regardless of line count) aren't quite that shape
/// either, closer to `ListingTextField`'s reasons than identical to them.
///
/// A field with [maxLines] > 1 is the mockup's `<textarea class="ta glf">`
/// — `.ta{height:auto;min-height:96px;padding:15px 16px;line-height:1.55;
/// resize:none;display:block}` — which rests at a *doubled* height, not at
/// one line that happens to be allowed to grow. Flutter's `TextField` opens
/// at `minLines` (defaulting to one line) regardless of `maxLines`, so
/// [minLines] defaults to [maxLines] here: that is what makes Commit read
/// as free text next to the single-line Email/Budget/Source boxes.
class LeadTextField extends StatelessWidget {
  const LeadTextField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.hintLine,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;

  /// The static `.hint` line under the box — a format rule the user needs
  /// before submitting (create-lead's "+998 and nine digits"), unlike
  /// [hintText], which is inside the field and vanishes on the first
  /// keystroke. Suppressed while [errorText] is set: the mockup never
  /// stacks a hint under an error.
  final String? hintLine;

  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  /// Resting height in lines. Left unset by every current caller, which
  /// takes the `.ta` default described in this class's doc comment: the
  /// field opens at [maxLines] when it is multi-line, and at one line
  /// otherwise.
  final int? minLines;

  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onChanged;
  final bool enabled;

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
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: maxLines,
            minLines: minLines ?? (maxLines > 1 ? maxLines : null),
            inputFormatters: inputFormatters,
            enabled: enabled,
            onChanged: (_) => onChanged?.call(),
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
        if (!hasError && hintLine != null) ...[
          // `.hint{margin-top:6px;padding-left:3px;font-size:10.5px;
          // line-height:1.5;color:var(--faint)}`.
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(
              hintLine!,
              style: type.micro.copyWith(color: colors.faint, height: 1.5),
            ),
          ),
        ],
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

/// Single-select chip [Wrap] for [LeadStatus] — same visual contract as
/// `features/filter/widgets/filter_choice_chip_group.dart`'s chip
/// (duplicated rather than imported: that file is private to
/// `features/filter/`, which `WORK_TAB_CONTRACT.md` §0 rule 3 reserves for
/// `my_listings` alone). Always required (no "any" deselect) — every lead
/// has exactly one status.
class LeadStatusField extends StatelessWidget {
  const LeadStatusField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final LeadStatus value;
  final ValueChanged<LeadStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.leadsStatusFieldLabel,
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final status in LeadStatus.kanbanOrder)
              LeadOptionChip(
                key: ValueKey('leadStatus-${status.wire}'),
                label: leadStatusLabel(l10n, status),
                isOn: status == value,
                onTap: () => onChanged(status),
              ),
          ],
        ),
      ],
    );
  }
}

/// The mockup's `.opt` pill — the mobile stand-in for the web app's `<select>`
/// enums. Used by [LeadStatusField] and by `leads-kanban`'s "Move to…" sheet,
/// which the mockup draws with the same `.opts`/`.opt` group.
class LeadOptionChip extends StatelessWidget {
  const LeadOptionChip({
    super.key,
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  final String label;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final foreground = isOn ? colors.pillInk : colors.ink;
    final content = Text(
      label,
      style: type.rowTitle.copyWith(color: foreground),
    );

    final chip = isOn
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: colors.pill,
              borderRadius: AppRadii.pill,
            ),
            alignment: Alignment.center,
            child: content,
          )
        : GlassSurface(
            variant: GlassVariant.onSurface,
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            alignment: Alignment.center,
            child: content,
          );

    return GestureDetector(onTap: onTap, child: chip);
  }
}

/// The honest stand-in for SCREENS.md §32/§33's "Coworker select (agent
/// role only)" — see `leads_repository.dart#coworkers`'s doc comment for
/// why this is display-only rather than a real select: `LeadWriteInput` has
/// no `coworkerId` field at all, so nothing typed into a select here could
/// ever be persisted. Shown only to an agent session (the caller gates
/// visibility), pre-filled with the resolved coworker name where one
/// exists, styled to *look* like the other select-shaped fields so it
/// reads as "present but inert," not missing — the same "look real, say
/// honestly that it isn't" shape every other stand-in in this app follows
/// (see the permissions-primer's `PermissionOutcome.unavailable` row for
/// another instance of the same idea).
class LeadCoworkerField extends StatelessWidget {
  const LeadCoworkerField({super.key, required this.coworkerName});

  /// `null` (blank) for a lead/draft with no assigned coworker.
  final String? coworkerName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.leadsCoworkerFieldLabel,
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Opacity(
          opacity: 0.6,
          child: GlassSurface(
            variant: GlassVariant.flatForm,
            borderRadius: BorderRadius.circular(AppRadii.control),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.base,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    coworkerName ?? '—',
                    style: type.body.copyWith(color: colors.ink),
                  ),
                ),
                Icon(Icons.lock_outline_rounded, size: 15, color: colors.faint),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: colors.faint),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                l10n.leadsCoworkerUnavailableNote,
                style: type.caption.copyWith(color: colors.faint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
