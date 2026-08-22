/// The three slides, with SCREENS.md §3.1's copy quoted character for
/// character. Three implementations are building against this spec; the
/// point of quoting rather than paraphrasing is that they agree, so nothing
/// here should be "improved" without changing the spec first.
///
/// The icons are this build's own choice — §3.1 specifies copy and
/// behaviour but no artwork, and the app ships no illustration assets.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

/// The slide count — fixed regardless of locale (SCREENS.md §3.1 spec's
/// exactly three), so callers that only need the count (page-dot math, the
/// "is this the last slide" check) don't need an [AppLocalizations] just to
/// call [onboardingSlides] and throw the list away.
const int onboardingSlideCount = 3;

// Was a top-level `const List<OnboardingSlide>` before localization — a
// localized string needs a BuildContext/AppLocalizations, which a `const`
// initializer can't provide, so this became a function. Its one caller
// (onboarding_screen.dart) already has a context to read AppLocalizations
// from on every build.
List<OnboardingSlide> onboardingSlides(AppLocalizations l10n) => [
  OnboardingSlide(
    title: l10n.onboardingSlideOneTitle,
    body: l10n.onboardingSlideOneBody,
    icon: Icons.home_work_rounded,
  ),
  OnboardingSlide(
    title: l10n.onboardingSlideTwoTitle,
    body: l10n.onboardingSlideTwoBody,
    icon: Icons.share_rounded,
  ),
  OnboardingSlide(
    title: l10n.onboardingSlideThreeTitle,
    body: l10n.onboardingSlideThreeBody,
    icon: Icons.trending_up_rounded,
  ),
];
