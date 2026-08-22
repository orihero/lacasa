/// "Nearby Places" (§26's "Nearby chip multi-select", `AdWriteInput
/// .nearPlacesList`). **Deviation from SCREENS.md's literal "multi-select"
/// wording, documented here rather than silently reinterpreted**: a
/// multi-select implies picking from a fixed vocabulary, but no such
/// vocabulary exists anywhere in this build — not in SCREENS.md itself, not
/// in `apps/web`/`apps/console`, and the wire field is `List<String>` free
/// text (`listing_detail_fixtures.dart`'s own example values are full
/// sentences like "Chilonzor metro station (7 min walk)", not a token from
/// a closed set). Built as a dynamic add/remove chip list instead — type a
/// place, tap **"Add"** to add it as a chip with an **"X"** to remove —
/// mirroring the Additional Info field's own already-spec'd "dynamic ...
/// rows (Delete per row, Add button)" interaction, applied to a single
/// string instead of a key/value pair. This is the honest reading of a
/// free-text wire field, not an invented vocabulary.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/shared.dart';
import '../../../../theme/theme.dart';
import 'listing_text_field.dart';

class NearbyPlacesField extends StatefulWidget {
  const NearbyPlacesField({
    super.key,
    required this.places,
    required this.onChanged,
  });

  final List<String> places;
  final ValueChanged<List<String>> onChanged;

  @override
  State<NearbyPlacesField> createState() => _NearbyPlacesFieldState();
}

class _NearbyPlacesFieldState extends State<NearbyPlacesField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onChanged([...widget.places, value]);
    _controller.clear();
    setState(() {});
  }

  void _removeAt(int index) {
    final next = List.of(widget.places)..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l10n.listingEditorNearbyPlacesLabel),
        if (widget.places.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < widget.places.length; i++)
                _RemovableChip(
                  key: ValueKey('nearbyPlace-$i-${widget.places[i]}'),
                  label: widget.places[i],
                  onRemove: () => _removeAt(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
        ],
        Row(
          children: [
            Expanded(
              child: GlassSurface(
                variant: GlassVariant.flatForm,
                borderRadius: BorderRadius.circular(AppRadii.control),
                // Same fixed `.inp` height as every other control on this
                // form (see `listing_text_field.dart`).
                height: kListingControlHeight,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  key: const ValueKey('nearbyPlace-input'),
                  controller: _controller,
                  onSubmitted: (_) => _add(),
                  style: listingControlTextStyle(
                    type,
                  ).copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: l10n.listingEditorNearbyPlacesHint,
                    hintStyle: listingControlTextStyle(
                      type,
                    ).copyWith(color: colors.faint),
                  ),
                ),
              ),
            ),
            const SizedBox(width: kListingFieldPairGap),
            GestureDetector(
              key: const ValueKey('nearbyPlace-add'),
              onTap: _add,
              child: Container(
                height: kListingControlHeight,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sunk,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
                child: Text(
                  l10n.listingEditorNearbyPlacesAddButtonLabel,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({
    super.key,
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: AppRadii.pill,
      padding: const EdgeInsets.only(
        left: 14,
        right: AppSpacing.sm,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: type.rowTitle.copyWith(color: colors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 16, color: colors.muted),
          ),
        ],
      ),
    );
  }
}
