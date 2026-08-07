/// The `.sec` header row shared by every rail: an `h2` title plus an
/// optional trailing link ("View all" / "Explore"). [linkLabel]/[onLink]
/// both null renders the title alone — used by Explore Nearby, which the
/// build spec notes deliberately has no link ("full pagination lives in
/// `listing-search`, not here").
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.linkLabel,
    this.onLink,
  });

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flexible + ellipsis rather than an unconstrained Text: a larger
          // system font-scale setting or a longer localized string must
          // truncate gracefully here, not push the trailing link off the
          // right edge of the screen.
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: type.sectionHeading.copyWith(color: colors.ink),
            ),
          ),
          if (linkLabel != null && onLink != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onLink,
              child: Text(
                linkLabel!,
                style: type.rowTitle.copyWith(color: AppAccent.color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
