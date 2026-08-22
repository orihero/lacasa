/// The app's one answer to "this glyph/link is smaller than a fingertip".
///
/// Every icon-only control in this build started life as a hand-rolled
/// `GestureDetector` wrapped directly around whatever the mockup paints —
/// a 34dp round chip, a 28dp heart on a grid card, an 11.5dp "View all"
/// link, a bare "Retry" label. The mockup's sizes are *paint* sizes taken
/// from a CSS prototype that was never touched with a thumb; taken
/// literally in Flutter they become the **hit** size too, and every one of
/// them lands under both platform floors: 44dp (Apple HIG "Controls that
/// users interact with should be at least 44x44pt") and 48dp (Material
/// "Touch targets should be at least 48x48dp"). The worst offenders had no
/// box at all — a `GestureDetector` around a `Text` is exactly as tappable
/// as the ~17dp of glyph the font happened to draw.
///
/// [TapTarget] separates the two sizes so a caller never has to choose:
/// the **child keeps its mockup size and paints unchanged**, while the
/// hit box grows to [minSize] of transparent padding around it via a
/// [ConstrainedBox] + shrink-wrapping [Center]. `HitTestBehavior.opaque`
/// makes that padding catch taps rather than fall through — which is the
/// whole point, and also why it matters that this widget claims the tap
/// before an ancestor sees it: the heart on a listing card sits inside the
/// card's own `onTap`, and Flutter's gesture arena resolves a tap to the
/// deepest hit-tested recognizer, so a near-miss that used to open the
/// listing now toggles the favourite the user was aiming at.
///
/// **48, not 44.** Where the two platform floors disagree, taking the
/// larger one satisfies both from a single number, and the extra 4dp is
/// invisible: it is transparent padding, not paint.
///
/// **Semantics are not optional here.** [semanticsLabel] is required
/// rather than nullable because the controls this widget exists for are
/// icon-only or near-content-free — a heart, an "X", a two-word link — and
/// a screen-reader user gets nothing at all from them otherwise. The child's
/// own semantics are deliberately excluded ([Semantics.excludeSemantics]):
/// [semanticsLabel] always describes the whole control (for a text child it
/// is typically that same string), so leaving the child's node in place
/// would announce it twice.
///
/// Deliberately *not* an [IconButton]/[InkWell]: this app paints no Material
/// ink (see `AppTheme`'s `NoSplash.splashFactory` + transparent
/// `highlightColor`), and `IconButton` would additionally impose its own
/// padding, constraints and icon-theme colour on children that are already
/// pixel-matched to the mockup.
library;

import 'package:flutter/material.dart';

class TapTarget extends StatelessWidget {
  const TapTarget({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
    this.minSize = minimumSize,
  });

  /// The Material floor (48dp), which also clears Apple's 44pt one — see
  /// this file's doc comment for why a single number covers both.
  static const double minimumSize = 48;

  /// Announced by a screen reader in place of anything the child would say
  /// for itself. Required — see this file's doc comment.
  final String semanticsLabel;

  final VoidCallback onTap;

  /// Painted at its own intrinsic size, centred in the hit box. Nothing
  /// about the child changes; only what surrounds it does.
  final Widget child;

  /// Escape hatch for a control that genuinely cannot afford 48dp of
  /// layout (a dense inline row, say). Left at [minimumSize] everywhere in
  /// the app today; a caller lowering it is opting out of the floor this
  /// widget exists to enforce, so it should say why.
  final double minSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      // The tap action is declared here, not left to the GestureDetector
      // below: `excludeSemantics` drops the *whole* descendant subtree,
      // which would otherwise take the detector's own `tap` action with it
      // and leave a screen-reader user with a labelled node they cannot
      // activate — a worse control than the unlabelled one this replaced.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          // widthFactor/heightFactor: 1 makes this Center shrink-wrap the
          // child instead of expanding to the incoming maxWidth/maxHeight —
          // without them a TapTarget in a loose (or unbounded) parent would
          // swallow the whole row. The ConstrainedBox's minimums still
          // apply on the way back up, so the result is exactly
          // `max(childSize, minSize)`.
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
