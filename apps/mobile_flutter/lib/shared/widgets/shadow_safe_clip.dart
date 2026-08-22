/// A [ClipRect] that clips the horizontal axis only, leaving vertical
/// slack so a child's drop shadow can paint outside the box.
///
/// ## The problem it exists for
/// Every scroll view in Flutter clips to its viewport by default
/// (`clipBehavior: Clip.hardEdge`). That is correct for the scroll axis —
/// content must not spill past the track — but it also clips the *cross*
/// axis, and the cross axis is where drop shadows live.
///
/// A horizontal strip of chips is the case that bites. The rail is sized
/// to the chips (a 32dp chip in a 38dp band, a 40dp chip in a 46dp band),
/// because that is what the mockup states, while [AppShadows.selectedChip]
/// is `0 8px 18px -4px` — it needs roughly 22dp *below* the chip to finish.
/// The viewport clip cuts it off a few pixels down, so the shadow ends in a
/// hard horizontal line flush against the pill instead of fading out. The
/// pill then reads as a taller, heavier block than the chips beside it,
/// which is the opposite of what an elevation is for.
///
/// Simply passing `clipBehavior: Clip.none` to the scroll view fixes the
/// shadow and breaks the scrolling: items scrolled past the leading edge
/// keep painting, over whatever sits beside the strip. That is fine for a
/// rail that spans the full screen (there is nothing beside it, and the
/// overflow lands off-screen), and wrong for a strip sharing its row with
/// other controls.
///
/// This widget is the pair to `Clip.none`: set the scroll view's
/// [Clip.none] so it stops clipping at all, then wrap it in this so the
/// horizontal clip comes back — and only that one. Shadows keep their
/// [slack] above and below.
///
/// ```dart
/// ShadowSafeClip(
///   child: SingleChildScrollView(
///     scrollDirection: Axis.horizontal,
///     clipBehavior: Clip.none,
///     child: ...,
///   ),
/// )
/// ```
library;

import 'package:flutter/widgets.dart';

class ShadowSafeClip extends StatelessWidget {
  const ShadowSafeClip({super.key, required this.child, this.slack = 32});

  final Widget child;

  /// How far above and below the box the child may paint, in logical
  /// pixels. The default clears the tallest shadow in `AppShadows`
  /// (`selectedPillLarge`, which reaches ~22dp) with room to spare; a
  /// shadow is a soft gradient, so over-reserving costs nothing but
  /// under-reserving is visible as a hard edge.
  final double slack;

  @override
  Widget build(BuildContext context) {
    return ClipRect(clipper: _VerticalSlackClipper(slack), child: child);
  }
}

class _VerticalSlackClipper extends CustomClipper<Rect> {
  const _VerticalSlackClipper(this.slack);

  final double slack;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -slack, size.width, size.height + slack);

  @override
  bool shouldReclip(_VerticalSlackClipper oldClipper) =>
      oldClipper.slack != slack;
}
