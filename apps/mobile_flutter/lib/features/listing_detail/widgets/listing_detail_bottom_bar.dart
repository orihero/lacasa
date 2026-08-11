/// The floating action bar pinned to the bottom of `listing-detail`
/// (mockup `.bar`): the asking price on the left, the primary
/// **"Submit an application"** CTA on the right.
///
/// **Where "Save the Place" went.** SCREENS.md §3.7 lists two buttons —
/// "Submit an application" (primary, full-width) and "Save the Place"
/// (only if `role != "agent"`) — while the mockup's bar carries the price
/// and one button, with saving handled by the heart in the hero nav. Both
/// are honoured rather than one being dropped: the bar matches the mockup,
/// and "Save the Place" renders as a full-width secondary button in the
/// content just above the price footer, gated on the same role rule and
/// wired to the same [favouriteAdIdsProvider] the heart toggles. A user
/// therefore sees both affordances the spec asks for, and they never
/// disagree about state because there is only one piece of state.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class ListingDetailBottomBar extends StatelessWidget {
  const ListingDetailBottomBar({
    super.key,
    required this.ad,
    required this.onSubmitApplication,
  });

  final Ad ad;
  final VoidCallback onSubmitApplication;

  /// What the scrolling content must clear so the last section isn't
  /// permanently hidden behind this bar (`.det{padding-bottom:112px}`).
  static const double reservedHeight = 112;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Positioned(
      left: 10,
      right: 10,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(30),
          distortionWidth: 18,
          height: 78,
          padding: const EdgeInsets.only(left: AppSpacing.xl, right: 10),
          // Neither child may push the other off the bar. Left to
          // themselves they do: the CTA's label is fixed by SCREENS.md and
          // sizes to its text, so a seven-figure price on a 360pt phone
          // overflows the row — which the phone-width guard in
          // `listing_detail_screen_test.dart` caught.
          //
          // The rule this encodes: the price always keeps at least
          // [_minPriceWidth] and ellipsizes beyond that, and the button
          // gets everything left over, scaling its label down (never
          // truncating it) if that is narrower than the label's natural
          // width. Truncating "Submit an application" to "Submit an appl…"
          // is not an acceptable degradation for the screen's primary
          // action, and neither is a price reading "$ 1,250,00…".
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxButtonWidth =
                  (constraints.maxWidth - _minPriceWidth - AppSpacing.base)
                      .clamp(0.0, constraints.maxWidth);

              return Row(
                children: [
                  Flexible(
                    child: Text(
                      Formatters.price(ad),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.price.copyWith(color: colors.ink),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxButtonWidth),
                    child: _SubmitButton(onTap: onSubmitApplication),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// How much room the price keeps before the CTA starts giving way. Roughly
/// a six-figure price at the bar's type size; past that the price
/// ellipsizes, which is survivable because the full figure also appears
/// un-truncated in the price footer a few lines up the page.
const double _minPriceWidth = 96;

/// `.book` — the accent-gradient pill CTA.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppAccent.gradient,
          borderRadius: BorderRadius.circular(AppRadii.pillButton),
          boxShadow: const [
            BoxShadow(
              color: AppAccent.shadowColor,
              blurRadius: 22,
              spreadRadius: -8,
              offset: Offset(0, 10),
            ),
          ],
        ),
        // scaleDown is a no-op whenever the label fits, which is the normal
        // case — it only engages on the narrow-phone-plus-long-price
        // combination the parent's ConstrainedBox creates, and shrinks the
        // type rather than clipping the spec's fixed copy.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            AppLocalizations.of(context).listingSubmitApplicationButtonLabel,
            maxLines: 1,
            style: type.rowTitle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// SCREENS.md §3.7's second button — see this file's doc comment for why it
/// lives in the content column rather than in the bar. Renders nothing for
/// an agent session, per the spec's literal `role != "agent"` (the same
/// narrower rule the hero's heart follows, via
/// `FavouriteButton.hideForCoworker: false`).
class SaveThePlaceButton extends ConsumerWidget {
  const SaveThePlaceButton({super.key, required this.ad});

  final Ad ad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authSessionProvider).role;
    if (role == UserRole.agent) return const SizedBox.shrink();

    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final isSaved = ref.watch(favouriteAdIdsProvider).contains(ad.id);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(context, ref),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
            border: Border.all(color: colors.line, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSaved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 17,
                color: isSaved ? AppAccent.color : colors.ink2,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                isSaved
                    ? AppLocalizations.of(context).listingSavedButtonLabel
                    : AppLocalizations.of(
                        context,
                      ).listingSaveThePlaceButtonLabel,
                style: type.rowTitle.copyWith(color: colors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(favouriteAdIdsProvider.notifier).toggle(ad.id);
    } on ApiException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).listingFavouriteUpdateErrorMessage,
          ),
        ),
      );
    }
  }
}
