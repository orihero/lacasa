/// The `.topfade` strip: a blurred bar pinned under the OS status bar so
/// content scrolling past the clock stays legible, fading to transparent
/// toward its bottom edge. Build spec: "this is chrome, not a 'section,'
/// and is shared by every scrolling tab-root screen, not specific to
/// Home" — kept local to `lib/features/home/` for this build (which owns
/// only that directory), with a doc note here for whichever later agent
/// builds `listing-search`/`agents-directory`/etc. that this is a
/// candidate to hoist into shared chrome rather than reimplement.
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
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
