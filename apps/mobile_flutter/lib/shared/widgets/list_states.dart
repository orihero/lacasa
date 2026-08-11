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
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
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
            GestureDetector(
              onTap: onAction,
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
