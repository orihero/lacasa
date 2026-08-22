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

import '../../../l10n/generated/app_localizations.dart';
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

  bool get _onLastSlide => _page == onboardingSlideCount - 1;

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
    final l10n = AppLocalizations.of(context);
    final slides = onboardingSlides(l10n);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.screen,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) => setState(() => _page = index),
                      itemCount: slides.length,
                      itemBuilder: (context, index) =>
                          _Slide(slide: slides[index]),
                    ),
                    // `.onb__skip{position:absolute;top:62px;right:20px}`
                    // floats *over* the slide rather than taking a row of
                    // its own above it. 62 less the mockup's own
                    // `.sb{height:54px}` status bar — the inset SafeArea has
                    // already eaten — leaves the 8px gap below it.
                    Positioned(
                      top: 8,
                      right: AppSpacing.screenGutter,
                      child: Semantics(
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _finish,
                          child: GlassSurface(
                            height: 34,
                            alignment: Alignment.center,
                            borderRadius: BorderRadius.circular(17),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            child: Text(
                              l10n.onboardingSkipButtonLabel,
                              // `.onb__skip{font-size:11.5px;font-weight:
                              // 600}`. Rendered in `ink`, not the mockup's
                              // white: these slides have no photography
                              // under them (see `_Slide`), so white would
                              // be invisible on `colors.screen`.
                              style: type.bodySmall.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // `.dots{margin:21px 0}` — equal rhythm above and below.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 21),
                child: _PageDots(count: slides.length, active: _page),
              ),
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
                  label: _onLastSlide
                      ? l10n.onboardingGetStartedButtonLabel
                      : l10n.onboardingNextButtonLabel,
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

    // `.onb__body{position:absolute;left:0;right:0;bottom:28px;padding:0
    // 26px}` — the copy block is anchored to the bottom of the slide, not
    // centred in it. The icon tile stays: it is this build's stand-in for
    // the mockup's full-bleed slide photography, which the app ships no
    // assets for (see `onboarding_slides.dart`).
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
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
            // `.onb__h{font-size:25.5px;line-height:1.3;letter-spacing:
            // -.5px}` — LaCasaTypography.display, exactly.
            style: type.display.copyWith(color: colors.ink),
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
            // `.dot{width:6px;height:6px;background:rgba(255,255,255,.4)}`,
            // `.dot.on{width:21px}`, in a row with a 5px gap. The inactive
            // fill is `glyphTrack`, the opaque-surface analogue of that 40%
            // white: these slides carry no photography (see `_Slide`), and
            // the hairline `line` token is too pale to read on a 6px dot.
            //
            // It was `faint` until that token became a 4.5:1-floor *text*
            // color, at which point the inactive dots measured 4.58:1 on
            // `screen` against the active dot's 3.16:1 — the "you are here"
            // marker was the quietest thing in the row. `glyphTrack` exists
            // for exactly this; see `LaCasaColors.glyphTrack`.
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: i == active ? 21 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? AppAccent.color : colors.glyphTrack,
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
          // The mockup's `.btn-w` is a *white* pill in a glass tray,
          // because it sits on slide photography. These slides sit on
          // `colors.screen` instead (no artwork ships with the app), where
          // a white pill would disappear — so this takes the app's other
          // primary-button material, `.btn--acc`'s accent gradient and
          // glow, the same one `auth_form_widgets.dart` uses. Revisit if
          // full-bleed slide media ever lands.
          decoration: BoxDecoration(
            gradient: AppAccent.gradient,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
            boxShadow: AppShadows.accentGlow,
          ),
          child: Text(
            label,
            // `.btn-w{font-size:14.5px;font-weight:600;letter-spacing:.1px}`
            style: type.rowTitle.copyWith(
              color: Colors.white,
              fontSize: 14.5,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
