/// `.hero__nav` — the three round glass buttons floating over the hero:
/// back, share, and save. SCREENS.md §3.7's header row, verbatim.
///
/// **Share opens the real OS share sheet** via [LinkLauncher.share] — the
/// payload is the listing title, its formatted price, and the public web
/// link, not a bare URL, so whatever the user shares to (Telegram, SMS,
/// mail…) receives something worth reading on its own. Only a sheet the
/// user dismissed without picking a target falls back to copying just the
/// link and saying so honestly — the same "copy and toast" this button used
/// before `share_plus` existed, now reserved for the one path where the
/// real share genuinely didn't happen.
/// `ShareResultStatus.unavailable` (the platform can't say which action the
/// user took, but the sheet did open) does **not** fall back: [LinkLauncher.share]
/// already treats it as a success, and copy-link on top of a share that may
/// well have worked would just be a confusing second toast under a sheet
/// that did its job.
///
/// **Save is [FavouriteButton] with `hideForCoworker: false`**, the one
/// caller in the app that opts into SCREENS.md §3.7's literal "shown only
/// if `role != 'agent'`" wording instead of the hides-for-agent-and-
/// coworker rule every listing card follows. That widget's own doc comment
/// explains the divergence and why it wasn't silently harmonized.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/platform/link_launcher.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class ListingDetailNav extends ConsumerWidget {
  const ListingDetailNav({super.key, this.ad});

  /// Null while the listing is still loading or failed to load — back is
  /// still offered (a user must always be able to leave), share and save
  /// are not, since neither has anything to act on yet.
  final Ad? ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAd = ad;
    final l10n = AppLocalizations.of(context);

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
              semanticLabel: l10n.listingNavBackSemanticsLabel,
              onTap: () => _pop(context),
            ),
            const Spacer(),
            if (currentAd != null) ...[
              _RoundGlassButton(
                icon: Icons.ios_share_rounded,
                semanticLabel: l10n.listingNavShareSemanticsLabel,
                onTap: () => _share(context, ref, currentAd),
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

  Future<void> _share(BuildContext context, WidgetRef ref, Ad ad) async {
    // The public web listing URL — the same surface a recipient without the
    // app can open. `apps/web` serves listings at `/ads/:id`.
    final link = 'https://lacasa.uz/ads/${ad.id}';
    // A share payload worth receiving: title + formatted price + link, not
    // a bare URL. `Formatters.price` is the same rule the price footer
    // shows, reused rather than re-derived.
    final text = '${ad.title}\n${Formatters.price(ad)}\n$link';

    final shared = await ref
        .read(linkLauncherProvider)
        .share(text: text, subject: ad.title);
    if (!context.mounted || shared) return;

    // The sheet was dismissed without a target (or the platform can't say
    // which happened) — fall back to the old copy-and-toast behaviour
    // rather than a tap that looks like it did nothing.
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    LaCasaToast.showSuccess(
      context,
      AppLocalizations.of(context).listingLinkCopiedToastMessage,
    );
  }
}

/// `.hero__nav .rnd{background:rgba(255,255,255,.46);color:#1b1b23}` — the
/// one place the mockup overrides the base `.rnd{color:#fff}`: a dark ink
/// glyph on a light translucent circle, so it stays legible over any
/// photography rather than disappearing into a bright hero.
const Color _heroNavIcon = Color(0xFF1B1B23);

/// `.hero__nav .rnd` — 42px circle, glass, dark ink icon.
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
          // The `rgba(255,255,255,.46)` base tint sits *inside* the lens, on
          // top of the refracted photo, exactly as the CSS layers it.
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.46),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: _heroNavIcon),
          ),
        ),
      ),
    );
  }
}
