/// The no-chrome overlay row for `photo-gallery`: dismiss "X" (top-left,
/// per SCREENS.md §3.8 — "Close 'X' top-left → back to listing-detail")
/// plus a `{n}/{total}` counter (top-right). Both painted with
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
  });

  final int currentIndex;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.base,
      left: AppSpacing.base,
      right: AppSpacing.base,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GalleryCloseButton(onTap: onClose),
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
      child: IconButton(
        icon: const Icon(Icons.close_rounded, color: Colors.white),
        tooltip: AppLocalizations.of(context).galleryCloseTooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
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

    return GlassSurface(
      variant: GlassVariant.onPhoto,
      borderRadius: AppRadii.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Semantics(
        label: AppLocalizations.of(context).galleryCounterSemanticsLabel(label),
        excludeSemantics: true,
        child: Text(
          label,
          style: LaCasaTypography.tabular(
            type.micro,
          ).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
