/// The `.fav g` heart control overlaid on a listing photo (or standalone,
/// e.g. `listing-detail`'s header row).
///
/// **Visibility rule, default**: hidden for `role: "agent"`/`role:
/// "coworker"`, visible for a signed-out session and `role: "user"` — the
/// rule every listing card in the app follows (Home's rails, search
/// results). **[hideForCoworker]** exists because SCREENS.md §3.7's own
/// text for `listing-detail` is narrower — "shown only if `role !=
/// 'agent'`" — which literally leaves the heart visible for a coworker,
/// unlike every card-shaped use of this control. Rather than silently
/// harmonizing the two (or forking the widget), that one screen passes
/// `hideForCoworker: false` to opt into the spec's literal text; every
/// other caller keeps the default. This divergence is flagged here again
/// deliberately — it may be a spec inconsistency worth resolving upstream,
/// not obviously intentional.
///
/// **Behavior**: tap flips the icon immediately (optimistic), then confirms
/// with [favouriteAdIdsProvider]'s notifier (`shared/state/`); a failure
/// reverts the icon and surfaces a toast. This is its own [GestureDetector]
/// nested inside the listing card's — Flutter's gesture arena resolves a
/// tap to the deepest hit-tested recognizer by default, so this tap is
/// never also seen by the card's `onTap`.
///
/// Promoted out of `features/home/widgets/favourite_button.dart`; the only
/// behavior change is the new [hideForCoworker] parameter (defaults to
/// `true`, i.e. Home's original hides-for-both rule is unchanged for every
/// existing caller) and reading [favouriteAdIdsProvider] from its new
/// shared home instead of Home's own state file.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../navigation/auth_session.dart';
import '../../theme/theme.dart';
import '../state/favourite_ad_ids_provider.dart';

class FavouriteButton extends ConsumerWidget {
  const FavouriteButton({
    super.key,
    required this.adId,
    this.size = 34,
    this.hideForCoworker = true,
  });

  final String adId;
  final double size;

  /// See this file's doc comment. `true` (the default) matches every
  /// card-shaped caller's rule; `listing-detail` passes `false` to follow
  /// SCREENS.md §3.7's literal "shown only if `role != 'agent'`" text.
  final bool hideForCoworker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;
    final hidden =
        role == UserRole.agent || (hideForCoworker && role == UserRole.coworker);
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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).sharedFavouriteUpdateFailedMessage,
            ),
          ),
        );
      }
    }
  }
}
