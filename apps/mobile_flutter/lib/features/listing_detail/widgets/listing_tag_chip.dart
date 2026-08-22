/// The `.tag` pill this screen uses for its three chip lists: the Info tags
/// (Type/Category/Repair/Furniture), Additional Information's key/value
/// pairs, and Nearby Places.
///
/// **Why [glass] is a parameter rather than always-on.** The source mockup
/// marks every one of these `.tag gl`, i.e. glass. Two of the three lists
/// are unbounded — `nearPlacesList` and `optionList` are free-form arrays
/// an agent fills in, and nothing caps them — and [GlassSurface] is a
/// backdrop-sampling shader whose own doc comment warns against "many large
/// lenses over one complex, frequently-repainting background". Twenty
/// nearby-place lenses stacked in a scroll view is exactly that shape. So
/// the bounded list (Info tags, at most four) keeps the glass the mockup
/// specifies, and the unbounded lists render the same pill as a flat
/// `sunk` fill. Deliberate, and the one place this screen departs from the
/// mockup's material.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class ListingTagChip extends StatelessWidget {
  const ListingTagChip({super.key, required this.label, this.glass = false});

  final String label;

  /// See this file's doc comment — `true` only for bounded chip lists.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // `.tag{height:30px;border-radius:15px;padding:0 12px;font-size:10.5px;
    // font-weight:500;color:var(--ink-2)}` — specMeta is that exact role.
    final text = Text(
      label,
      style: type.specMeta.copyWith(color: colors.ink2),
    );
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 7);

    if (!glass) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.sunk,
          borderRadius: BorderRadius.circular(15),
        ),
        child: text,
      );
    }

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(15),
      // The variant default is tuned for a card; a 30px-tall pill would be
      // swallowed whole by it (see GlassSurface.distortionWidth).
      distortionWidth: 7,
      padding: padding,
      child: text,
    );
  }
}
