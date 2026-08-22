/// "Additional Info" (§26's "dynamic key/value rows (Delete per row, Add
/// button)", `AdWriteInput.optionList`). Each row is a free-text key +
/// free-text value; **"Add"** appends a blank editable row, **"Delete"**
/// removes one.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'listing_form_fields.dart';

class AdditionalInfoField extends StatelessWidget {
  const AdditionalInfoField({
    super.key,
    required this.rows,
    required this.onChanged,
  });

  final List<AdditionalInfoRow> rows;

  /// Called after any add/edit/delete — the caller owns re-rendering
  /// (typically `setState(() {})`, since [rows] is mutated in place by this
  /// widget's own callbacks rather than rebuilt as a new list each time).
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l10n.listingEditorAdditionalInfoLabel),
        for (var i = 0; i < rows.length; i++) ...[
          _Row(
            key: ValueKey('additionalInfo-row-${rows[i].id}'),
            row: rows[i],
            onChanged: onChanged,
            onDelete: () {
              rows.removeAt(i);
              onChanged();
            },
          ),
          // `.kv{margin-bottom:8px}`
          const SizedBox(height: AppSpacing.md),
        ],
        // `<button class="btn btn--sm btn--ghost glf" style="margin-top:9px">
        // <i class="i" data-i="plus"></i>Add</button>` —
        // `.btn--sm{height:44px;border-radius:22px;font-size:12.5px;
        // width:auto;padding:0 18px}`, `.btn .i{font-size:17px}`.
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: GestureDetector(
            key: const ValueKey('additionalInfo-add'),
            onTap: () {
              rows.add(AdditionalInfoRow());
              onChanged();
            },
            child: GlassSurface(
              variant: GlassVariant.flatForm,
              borderRadius: AppRadii.pill,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 17, color: colors.ink),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.listingEditorAdditionalInfoAddButtonLabel,
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.row,
    required this.onChanged,
    required this.onDelete,
  });

  final AdditionalInfoRow row;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // `.kv{display:flex;align-items:center;gap:8px;border-radius:16px;
    // padding:7px 8px 7px 14px}` — key, value *and* the delete button share
    // **one** row surface; they are not three separate boxes.
    return GlassSurface(
      variant: GlassVariant.flatForm,
      borderRadius: BorderRadius.circular(AppRadii.md),
      padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // `.kv__k{max-width:38%;font-weight:600}` — expressed as a flex
          // weight rather than a hard cap, so a long Russian/Uzbek key
          // still gets its ~38% share without being truncated by a
          // pixel-exact ceiling.
          Expanded(
            flex: 38,
            child: _input(
              context,
              hintText: l10n.listingEditorAdditionalInfoKeyHint,
              initialText: row.key,
              bold: true,
              onChanged: (v) {
                row.key = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 62,
            child: _input(
              context,
              hintText: l10n.listingEditorAdditionalInfoValueHint,
              initialText: row.value,
              onChanged: (v) {
                row.value = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // `.kv__x{width:32px;height:32px;border-radius:16px;font-size:15px;
          // color:#e0355f}`
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 15,
                  color: AppStatusColors.errorText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// `.kv input{flex:1;min-width:0;border:0;background:none;font-size:12px}`
  /// — a bare field on the shared `.kv` surface, not a nested input box.
  Widget _input(
    BuildContext context, {
    required String hintText,
    required String initialText,
    required ValueChanged<String> onChanged,
    bool bold = false,
  }) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final style = bold
        ? type.body.copyWith(fontWeight: FontWeight.w600)
        : type.body;

    return TextFormField(
      initialValue: initialText,
      onChanged: onChanged,
      style: style.copyWith(color: colors.ink),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        hintText: hintText,
        hintStyle: style.copyWith(color: colors.faint),
      ),
    );
  }
}
