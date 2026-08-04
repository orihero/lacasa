/// The `.fav g` heart control overlaid on a listing photo.
///
/// **Visibility rule** (build spec, "Favourite / heart control — exact
/// visibility rule"): hidden for `role: "agent"`/`role: "coworker"`,
/// visible for a signed-out session and `role: "user"` — inherited from
/// §3.7/the server's own rule, not from the mockup's `home-feed` markup
/// (which renders every heart unconditionally, a gap this build closes
/// rather than reproduces; see `listing-detail`'s own `data-when="not-agent"`
/// for the pattern this mirrors).
///
/// **Behavior**: tap flips the icon immediately (optimistic), then confirms
/// with [favouriteAdIdsProvider]'s notifier; a failure reverts the icon and
/// surfaces a toast. This is its own [GestureDetector] nested inside the
/// listing card's — Flutter's gesture arena resolves a tap to the deepest
/// hit-tested recognizer by default, so this tap is never also seen by the
/// card's `onTap` (the Flutter equivalent of the mockup's own
/// `e.stopPropagation()` on `data-fav`, achieved here by widget layering
/// rather than an explicit stop call).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../navigation/auth_session.dart';
import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';

class FavouriteButton extends ConsumerWidget {
  const FavouriteButton({super.key, required this.adId, this.size = 34});

  final String adId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;
    final hidden = role == UserRole.agent || role == UserRole.coworker;
    if (hidden) return const SizedBox.shrink();

    final isFavourite = ref.watch(favouriteAdIdsProvider).contains(adId);

    return GestureDetector(
      key: ValueKey('favourite-$adId'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(context, ref),
      child: GlassSurface(
        variant: GlassVariant.onPhoto,
        borderRadius: AppRadii.pill,
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Icon(
          isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: size * 0.5,
          color: isFavourite ? AppAccent.color : Colors.white,
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(favouriteAdIdsProvider.notifier).toggle(adId);
    } on ApiException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update favourites")),
        );
      }
    }
  }
}
