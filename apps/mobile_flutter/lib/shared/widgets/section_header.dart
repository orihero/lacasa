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
import 'tap_target.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.linkLabel,
    this.onLink,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.screenGutter,
    ),
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
            // [TapTarget], not a bare [GestureDetector]: this link is
            // 11.5px type, so a detector wrapped straight around the Text
            // gave it a ~17dp-tall hit box with no padding at all — under
            // half the 48dp floor, on a control that sits at the very edge
            // of the screen where thumbs are least accurate. The link keeps
            // its type and colour exactly; only the transparent box around
            // it grows, which does raise the header row to 48dp tall
            // wherever a link is present (headers without one are
            // unchanged) — see `tap_target.dart` for why that layout cost
            // is the right side of the trade.
            TapTarget(
              semanticsLabel: linkLabel!,
              onTap: onLink!,
              child: Text(
                linkLabel!,
                // `.link{font-size:11.5px;font-weight:500;color:var(--muted)}`
                // — muted, not accent. The source's accent variant is a
                // separate class (`.link--acc`, used by login/register and
                // publish-status), and no `.sec` header in the mockup uses
                // it, so this widget renders the base rule only. No size
                // role is exactly 11.5/500; `specMeta` (10.5/500, no
                // letter-spacing) is the nearest and needs only the size.
                style: type.specMeta.copyWith(
                  fontSize: 11.5,
                  color: colors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
