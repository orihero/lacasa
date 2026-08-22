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
/// **Behavior, signed in**: tap flips the icon immediately (optimistic),
/// then confirms with [favouriteAdIdsProvider]'s notifier
/// (`shared/state/`); a failure reverts the icon and surfaces a toast. This
/// is its own tap recognizer nested inside the listing card's — Flutter's
/// gesture arena resolves a tap to the deepest hit-tested recognizer by
/// default, so this tap is never also seen by the card's `onTap`.
///
/// **Behavior, signed out**: the heart is *visible* (see the visibility
/// rule above) but saving requires an account, so the session is checked
/// **before** the optimistic flip and the tap becomes an invitation instead
/// of a mutation — [showSignInToSavePrompt]'s toast plus a "Sign in" action.
/// It used to flip the heart, POST `/saved-ads/:id` with no token, revert on
/// the 401, and report "Couldn't update favourites" — three lies in a row: a
/// state that was never saved, a request that could never succeed, and copy
/// blaming a network that was working perfectly. `saved-listings` already
/// treated this same situation as a sign-in prompt (its `_SignedOutState`);
/// this is that treatment applied at the moment the user actually reaches
/// for it, which for a marketplace is the single most common point at which
/// an anonymous visitor has a reason to create an account.
///
/// **Tap target**: the painted chip stays at the mockup's [size] (34dp on a
/// full card, 28dp on a grid card, 26dp on a row card, 42dp in
/// `listing-detail`'s hero nav) while [TapTarget] grows the *hit* box to
/// 48dp — see `tap_target.dart` for why a 28dp heart sitting a few pixels
/// from the card's own `onTap` was the app's worst-behaved control. The chip
/// is *centred* in that box, so a card positioning this widget by the
/// mockup's own `.fav{top:…;right:…}` inset moves the paint inward by half
/// the difference; [cornerInset] is the one place that compensation is
/// computed, and every card-shaped caller goes through it.
///
/// Promoted out of `features/home/widgets/favourite_button.dart`; the only
/// behavior change on promotion was the [hideForCoworker] parameter
/// (defaults to `true`, i.e. Home's original hides-for-both rule is
/// unchanged for every existing caller) and reading [favouriteAdIdsProvider]
/// from its new shared home instead of Home's own state file.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../navigation/auth_session.dart';
import '../../navigation/route_paths.dart';
import '../../theme/theme.dart';
import '../state/favourite_ad_ids_provider.dart';
import 'tap_target.dart';
import 'toast.dart';

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

  /// The [Positioned] inset a card must use so the **painted** chip still
  /// lands [mockupInset] from its photo's edge, given that [TapTarget]
  /// centres a [size] chip inside a 48dp hit box.
  ///
  /// This exists because the compensation was got wrong the first time and
  /// in three different ways: `.fcard`'s heart kept its `top:9px;right:9px`
  /// and drifted to ~16px, contradicting the CSS rule quoted directly above
  /// it; `.vcard`'s was hand-tuned to a number that split the difference;
  /// `.lcard`'s was left alone. It is arithmetic, not judgement, so it is
  /// computed once here rather than re-derived per card.
  ///
  /// A negative result is expected and correct on the tight cards: the chip
  /// sits closer to the corner than the hit box's own half-margin, so the
  /// box's outermost 2–4px land outside the photo. Nothing is lost there
  /// that could have been won: a [RenderBox] only hit-tests points inside
  /// its own size, so the photo's `Stack` never sees a pointer past its rect
  /// however far a `Positioned` child overhangs it — that strip belongs to
  /// the card's own `onTap` and always did. The usable corner target is
  /// therefore 44–46dp on `.vcard`/`.lcard` instead of 48dp: still above
  /// Apple's 44pt floor, and far better than the alternative, which is every
  /// heart in the app visibly off its corner.
  static double cornerInset(double mockupInset, {double size = 34}) =>
      mockupInset - (TapTarget.minimumSize - size) / 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;
    final hidden =
        role == UserRole.agent ||
        (hideForCoworker && role == UserRole.coworker);
    if (hidden) return const SizedBox.shrink();

    final isFavourite = ref.watch(favouriteAdIdsProvider).contains(adId);
    final l10n = AppLocalizations.of(context);

    return TapTarget(
      key: ValueKey('favourite-$adId'),
      // The label names what the tap *does*, not what the icon currently
      // shows — a screen reader announcing "Remove from favourites" on a
      // filled heart tells the user the outcome of activating it, which is
      // the only thing they can act on.
      semanticsLabel: isFavourite
          ? l10n.sharedFavouriteRemoveSemanticsLabel
          : l10n.sharedFavouriteAddSemanticsLabel,
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
    // Read the session *before* the optimistic flip, not after the request
    // comes back 401 — see this file's doc comment.
    if (!ref.read(authSessionProvider).isSignedIn) {
      showSignInToSavePrompt(context);
      return;
    }

    try {
      await ref.read(favouriteAdIdsProvider.notifier).toggle(adId);
    } on ApiException {
      if (context.mounted) {
        LaCasaToast.showError(
          context,
          AppLocalizations.of(context).sharedFavouriteUpdateFailedMessage,
        );
      }
    }
  }
}

/// The signed-out response to any "save this listing" gesture: a neutral
/// toast inviting the user to sign in, with the sign-in screen one tap away
/// rather than left as an exercise.
///
/// Lives here, next to the control that raises it most, but is deliberately
/// public and top-level because `listing-detail` raises the identical prompt
/// from a second surface — SCREENS.md §3.7's "Save the Place" button, which
/// toggles the same [favouriteAdIdsProvider] state as the hero's heart and
/// therefore must fail (and invite) identically. Two copies of this would be
/// two places for the copy, the icon, the duration and the destination to
/// drift apart.
///
/// Neutral ([LaCasaToast.showInfo]), never [LaCasaToast.showError]: nothing
/// failed. The user asked for something the app is happy to give them as
/// soon as they have an account.
void showSignInToSavePrompt(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  // Resolved *now*, while the raising widget is certainly still mounted.
  // The toast outlives it — 4s is long enough for a listing card to scroll
  // out of the tree, which on a marketplace feed is the common case, not the
  // exotic one — and the previous `if (context.mounted) context.push(...)`
  // turned exactly that case into a button that looked tappable and did
  // nothing at all. A [GoRouter] is app-scoped and outlives every card, so
  // holding the router itself (rather than a context that can find one)
  // makes "Sign in" work for the whole life of the toast.
  final router = GoRouter.of(context);
  LaCasaToast.showInfo(
    context,
    l10n.sharedSignInToSaveMessage,
    // No `textColor` here: the accent is the toast system's, set once as
    // `SnackBarThemeData.actionTextColor` (see `toast.dart` and
    // `lib/theme/app_theme.dart`) so every action toast matches without
    // each call site remembering to say so.
    action: SnackBarAction(
      label: l10n.sharedSignInActionLabel,
      onPressed: () => router.push(RoutePaths.login),
    ),
  );
}
