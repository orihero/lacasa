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
          const SizedBox(height: AppSpacing.sm),
        ],
        GestureDetector(
          key: const ValueKey('additionalInfo-add'),
          onTap: () {
            rows.add(AdditionalInfoRow());
            onChanged();
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sunk,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: Text(
              l10n.listingEditorAdditionalInfoAddButtonLabel,
              style: type.rowTitle.copyWith(color: colors.ink),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _cell(
            context,
            hintText: l10n.listingEditorAdditionalInfoKeyHint,
            initialText: row.key,
            onChanged: (v) {
              row.key = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _cell(
            context,
            hintText: l10n.listingEditorAdditionalInfoValueHint,
            initialText: row.value,
            onChanged: (v) {
              row.value = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: onDelete,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppStatusColors.errorText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(
    BuildContext context, {
    required String hintText,
    required String initialText,
    required ValueChanged<String> onChanged,
  }) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.flatForm,
      borderRadius: BorderRadius.circular(AppRadii.control),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 4,
      ),
      child: TextFormField(
        initialValue: initialText,
        onChanged: onChanged,
        style: type.body.copyWith(color: colors.ink),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: type.body.copyWith(color: colors.faint),
        ),
      ),
    );
  }
}
