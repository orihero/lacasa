/// The shell every body section of `listing-detail` sits in: a heading and
/// its content, with the vertical rhythm applied in one place so Description,
/// Additional Information, Sizes, Nearby Places and Location can't drift
/// apart by a few pixels each.
///
/// [ListingDetailSection] renders nothing at all when [child] is null. That
/// is the mechanism behind this screen's honest-gap rule: a section whose
/// data the ad doesn't carry is *absent*, not present-but-empty. An ad with
/// no `nearPlacesList` shows no Nearby Places heading, rather than a heading
/// over blank space that reads as a loading failure.
///
/// The exception is Location, which passes a non-null child even with no
/// pin — "we don't have a location for this listing" is information the
/// buyer wants, unlike "this listing has no additional information", which
/// is not. See `listing_location_section.dart`.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class ListingDetailSection extends StatelessWidget {
  const ListingDetailSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;

  /// Null renders the whole section away, heading included.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final body = child;
    if (body == null) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.panel__h h3` — 15.5/700.
          Text(title, style: type.panelHeading.copyWith(color: colors.ink)),
          const SizedBox(height: AppSpacing.base),
          body,
        ],
      ),
    );
  }
}

/// A `.tags`-style wrap of chips, the layout three of this screen's
/// sections share. Returns null for an empty [children] list so a caller
/// can hand the result straight to [ListingDetailSection.child] and get the
/// heading dropped along with it.
Widget? tagWrapOrNull(List<Widget> children) {
  if (children.isEmpty) return null;
  return Wrap(
    spacing: 7,
    runSpacing: 7,
    children: children,
  );
}
