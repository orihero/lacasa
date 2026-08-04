/// Shared photo surface for every listing card / tile on this screen.
/// Handles three cases identically: no photo URL at all (the fixture path
/// — see `home_feed_fixtures.dart`'s doc comment), a photo URL that fails
/// to load (the live-API path with no network reachable — exactly the
/// "must render sensibly with NO network available" scenario the build
/// task specifies), and a normal successful load. The first two both fall
/// back to the same themed placeholder box rather than a broken-image
/// glyph or a thrown error.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class ListingPhoto extends StatelessWidget {
  const ListingPhoto({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.icon = Icons.image_rounded,
  });

  final String? url;
  final BoxFit fit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    if (url == null || url!.isEmpty) {
      return _placeholder(colors);
    }

    return Image.network(
      url!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _placeholder(colors),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(colors);
      },
    );
  }

  Widget _placeholder(LaCasaColors colors) {
    return ColoredBox(
      color: colors.sunk,
      child: Center(child: Icon(icon, color: colors.faint, size: 28)),
    );
  }
}
