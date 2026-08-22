/// Shared loading/error/empty vocabulary for any list-shaped surface in the
/// app: a pulsing shimmer box, a compact glass retry card for a
/// secondary/scoped failure, and a full-width centered state for a
/// primary/terminal failure or an empty result set. Every screen that
/// fetches a list should reach for one of these three rather than
/// hand-rolling its own loading/error/empty look — that consistency is the
/// whole point of pulling this out of Home (`rail_states.dart`) and giving
/// it a feature-agnostic name.
///
/// **Copy is the caller's job, not this file's** — [RailRetryCard] and
/// [FullWidthState] both take a [message] string because the loading/error
/// copy differs per screen (`map-view`'s pin set might phrase its own
/// failure differently than `listing-search`'s). The one rule every
/// *empty-result* caller must follow: SCREENS.md's copy is
/// **"No listings found"**, never the web app's misspelled "Not fount
/// post" (`apps/web/src/components/list/List.jsx:9`, confirmed real, and
/// exactly the kind of legacy bug this rebuild exists to not reproduce) —
/// `listing-search`'s own empty state used to disagree with this rule
/// ("No listings match your search."); that was a bug, fixed alongside
/// this screen's first tests.
///
/// Promoted verbatim out of `features/home/widgets/rail_states.dart` — no
/// behavior change, only its address (and file name — "rail" implied
/// Home's own horizontal rails specifically) moved.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/theme.dart';
import 'tap_target.dart';

/// Makes a state that does not scroll pull-to-refreshable.
///
/// [RefreshIndicator] arms itself off a [ScrollNotification] from a
/// descendant scrollable — so on the one screen state where a manual
/// refresh matters most, the *empty* one, there is nothing to pull. A
/// board that reads "No leads yet." because a coworker's lead hasn't been
/// fetched since the app launched is precisely the case §9.3 of the UX
/// audit describes, and wrapping only the populated list would have left
/// it the one place the gesture doesn't work.
///
/// This gives such a state a real, always-overscrollable viewport whose
/// content is at least as tall as the viewport itself, so the child still
/// renders centred and full-bleed while the pull gesture reaches the
/// indicator above it.
///
/// [ScrollConfiguration] with `overscroll: false` matches every other
/// scroller in this app: Android's stretch overscroll isolates a scrollable
/// into its own layer and renders the backdrop-sampling glass lenses inside
/// it black at the edges. It suppresses the *glow/stretch* only — a
/// [RefreshIndicator] is a separate widget and is unaffected.
///
/// **Give this a bounded height.** It is meant for the child of an
/// [Expanded]/sliver fill; under an unbounded parent the viewport constraint
/// it reads is infinite and the `minHeight` below would assert.
class RefreshableFill extends StatelessWidget {
  const RefreshableFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            // Not the default physics: a viewport whose content exactly
            // fills it has no scroll extent, and the default physics refuse
            // to accept a drag at all in that case — which is the whole
            // situation this widget exists for.
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: child),
            ),
          ),
        );
      },
    );
  }
}

/// A pulsing placeholder box standing in for a photo/line of text while a
/// list loads.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.sunk,
              colors.line,
              _controller.value * 0.6 + 0.2,
            ),
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}

/// A compact, scoped retry card — sized to whichever card shape the caller
/// passes via [width], for a secondary section whose failure shouldn't
/// blank the rest of the screen. Height is intrinsic to the content (an
/// icon, a message that may wrap to 2+ lines, and the Retry label) rather
/// than a caller-supplied fixed height, since a fixed height tuned for one
/// message length silently clips/overflows for another.
class RailRetryCard extends StatelessWidget {
  const RailRetryCard({
    super.key,
    required this.width,
    required this.message,
    required this.onRetry,
  });

  final double width;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.cardLg),
      // Card-sized rather than the small-first `.gl` default — widened so
      // the lens band reads as one continuous distortion across the card.
      distortionWidth: 18,
      width: width,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppStatusColors.warningText,
            size: 22,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: type.bodySmall.copyWith(color: colors.ink2),
          ),
          // No extra SizedBox: [TapTarget]'s 48dp minimum already puts ~15dp
          // of transparent padding above and below the Retry label, which is
          // more separation than the AppSpacing.sm gap it replaces. Stacking
          // both would push the card visibly taller for no gain.
          //
          // The label used to be a bare [GestureDetector] around 10dp type —
          // the smallest hit target in the app, on the one control whose
          // entire job is to be findable after something already went wrong.
          TapTarget(
            semanticsLabel: AppLocalizations.of(context).sharedRetryLabel,
            onTap: onRetry,
            child: Text(
              AppLocalizations.of(context).sharedRetryLabel,
              style: type.label.copyWith(color: AppAccent.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-width, primary-content error/empty state for a screen's
/// terminal list surface (e.g. `listing-search`'s results list, Home's
/// combined whole-feed-empty case). See this file's doc comment for the
/// copy rule every caller must follow for the empty case.
class FullWidthState extends StatelessWidget {
  const FullWidthState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        // Shrink-wrap so a caller that wraps this in a `Center` (leads-list,
        // leads-kanban, coworkers-list) actually gets a centered state: an
        // `Align` loosens its child's constraints, which a `MainAxisSize.max`
        // Column would immediately re-expand to fill, leaving the content
        // pinned to the top and the `Center` inert. Under a *tight* parent
        // (an `Expanded`, a sliver fill) this is a no-op — the column still
        // takes the full height.
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.faint, size: 36),
          const SizedBox(height: AppSpacing.base),
          Text(
            message,
            textAlign: TextAlign.center,
            style: type.body.copyWith(color: colors.ink2),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.base),
            // The pill's own padding already gets it close to 48dp tall but
            // not reliably past it (and never at all horizontally for a
            // short label), so the floor is enforced here rather than left
            // to whatever the caller's copy happens to measure.
            TapTarget(
              semanticsLabel: actionLabel!,
              onTap: onAction!,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.base,
                ),
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  actionLabel!,
                  style: type.label.copyWith(color: colors.pillInk),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
