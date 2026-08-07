/// The three slides, with SCREENS.md §3.1's copy quoted character for
/// character. Three implementations are building against this spec; the
/// point of quoting rather than paraphrasing is that they agree, so nothing
/// here should be "improved" without changing the spec first.
///
/// The icons are this build's own choice — §3.1 specifies copy and
/// behaviour but no artwork, and the app ships no illustration assets.
library;

import 'package:flutter/material.dart';

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

const List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    title: 'Manage every listing in one place',
    body:
        'Keep all your listings organized and easy to access, all in one app.',
    icon: Icons.home_work_rounded,
  ),
  OnboardingSlide(
    title: 'Share to every channel at once',
    body:
        'Publish to Instagram, Telegram and more without leaving the app.',
    icon: Icons.share_rounded,
  ),
  OnboardingSlide(
    title: 'Track leads from first contact to close',
    body:
        'Sort and follow up on every inquiry so nothing slips through.',
    icon: Icons.trending_up_rounded,
  ),
];
