/// `saved-listings` (SCREENS.md §3.17) — header "Saved Listings", a back
/// arrow, and [SavedListingsGrid].
///
/// **Router wiring**: SCREENS.md §1 buckets `saved-listings` under "Pushed
/// (full-screen, back-stack)", reached only from `profile-buyer`
/// (§15: "Saved Listings" → `saved-listings`) — so, exactly like
/// `AgentProfileScreen`, it takes a [branchPrefix] (defaulting to
/// `RoutePaths.profile`, the only branch that ever opens it) rather than
/// living on the root navigator, and any listing it opens must resolve back
/// into that same branch.
///
/// **Known integration gap**: `route_paths.dart` declares
/// `RoutePaths.profileSaved` (`/profile/saved`) but, as of this task,
/// `app_router.dart` has no `listing/:id` child route under
/// `RoutePaths.profile` the way `/agents`, `/home` and `/search` each do —
/// only those three branches currently declare one (see
/// `route_paths.dart`'s `agentsListingDetail`/`homeListingDetail`/
/// `searchListingDetail`). Tapping a card here pushes
/// `'$branchPrefix/listing/$adId'` per that same convention; the integration
/// step wiring this screen into the Profile branch needs to add that child
/// route too, or the push 404s. Flagged rather than worked around, since
/// `app_router.dart` is out of this task's ownership.
///
/// **Signed-out deep link (this task's other explicit judgment call)**:
/// SCREENS.md only ever links here from `profile-buyer`, so a normal user
/// never reaches this screen signed out — but a deep link/restored route can.
/// `GET /api/saved-ads` requires auth (`saved_ads_resource.dart`), so
/// fetching anyway would just surface a 401 dressed up as a generic load
/// error, indistinguishable from a real outage. Rendering the ordinary empty
/// grid instead ("You haven't saved any listings yet.") would be worse: it
/// tells a signed-out visitor they have looked and found nothing, which is
/// not true — they were never asked. This screen checks
/// `authSessionProvider.isSignedIn` before ever reading
/// [savedListingsProvider] and shows a dedicated sign-in prompt instead,
/// with its own copy (SCREENS.md defines no string for this exact case, so
/// this is written to match the app's voice rather than quoted from §3.17).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import 'saved_listings_grid.dart';

class SavedListingsScreen extends ConsumerWidget {
  const SavedListingsScreen({
    super.key,
    this.branchPrefix = RoutePaths.profile,
  });

  /// The tab branch this screen was pushed into — see this file's doc
  /// comment. Defaults to Profile, the only branch §1/§15 ever open it from.
  final String branchPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final isSignedIn = ref.watch(
      authSessionProvider.select((state) => state.isSignedIn),
    );

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NavRow(onBack: () => _pop(context)),
            Expanded(
              child: isSignedIn
                  ? SavedListingsGrid(
                      onOpenListing: (adId) =>
                          context.push('$branchPrefix/listing/$adId'),
                    )
                  : _SignedOutState(
                      onSignIn: () => context.push(RoutePaths.login),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    // Same reasoning as `agent_profile_screen.dart`'s: a deep link straight
    // into this screen has nothing to pop, and that is not an error — "up"
    // is just the Profile tab rather than "back".
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.profile);
    }
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 22,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Saved Listings',
              overflow: TextOverflow.ellipsis,
              style: type.navTitle.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// The deep-link-while-signed-out state — see this file's doc comment for
/// why this is a distinct state from the ordinary empty grid.
class _SignedOutState extends StatelessWidget {
  const _SignedOutState({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: colors.faint,
              size: 36,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Sign in to see your saved listings.',
              textAlign: TextAlign.center,
              style: type.body.copyWith(color: colors.ink2),
            ),
            const SizedBox(height: AppSpacing.base),
            GestureDetector(
              onTap: onSignIn,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.base,
                ),
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  'Sign In',
                  style: type.label.copyWith(color: colors.pillInk),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
