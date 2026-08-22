/// The `.topfade` strip: a blurred bar pinned under the OS status bar so
/// content scrolling past the clock stays legible, fading to transparent
/// toward its bottom edge. Build spec: "this is chrome, not a 'section,'
/// and is shared by every scrolling tab-root screen, not specific to
/// Home" — kept local to `lib/features/home/` for this build (which owns
/// only that directory), with a doc note here for whichever later agent
/// builds `listing-search`/`agents-directory`/etc. that this is a
/// candidate to hoist into shared chrome rather than reimplement.
///
/// ## Height
/// `.topfade{height:var(--fh,64px)}` (mockup :193): the strip is sized to
/// whatever chrome it has to back. On a screen with no fixed header that is
/// `--fh:64px`, the status bar alone — the intrinsic height below, which
/// takes the real inset rather than the source's fixed 54px status bar and
/// adds the same ~20px of ramp under it. On a screen with a fixed header,
/// `--fh` is that
/// header's full height (`.nav{height:var(--fh)}`, :196-198) so the strip
/// blurs everything sliding under it, not just the top of it. Give this
/// widget tight constraints (a [Positioned.fill] inside the header's own
/// box) to get the second case; see `home_feed_screen.dart`'s pinned
/// header, the one caller that does.
///
/// Known drift: the source's mask fades the `backdrop-filter` out along
/// with the tint, so the blur itself dissolves. [BackdropFilter] takes no
/// mask, so only the tint ramps and the blur ends on a hard horizontal
/// edge. A progressive-blur stack would close it; it is not worth the
/// layers until the strip backs something taller than a header row.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class TopFadeBar extends StatelessWidget {
  const TopFadeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final topInset = MediaQuery.of(context).padding.top;

    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: topInset + 20,
            decoration: BoxDecoration(
              // `-webkit-mask:linear-gradient(#000 0%,#000 50%,transparent
              // 100%)` — the source holds the strip at full strength for its
              // top half and only then ramps out, so the clock keeps a solid
              // scrim whatever the strip's height is. A straight two-stop
              // ramp thinned out over the clock as soon as the strip grew
              // past the status bar to back a fixed header.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.5, 1],
                colors: [
                  colors.screen.withValues(alpha: 0.85),
                  colors.screen.withValues(alpha: 0.85),
                  colors.screen.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
