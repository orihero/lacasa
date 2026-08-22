/// `login` (SCREENS.md §3.12) — "Sign In". A root-navigator modal (§1's
/// "Modal (full-screen takeover, explicit dismiss, tab bar hidden)"
/// bucket), reached at `RoutePaths.login` from the Profile tab
/// (`profile-signed-out`) and any "Sign in" link elsewhere in the app.
///
/// **Fields, button and link text are quoted from §3.12 character for
/// character**: "Email", "Password", "Sign in", "Don't you have an
/// account?" — that last one is the *entire* tappable link, with no
/// separate "Sign up" word appended (see `auth_form_widgets.dart`'s
/// [AuthFooterLink] doc comment for why this reading was chosen over
/// `mockup-e-liquid-glass.html`'s own decoration).
///
/// **Error copy**: `ApiErrorCode.invalidCredentials` (401) always renders
/// as §3.12's fixed "Invalid email or password", regardless of what the
/// server's own message text happens to say (the two already coincide —
/// see `apps/api/src/routes/auth.js` — but the spec pins the copy, not the
/// coincidence). Every other [ApiErrorException] (chiefly `validation`,
/// 400) surfaces the server's own message verbatim, per §3.12's "or the
/// server's validation message". A required-fields check runs first,
/// client-side, before any request — same reasoning `contact_sheet.dart`
/// documents (a round trip to be told a field is empty is a round trip
/// that didn't need to happen) — reusing that file's own "Required fields
/// are not filled" wording, since §3.12 specifies no message of its own
/// for this case and this codebase already has exactly one convention for
/// it.
///
/// **Submission goes through `AuthSessionNotifier.signInWithPassword`**
/// (`lib/navigation/auth_session.dart`), not `AuthRepository.login`
/// directly — that command both calls the repository and applies the
/// result to `authSessionProvider`, so every screen reading session state
/// (the tab bar's role-aware set among them) updates the instant this one
/// succeeds, with no separate `signIn` call needed here.
///
/// **Success**: §3.12 says "dismiss to `home-feed`" — read as `context.go
/// (RoutePaths.home)` rather than a plain pop, since this modal can be
/// reached from places other than Home (a push from `profile-signed-out`,
/// say) and the spec names a fixed destination, not "wherever this came
/// from". The toast is shown immediately after that navigation call, same
/// order `contact_sheet.dart` uses for its own success path.
///
/// **No spinner instruction for `login`** (contrast §3.13's explicit
/// "Full-screen spinner while submitting" for `register`) — this screen
/// uses [AuthPrimaryButton]'s own inline busy state instead, the same
/// convention every other form-with-one-button screen in this app already
/// uses (`contact_sheet.dart`, `edit_profile_screen.dart`).
///
/// **Both fields start empty**, exactly as `register_screen.dart`'s six do.
/// An earlier revision seeded them with the credentials of the approved
/// `AGENT` account `prisma/seed-olx.js` creates, suppressed only under
/// `flutter test` — so every debug, profile *and* release build opened this
/// screen holding a working password for somebody else's account, unlabelled
/// as a demo value. Beyond handing that account to anyone who launched the
/// app, it made the screen actively misleading: typing an email over the
/// prefilled one left the prefilled *password* in place underneath, and the
/// only feedback was §3.12's "Invalid email or password" — a message that
/// describes credentials the user never entered. §3.12 specifies no initial
/// field contents, and an empty form is the only reading of that which
/// cannot lie to the user, so do not reintroduce a prefill here: a manual
/// tester who wants one tap can use the platform password manager, which is
/// what the obscured, `TextInputAction.done` password field is already
/// shaped for — and, as of this revision, actually wired to (see below).
///
/// ## The debug-only shortcut on the hero icon
///
/// The ban above is on a *prefill*, and it stands. What replaced the need
/// for one is a hidden gesture on the hero lock: five taps signs in as
/// `prisma/seed-olx.js`'s seeded agent, a three-second press as its seeded
/// buyer (`_DevSignInGestures`, `_devSignInAs`).
///
/// It avoids all three faults of the prefill it substitutes for.
/// **It cannot ship**: the gesture detector is behind [kDebugMode] and is
/// absent from the widget tree entirely in profile and release builds, where
/// the old prefill — guarded only by `flutter test` — was present in every
/// one. **It cannot be stumbled into**: five taps inside a two-second window,
/// or a press five times longer than [kLongPressTimeout], on an icon that
/// looks like decoration. And **it cannot lie**: it writes the credentials
/// into the visible fields at the moment it uses them, so the form always
/// shows what was actually submitted, which is precisely what the prefill
/// stopped doing as soon as the user typed over one field and not the other.
///
/// ## Password recovery (this run's §7.4)
///
/// This screen used to offer exactly three exits — submit, the Sign Up link,
/// and the close "X" — with the invalid-credentials message as a terminal
/// string. A user who forgot their password was locked out permanently: the
/// only remaining move was a second account under a different email, which
/// is not a move at all for an agent whose listings, leads and coworkers all
/// hang off the original one.
///
/// **There is no self-service reset to link to.** `apps/api/src/routes/
/// auth.js` exposes `register`, `login` and `me` and nothing else — no
/// `POST /auth/forgot-password`, no token mail, no reset screen anywhere in
/// this app. So the "Forgot password?" link opens [showContactSheet]
/// (SCREENS.md §3.11), the one real support channel the product has, with
/// the message pre-filled from whatever the user already typed into the
/// Email field. That is a human-in-the-loop reset rather than an automated
/// one, but it is a route out, which is the thing that was missing.
///
/// **Swap target, for whoever lands the endpoint**: replace
/// [_LoginScreenState._openForgotPassword]'s `showContactSheet` call with a
/// push to the reset screen the moment `POST /auth/forgot-password` exists;
/// the link, its label (`authLoginForgotPasswordLinkLabel`) and the
/// invalid-credentials pointer under the error banner
/// (`authLoginForgotPasswordHintMessage`) all stay exactly as they are.
///
/// ## Password managers (this run's §7.8)
///
/// The whole form is an [AutofillGroup] and both fields carry
/// [AutofillHints] — without those, nothing in this app was fillable *or
/// saveable* by iOS Keychain, Android Autofill, 1Password or Bitwarden, which
/// is what made the missing reset flow above permanent rather than merely
/// annoying. [TextInput.finishAutofillContext] fires after a *successful*
/// sign-in only: it is the call that prompts the platform to save the
/// credential, and prompting to save one that was just rejected would train
/// users to store a wrong password.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../contact/contact.dart';
import 'auth_form_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Empty in every build mode — see the file doc comment for why there is
  // no build-mode-dependent prefill here any more.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  /// The second line under [_error] — set only for
  /// [ApiErrorCode.invalidCredentials], the one failure "Forgot password?"
  /// is the answer to. See [AuthErrorBanner.detail].
  String? _errorDetail;

  @override
  void dispose() {
    _devTapTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// The "X" — an explicit dismiss with nowhere fixed to land, unlike a
  /// successful sign-in. Pops back to whatever pushed this modal when there
  /// is something to pop back to (the ordinary case); falls back to Home
  /// only for a bare deep link straight into `/login`, matching
  /// `permissions_primer_screen.dart`'s/`edit_profile_screen.dart`'s
  /// identical fallback for the same reason.
  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;

    // Captured once, up front, so every later use is safe regardless of the
    // `context.go` navigation and `mounted` re-check below — same reasoning
    // `agent_review_sheet.dart`'s `_submit` documents for its own `l10n`.
    final l10n = AppLocalizations.of(context);

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = l10n.authLoginRequiredFieldsError;
        _errorDetail = null;
      });
      return;
    }

    await _signIn(email: email, password: password, offerToSave: true);
  }

  /// The sign-in itself, shared by [_submit] and the debug-only shortcut on
  /// the hero icon ([_devSignInAs]). Split out so the shortcut inherits the
  /// real screen's busy state, error banner and post-login navigation rather
  /// than growing a second, quieter copy of them that could drift.
  ///
  /// [offerToSave] is the one thing the two callers disagree about: a
  /// human-typed credential should reach the platform password manager's
  /// save prompt, and a hardcoded seed credential should not — see the file
  /// doc comment's §7.8 section for the rule it is applying.
  Future<void> _signIn({
    required String email,
    required String password,
    required bool offerToSave,
  }) async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _error = null;
      _errorDetail = null;
      _submitting = true;
    });

    try {
      await ref
          .read(authSessionProvider.notifier)
          .signInWithPassword(email: email, password: password);
      if (!mounted) return;
      // Only after a credential the server accepted — see the file doc
      // comment on why a rejected one must never reach the save prompt.
      if (offerToSave) TextInput.finishAutofillContext();
      context.go(RoutePaths.home);
      LaCasaToast.showSuccess(context, l10n.authLoginSuccessToast);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(l10n, e);
        _errorDetail =
            e is ApiErrorException &&
                e.code == ApiErrorCode.invalidCredentials
            ? l10n.authLoginForgotPasswordHintMessage
            : null;
        _submitting = false;
      });
    }
  }

  /// How many taps on the hero icon sign in as the seeded agent, and how
  /// long a press signs in as the seeded buyer. Both from the request that
  /// introduced this; the tap count is high enough that no ordinary user
  /// reaches it by accident on a decorative icon.
  static const int _devTapsForAgent = 5;
  static const Duration _devPressForBuyer = Duration(seconds: 3);

  /// A run of taps is only a *run* while they keep coming. Without this, a
  /// single stray tap today plus four more tomorrow would eventually add up
  /// to a sign-in nobody asked for.
  ///
  /// Enforced with a [Timer] rather than by comparing [DateTime.now] between
  /// taps, because a timer is the version a widget test can actually drive:
  /// `tester.pump(duration)` advances the fake async clock that schedules
  /// timers and does nothing at all to the wall clock, so the wall-clock
  /// version of this rule would have been permanently unasserted.
  static const Duration _devTapWindow = Duration(seconds: 2);

  int _devTapCount = 0;
  Timer? _devTapTimer;

  /// Counts taps on the hero lock and signs in as the seeded agent on the
  /// [_devTapsForAgent]th. Debug builds only — see [_devSignInAs].
  void _onDevTap() {
    _devTapTimer?.cancel();
    _devTapCount++;

    if (_devTapCount >= _devTapsForAgent) {
      _devTapCount = 0;
      _devSignInAs(_devAgentEmail);
      return;
    }

    _devTapTimer = Timer(_devTapWindow, () => _devTapCount = 0);
  }

  /// `prisma/seed-olx.js`'s accounts, all on `password123`. Renaming either
  /// account there means changing it here — the seed file's own comments say
  /// so on both sides.
  static const String _devAgentEmail = 'agent@lacasa.dev';
  static const String _devBuyerEmail = 'user@lacasa.dev';
  static const String _devPassword = 'password123';

  /// Signs in as one of the seeded accounts, filling the visible fields
  /// first.
  ///
  /// **Filling the fields is deliberate, not laziness.** The prefill this
  /// screen used to carry is described at the top of this file as a lie the
  /// user could not see through; the fix for that was an empty form, and a
  /// shortcut that signed in from nowhere would reintroduce the same
  /// invisibility from the other direction. Here the credentials appear in
  /// the fields at the moment they are used, so a failed dev sign-in shows
  /// exactly which account was tried — and the ordinary error banner
  /// explains the rest.
  ///
  /// Callers are already behind [kDebugMode]; the assert makes that a
  /// contract of the method rather than of its call sites.
  void _devSignInAs(String email) {
    assert(kDebugMode, 'the dev sign-in shortcut must never run outside debug');
    if (_submitting) return;
    _email.text = email;
    _password.text = _devPassword;
    _signIn(email: email, password: _devPassword, offerToSave: false);
  }

  /// The only route out of a forgotten password this product currently has —
  /// see the file doc comment for why it is the contact sheet and not a
  /// reset endpoint, and for the swap to make when one exists.
  ///
  /// The typed email is carried into the message so support can act on the
  /// request without a round trip asking which account it is; a user who
  /// taps the link before typing anything gets the same request with the
  /// account left unnamed rather than a sentence with an empty quote in it.
  void _openForgotPassword() {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();

    showContactSheet(
      context,
      prefill: ContactPrefill(
        message: email.isEmpty
            ? l10n.authLoginForgotPasswordContactMessageNoEmail
            : l10n.authLoginForgotPasswordContactMessage(email),
      ),
    );
  }

  /// Takes [AppLocalizations] as a parameter rather than a `BuildContext` —
  /// see `agent_review_sheet.dart`'s identically-shaped `_messageFor` for
  /// why (a pure function fed the `l10n` its caller already captured, not
  /// one that re-derives it from a context that may be stale by the time an
  /// error lands).
  static String _messageFor(AppLocalizations l10n, ApiException e) {
    if (e is ApiErrorException) {
      return switch (e.code) {
        ApiErrorCode.invalidCredentials =>
          l10n.authLoginInvalidCredentialsError,
        // §3.12's fallback: "the server's validation message". Every other
        // code (chiefly `validation`) surfaces what the server actually
        // said rather than a copy invented here.
        _ => e.message,
      };
    }
    if (e is NetworkException) {
      return l10n.authLoginNetworkErrorMessage;
    }
    return l10n.authLoginGenericErrorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        // `.modal__x` is positioned, not laid out: it overlays the hero
        // icon's own band at the top right instead of taking a row above
        // it and pushing the whole form down.
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                AppSpacing.xl,
              ),
              // Everything below is one credential as far as the platform
              // password manager is concerned — see the file doc comment's
              // §7.8 section.
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DevSignInGestures(
                      onTap: _onDevTap,
                      onLongPress: () => _devSignInAs(_devBuyerEmail),
                      child: const AuthHeroIcon(
                        icon: Icons.lock_outline_rounded,
                      ),
                    ),
                    // `.hero-ic{margin-bottom:20px}`
                    const SizedBox(height: AppSpacing.section),
                    Text(
                      l10n.authLoginWelcomeHeading,
                      style: type.displayLead.copyWith(color: colors.ink),
                    ),
                    // `.lead__p{margin-top:10px}` — 12/400 in `--muted`.
                    const SizedBox(height: 10),
                    Text(
                      l10n.authLoginLeadBody,
                      style: type.body.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    AuthField(
                      label: l10n.authLoginEmailFieldLabel,
                      controller: _email,
                      hintText: l10n.authEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      // `username` first: it is the hint every manager keys
                      // its saved-credential lookup on, and `email` alone
                      // gets a contact-card fill rather than a login on iOS.
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                    ),
                    // `.field{margin-top:15px}` — AppSpacing.lg's documented
                    // 14–16px band, not the 12px list-row gap.
                    const SizedBox(height: AppSpacing.lg),
                    AuthField(
                      label: l10n.authLoginPasswordFieldLabel,
                      controller: _password,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.password],
                      trailing: AuthVisibilityToggle(
                        obscured: _obscurePassword,
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    // Directly under the field it recovers, where a user who
                    // has just failed to remember a password is already
                    // looking — not buried under the submit button.
                    const SizedBox(height: AppSpacing.base),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AuthFooterLink(
                        key: const ValueKey('loginForgotPasswordLink'),
                        text: l10n.authLoginForgotPasswordLinkLabel,
                        onTap: _openForgotPassword,
                      ),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: AppSpacing.base),
                      AuthErrorBanner(
                        key: const ValueKey('loginErrorBanner'),
                        message: error,
                        detail: _errorDetail,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.section),
                    AuthPrimaryButton(
                      label: l10n.authLoginSubmitButtonLabel,
                      submitting: _submitting,
                      onTap: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: AuthFooterLink(
                        text: l10n.authLoginFooterLinkText,
                        onTap: () => context.push(RoutePaths.register),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: AppSpacing.screenGutter,
              child: AuthCloseButton(onTap: _dismiss),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps the hero lock in the debug-only sign-in shortcut: five taps for the
/// seeded agent, a three-second press for the seeded buyer.
///
/// **Outside [kDebugMode] this returns the child untouched** — no
/// recognisers, no listener, nothing in the tree at all. That is the whole
/// safety story: a hidden gesture that signs anybody in with credentials
/// published in a seed script is a backdoor in a shipped build, however
/// obscure the gesture is, and the seeded emails are as likely to exist on a
/// staging server as on a laptop. Compiling it out is the only version of
/// this that cannot be reached by a user who guesses.
///
/// [RawGestureDetector] rather than [GestureDetector] because the long-press
/// duration has to be 3 seconds and [GestureDetector] does not expose one —
/// it hardcodes [kLongPressTimeout] (500ms), which on a decorative icon is
/// short enough for an ordinary press-and-look to trigger. Both recognisers
/// share the arena, which is exactly the behaviour wanted: release early and
/// the tap wins, hold past 3 seconds and the long press claims the gesture
/// and the tap is rejected, so one press can never count as both.
class _DevSignInGestures extends StatelessWidget {
  const _DevSignInGestures({
    required this.child,
    required this.onTap,
    required this.onLongPress,
  });

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;

    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              TapGestureRecognizer.new,
              (recognizer) => recognizer.onTap = onTap,
            ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(
                duration: _LoginScreenState._devPressForBuyer,
              ),
              (recognizer) => recognizer.onLongPress = onLongPress,
            ),
      },
      child: child,
    );
  }
}
