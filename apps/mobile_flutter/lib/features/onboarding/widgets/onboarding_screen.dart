/// `onboarding` (SCREENS.md §3.1) — the three-slide pitch carousel shown
/// once, on first launch.
///
/// Per §3.1: no header, full-bleed slides, dot pagination, **"Skip"**
/// top-right on *every* slide, and **"Get Started"** on the final slide
/// only. Both exits go to `home-feed` and both mark the carousel seen —
/// skipping is a decision, not a deferral, and re-showing it next launch
/// would ignore what the user just told us.
///
/// **Router wiring**: a modal on the root navigator (§1's "Modal
/// (full-screen takeover...)" bucket), so the tab bar is not in its tree.
/// It is reached by `app_router.dart`'s redirect rather than by any
/// `context.push` — nothing in the app navigates *to* onboarding, the app
/// simply starts there when the flag says to. See
/// `onboarding_providers.dart` for how the flag is known synchronously.
///
/// **`PopScope(canPop: false)`**: the back gesture must not dismiss this
/// into an app the user hasn't been introduced to. "Skip" is the exit, and
/// it is on screen at all times.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../data/onboarding_slides.dart';
import '../state/onboarding_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _onLastSlide => _page == onboardingSlides.length - 1;

  void _finish() {
    // Flag first: the router's redirect watches this, and `go`-ing to Home
    // while the flag still said "unseen" would bounce straight back here.
    ref.read(onboardingSeenProvider.notifier).complete();
    context.go(RoutePaths.home);
  }

  void _next() {
    if (_onLastSlide) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _finish,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          'Skip',
                          style: type.label.copyWith(color: colors.muted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemCount: onboardingSlides.length,
                  itemBuilder: (context, index) =>
                      _Slide(slide: onboardingSlides[index]),
                ),
              ),
              _PageDots(count: onboardingSlides.length, active: _page),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  0,
                  AppSpacing.screenGutter,
                  AppSpacing.xl,
                ),
                child: _PrimaryButton(
                  // §3.1 names only the final slide's button ("Get
                  // Started"). A carousel whose only forward affordance is a
                  // swipe strands anyone who doesn't try one, so the earlier
                  // slides carry the same button advancing the page — an
                  // addition to the spec, not a change to it.
                  label: _onLastSlide ? 'Get Started' : 'Next',
                  onTap: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.sunk,
              borderRadius: BorderRadius.circular(AppRadii.cardXl),
            ),
            child: Icon(slide.icon, size: 42, color: AppAccent.color),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: type.heroTitle.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: type.body.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active ? AppAccent.color : colors.line,
              borderRadius: AppRadii.pill,
            ),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppAccent.color,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
          ),
          child: Text(
            label,
            style: type.label.copyWith(color: Colors.white, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
