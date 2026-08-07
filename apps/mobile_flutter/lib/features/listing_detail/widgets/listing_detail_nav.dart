/// `.hero__nav` — the three round glass buttons floating over the hero:
/// back, share, and save. SCREENS.md §3.7's header row, verbatim.
///
/// **Share copies the listing link to the clipboard and toasts**, rather
/// than opening the OS share sheet the spec names. A native share sheet
/// needs a platform plugin (`share_plus`) this app does not depend on, and
/// adding one is a `pubspec.yaml` + per-platform-config change well outside
/// a screen build. The mockup's own share button does exactly this — its
/// markup is `data-toast="Link copied for sharing"` — so this matches the
/// prototype's behaviour while the plugin question stays open. Flagged in
/// the README's gap list, not quietly substituted.
///
/// **Save is [FavouriteButton] with `hideForCoworker: false`**, the one
/// caller in the app that opts into SCREENS.md §3.7's literal "shown only
/// if `role != 'agent'`" wording instead of the hides-for-agent-and-
/// coworker rule every listing card follows. That widget's own doc comment
/// explains the divergence and why it wasn't silently harmonized.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class ListingDetailNav extends StatelessWidget {
  const ListingDetailNav({super.key, this.ad});

  /// Null while the listing is still loading or failed to load — back is
  /// still offered (a user must always be able to leave), share and save
  /// are not, since neither has anything to act on yet.
  final Ad? ad;

  @override
  Widget build(BuildContext context) {
    final currentAd = ad;

    return Positioned(
      top: AppSpacing.base,
      left: 21,
      right: 21,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _RoundGlassButton(
              icon: Icons.arrow_back_rounded,
              semanticLabel: 'Back',
              onTap: () => _pop(context),
            ),
            const Spacer(),
            if (currentAd != null) ...[
              _RoundGlassButton(
                icon: Icons.ios_share_rounded,
                semanticLabel: 'Share',
                onTap: () => _share(context, currentAd),
              ),
              const SizedBox(width: 9),
              // Sized to match the two buttons beside it — FavouriteButton's
              // own default is the 34px card-corner size.
              FavouriteButton(
                adId: currentAd.id,
                size: 42,
                hideForCoworker: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    // `context.pop()` throws when there is nothing to pop — a deep link
    // straight into a listing is exactly that case, and it is not an error
    // state, it just means "up" is Home rather than "back".
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  Future<void> _share(BuildContext context, Ad ad) async {
    // The public web listing URL — the same surface a recipient without the
    // app can open. `apps/web` serves listings at `/ads/:id`.
    await Clipboard.setData(
      ClipboardData(text: 'https://lacasa.uz/ads/${ad.id}'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied for sharing')),
    );
  }
}

/// `.rnd` over a photo — 42px circle, glass, white icon.
class _RoundGlassButton extends StatelessWidget {
  const _RoundGlassButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onPhoto,
          borderRadius: AppRadii.pill,
          width: 42,
          height: 42,
          alignment: Alignment.center,
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }
}
