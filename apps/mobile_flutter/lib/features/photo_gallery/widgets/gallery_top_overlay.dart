/// The no-chrome overlay row for `photo-gallery`: dismiss "X" (top-left,
/// per SCREENS.md §3.8 — "Close 'X' top-left → back to listing-detail"),
/// the previous/next step buttons beside it (the mockup's
/// `data-gal-step="±1"` pair — a tap target for paging, since a swipe is
/// invisible and is also disabled while a photo is zoomed), and a
/// `{n}/{total}` counter (top-right). All painted with
/// [GlassVariant.onPhoto] — that variant's own doc comment
/// (`lib/theme/glass_surface.dart`) names "the photo-gallery counter/close
/// button" as one of its intended call sites.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../formatters/gallery_formatters.dart';

class GalleryTopOverlay extends StatelessWidget {
  const GalleryTopOverlay({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.onClose,
    this.onStep,
  });

  final int currentIndex;
  final int total;
  final VoidCallback onClose;

  /// Called with `-1`/`+1` by the previous/next buttons. `null` (or a
  /// single-item gallery) hides the pair entirely — there is nowhere to
  /// step to, and a permanently dead control is worse than no control.
  final ValueChanged<int>? onStep;

  @override
  Widget build(BuildContext context) {
    // `.gv__top{top:56px;left:18px;right:18px}` — the row clears the status
    // bar via the screen's own SafeArea, so only the horizontal inset and
    // the 12dp offset below it are stated here.
    return Positioned(
      top: AppSpacing.base,
      left: 18,
      right: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GalleryCloseButton(onTap: onClose),
          if (onStep != null && total > 1) ...[
            // `.gv__top{gap:9px}`.
            const SizedBox(width: 9),
            _StepButton(
              icon: Icons.chevron_left_rounded,
              label: AppLocalizations.of(
                context,
              ).galleryPreviousPhotoSemanticsLabel,
              onTap: currentIndex > 0 ? () => onStep!(-1) : null,
            ),
            const SizedBox(width: 9),
            _StepButton(
              icon: Icons.chevron_right_rounded,
              label: AppLocalizations.of(
                context,
              ).galleryNextPhotoSemanticsLabel,
              onTap: currentIndex < total - 1 ? () => onStep!(1) : null,
            ),
          ],
          const Spacer(),
          _CounterBadge(index: currentIndex, total: total),
        ],
      ),
    );
  }
}

/// The dismiss control. A real [IconButton] (not a bare [GestureDetector])
/// so it is reachable by keyboard focus/Tab and exposes its [tooltip] as
/// an accessible name to a screen reader — the assignment's explicit
/// "must be keyboard/screen-reader reachable: label the dismiss control"
/// requirement.
class GalleryCloseButton extends StatelessWidget {
  const GalleryCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      distortionWidth: 10,
      // `.rnd{width:42px;height:42px;font-size:19px;color:#fff}` — the same
      // disc as the step buttons beside it.
      width: 42,
      height: 42,
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(Icons.close_rounded, size: 19, color: Colors.white),
        tooltip: AppLocalizations.of(context).galleryCloseTooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// One `.rnd g` step button — 42px of glass over the photo, dimmed and
/// inert at whichever end of the gallery it can no longer move toward
/// (rather than removed, so the pair doesn't shift position mid-gallery).
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GlassSurface(
        variant: GlassVariant.onPhoto,
        borderRadius: AppRadii.pill,
        distortionWidth: 10,
        // `.rnd{width:42px;height:42px;font-size:19px;color:#fff}`.
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child: IconButton(
          icon: Icon(icon, size: 19, color: Colors.white),
          tooltip: label,
          onPressed: onTap,
          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final label = GalleryFormatters.pageCounter(index: index, total: total);

    // `.gv__ct{height:32px;border-radius:16px;padding:0 13px;
    // font-size:11.5px;font-weight:600;color:#fff}`. Tabular figures are
    // kept so the counter doesn't jitter as the page index changes width.
    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Semantics(
        label: AppLocalizations.of(context).galleryCounterSemanticsLabel(label),
        excludeSemantics: true,
        child: Text(
          label,
          style: LaCasaTypography.tabular(type.bodySmall).copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
