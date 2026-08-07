/// Shared loading/error/empty building blocks for every rail on this
/// screen (build spec, "Loading, empty, and error states" table) — kept in
/// one file since the same three shapes (shimmer box, compact inline retry
/// card, centered empty state) get reused by every rail with only sizing
/// and copy varying.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// A pulsing placeholder box standing in for a photo/line of text while a
/// rail loads.
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

/// The compact, rail-scoped retry card (build spec: "scoped to the rail so
/// one failed call doesn't blank the screen"). Sized like whichever card
/// shape the caller passes via [width]; height is intrinsic to the content
/// (an icon, a message that may wrap to 2+ lines, and the Retry label) —
/// deliberately not a caller-supplied fixed height, since a fixed height
/// tuned for one message length silently clips/overflows for another.
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
      // Card-sized, like the pitch banner — see its note on widening the
      // band back out from the small-first `.gl` default.
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
              'Retry',
              style: type.label.copyWith(color: AppAccent.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// The full-width, primary-content error/empty state used by Explore
/// Nearby (the terminal browse surface — build spec's table distinguishes
/// this from the compact [RailRetryCard] used by secondary rails).
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
