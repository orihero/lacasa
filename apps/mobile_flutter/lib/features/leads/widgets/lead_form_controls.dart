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
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

/// Two-step date-then-time picker shared by `kanban-move-sheet`'s "Call
/// time" field and `lead-detail`'s conditional "Call time" field — built on
/// plain Flutter `showDatePicker`/`showTimePicker` (no new dependency, see
/// `WORK_TAB_CONTRACT.md` §5). Returns `null` if the user backs out of
/// either step.
Future<DateTime?> pickLeadDateTime(BuildContext context, {DateTime? initial}) async {
  final now = DateTime.now();
  final seed = initial ?? now;
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

/// The select-shaped "Call time" tap target both callers of
/// [pickLeadDateTime] render around it.
class LeadDateTimeField extends StatelessWidget {
  const LeadDateTimeField({
    super.key,
    this.label = 'CALL TIME',
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: type.label.copyWith(color: colors.muted)),
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
                    value == null ? 'Select date' : Formatters.date(value!),
                    style: type.body.copyWith(
                      color: value == null ? colors.faint : colors.ink,
                    ),
                  ),
                ),
                Icon(Icons.calendar_month_outlined, size: 18, color: colors.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `LeadStatus` display label, matching `LeadStatusPill`'s own copy
/// verbatim (SCREENS.md §30's exact strings) — duplicated rather than
/// imported since [LeadStatusPill]'s label switch is private to
/// `shared/widgets/status_pill.dart`.
String leadStatusLabel(LeadStatus status) => switch (status) {
  LeadStatus.newLead => 'New',
  LeadStatus.couldNotConnect => 'Could Not Connect',
  LeadStatus.needToCallBack => 'Need To Call Back',
  LeadStatus.rejected => 'Rejected',
  LeadStatus.accepted => 'Accepted',
  LeadStatus.unknown => 'Unknown',
};

/// A labelled text input on the flat-glass form material, with an optional
/// per-field [errorText] line (matching `shared/widgets/
/// labelled_form_field.dart`'s `LabelledFormField`, née
/// `edit_profile_screen.dart`'s `_FormField`). Kept as its own widget
/// rather than reusing `LabelledFormField` directly — see that file's doc
/// comment for why: this form's fields (Commit's `maxLines: 3`, a fixed
/// vertical padding regardless of line count) aren't quite that shape
/// either, closer to `ListingTextField`'s reasons than identical to them.
class LeadTextField extends StatelessWidget {
  const LeadTextField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
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
        Text(label.toUpperCase(), style: type.label.copyWith(color: colors.muted)),
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
                  style: type.bodySmall.copyWith(color: AppStatusColors.errorText),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS', style: type.label.copyWith(color: colors.muted)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final status in LeadStatus.kanbanOrder)
              _StatusChip(
                key: ValueKey('leadStatus-${status.wire}'),
                label: leadStatusLabel(status),
                isOn: status == value,
                onTap: () => onChanged(status),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
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
    final content = Text(label, style: type.rowTitle.copyWith(color: foreground));

    final chip = isOn
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: colors.pill, borderRadius: AppRadii.pill),
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
/// reads as "present but inert," not missing — matching this codebase's
/// `MediaUploadUnavailableNotice` precedent for the same kind of gap.
class LeadCoworkerField extends StatelessWidget {
  const LeadCoworkerField({super.key, required this.coworkerName});

  /// `null` (blank) for a lead/draft with no assigned coworker.
  final String? coworkerName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COWORKER', style: type.label.copyWith(color: colors.muted)),
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
                "Assigning a coworker isn't available in this build yet.",
                style: type.caption.copyWith(color: colors.faint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
