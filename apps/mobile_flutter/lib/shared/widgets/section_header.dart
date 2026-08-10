/// A section/list header: a title plus an optional trailing link ("View
/// all" / "Explore" / "Clear"). [linkLabel]/[onLink] both null renders the
/// title alone. Originally every rail on Home's own feed; the same shape
/// fits e.g. `listing-search`'s "Recent Searches … Clear" row, which is
/// why this lives here rather than staying Home-only.
///
/// Promoted verbatim out of `features/home/widgets/section_header.dart` —
/// no behavior change, only its address moved. [padding] was added later,
/// promoting `work_dashboard`'s private `_SectionTitle` into this widget:
/// every original caller sits in a scroll view with zero horizontal
/// padding of its own and relies on this widget's default screen-gutter
/// inset, but Dashboard's "Coworker statistics" heading lives inside a
/// `Column` whose parent `SingleChildScrollView` already applies that same
/// gutter — adding a second one would double-indent it relative to every
/// sibling section. Dashboard passes [EdgeInsets.zero] rather than getting
/// its own near-identical copy of this widget.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.linkLabel,
    this.onLink,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
  });

  final String title;
  final String? linkLabel;
  final VoidCallback? onLink;

  /// Defaults to the screen-gutter inset every original (Home-rail) caller
  /// relies on. A caller already inside a padded container — see this
  /// file's doc comment — passes [EdgeInsets.zero] instead.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: padding,
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
