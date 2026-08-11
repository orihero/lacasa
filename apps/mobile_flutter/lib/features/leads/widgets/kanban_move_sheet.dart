/// `kanban-move-sheet` (SCREENS.md §34) — the gate `leads-kanban`'s "Move
/// to…" flow opens for a move into `need_to_call_back`, `rejected`, or
/// `accepted`. Contract §3.3 fixes this function's exact signature and
/// return contract — read that section before changing this file, since
/// `leads_kanban_screen.dart` is the one and only caller and depends on it
/// exactly.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import 'lead_form_controls.dart';

/// Opens the sheet for a move into [destination] (must be
/// [LeadStatus.needToCallBack], [LeadStatus.rejected], or
/// [LeadStatus.accepted] — the only three statuses `leads-kanban` ever
/// gates behind this sheet). Resolves to:
/// - `null` if the user cancelled — the caller must not move the card.
/// - a [LeadWriteInput] with `status: OptionalField(destination)` plus
///   either `callbackDate` ([LeadStatus.needToCallBack]) or
///   `conversationComment` ([LeadStatus.rejected]/[LeadStatus.accepted]) —
///   nothing else, per contract §3.3.
Future<LeadWriteInput?> showKanbanMoveSheet(
  BuildContext context, {
  required LeadStatus destination,
}) {
  return showModalBottomSheet<LeadWriteInput>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) => _KanbanMoveSheet(destination: destination),
  );
}

/// SCREENS.md §34's own field rule: "Commit (textarea, min 10 characters)".
const int _minNoteLength = 10;

class _KanbanMoveSheet extends StatefulWidget {
  const _KanbanMoveSheet({required this.destination});

  final LeadStatus destination;

  @override
  State<_KanbanMoveSheet> createState() => _KanbanMoveSheetState();
}

class _KanbanMoveSheetState extends State<_KanbanMoveSheet> {
  late final TextEditingController _note;
  DateTime? _callTime;
  bool _noteTouched = false;

  bool get _isCallback => widget.destination == LeadStatus.needToCallBack;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_isCallback) return _callTime != null;
    return _note.text.trim().length >= _minNoteLength;
  }

  Future<void> _pickCallTime() async {
    final picked = await pickLeadDateTime(context, initial: _callTime);
    if (picked == null || !mounted) return;
    setState(() => _callTime = picked);
  }

  void _save() {
    if (!_canSave) return;
    final input = _isCallback
        ? LeadWriteInput(
            status: OptionalField(widget.destination),
            callbackDate: OptionalField(_callTime),
          )
        : LeadWriteInput(
            status: OptionalField(widget.destination),
            conversationComment: OptionalField(_note.text.trim()),
          );
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    final title = _isCallback
        ? l10n.leadsCallbackSheetTitle
        : l10n.leadsConversationSheetTitle;

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
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(color: colors.line, borderRadius: AppRadii.pill),
                ),
              ),
              Text(title, style: type.sheetTitle.copyWith(color: colors.ink)),
              const SizedBox(height: AppSpacing.section),
              if (_isCallback) ...[
                Semantics(
                  button: true,
                  child: KeyedSubtree(
                    key: const ValueKey('kanbanMoveSheet-callTime'),
                    child: LeadDateTimeField(value: _callTime, onTap: _pickCallTime),
                  ),
                ),
              ] else ...[
                Text(l10n.leadsCommitFieldUppercaseLabel, style: type.label.copyWith(color: colors.muted)),
                const SizedBox(height: AppSpacing.sm),
                GlassSurface(
                  variant: GlassVariant.flatForm,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.base,
                  ),
                  child: TextField(
                    key: const ValueKey('kanbanMoveSheet-note'),
                    controller: _note,
                    maxLines: 4,
                    onChanged: (_) => setState(() => _noteTouched = true),
                    style: type.body.copyWith(color: colors.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: l10n.leadsConversationHint,
                      hintStyle: type.body.copyWith(color: colors.faint),
                    ),
                  ),
                ),
                if (_noteTouched && _note.text.trim().length < _minNoteLength) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.leadsCommitMinLengthError(_minNoteLength),
                    style: type.bodySmall.copyWith(color: AppStatusColors.errorText),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.section),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      key: const ValueKey('kanbanMoveSheet-cancel'),
                      label: l10n.leadsCancelButtonLabel,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: _SheetButton(
                      key: const ValueKey('kanbanMoveSheet-save'),
                      label: l10n.leadsSaveButtonLabel,
                      primary: true,
                      onTap: _canSave ? _save : null,
                    ),
                  ),
                ],
              ),
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
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final enabled = onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Opacity(
        opacity: !primary || enabled ? 1 : 0.5,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: primary ? AppAccent.gradient : null,
            color: primary ? null : colors.sunk,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
          ),
          child: Text(
            label,
            style: type.rowTitle.copyWith(color: primary ? Colors.white : colors.ink2),
          ),
        ),
      ),
    );
  }
}
