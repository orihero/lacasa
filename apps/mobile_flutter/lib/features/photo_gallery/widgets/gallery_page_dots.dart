/// Page-dot index indicator — SCREENS.md §3.8: "page-dot indicator +
/// `{n}/{total}` counter". Self-scrolling (via an internal, user-
/// non-interactive [ListView]) so an ad with a large photo count never
/// overflows the screen width the way a plain unconstrained [Row] of dots
/// would; the active dot is kept roughly centered in view as the current
/// page changes.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';

class GalleryPageDots extends StatefulWidget {
  const GalleryPageDots({
    super.key,
    required this.total,
    required this.currentIndex,
  });

  final int total;
  final int currentIndex;

  @override
  State<GalleryPageDots> createState() => _GalleryPageDotsState();
}

class _GalleryPageDotsState extends State<GalleryPageDots> {
  final _scrollController = ScrollController();

  static const double _dotExtent = 14;

  @override
  void didUpdateWidget(covariant GalleryPageDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    }
  }

  void _scrollToCurrent() {
    if (!mounted || !_scrollController.hasClients) return;
    final target = (widget.currentIndex * _dotExtent) - 60;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      label: AppLocalizations.of(context).galleryPositionSemanticsLabel(
        widget.currentIndex + 1,
        widget.total,
      ),
      child: SizedBox(
        height: 8,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.total,
          itemBuilder: (context, i) {
            final active = i == widget.currentIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: active ? _dotExtent - 4 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: AppRadii.pill,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
