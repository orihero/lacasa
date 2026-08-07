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
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import 'auth_form_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
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

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Required fields are not filled');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    try {
      await ref
          .read(authSessionProvider.notifier)
          .signInWithPassword(email: email, password: password);
      if (!mounted) return;
      context.go(RoutePaths.home);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User successfully logged in.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(e);
        _submitting = false;
      });
    }
  }

  static String _messageFor(ApiException e) {
    if (e is ApiErrorException) {
      return switch (e.code) {
        ApiErrorCode.invalidCredentials => 'Invalid email or password',
        // §3.12's fallback: "the server's validation message". Every other
        // code (chiefly `validation`) surfaces what the server actually
        // said rather than a copy invented here.
        _ => e.message,
      };
    }
    if (e is NetworkException) {
      return 'No connection. Check your network and try again.';
    }
    return 'Something went wrong';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.md,
            AppSpacing.screenGutter,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: AuthCloseButton(onTap: _dismiss),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AuthHeroIcon(icon: Icons.lock_outline_rounded),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome back',
                style: type.displayLead.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.section),
              AuthField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.base),
              AuthField(
                label: 'Password',
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                trailing: AuthVisibilityToggle(
                  obscured: _obscurePassword,
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.base),
                AuthErrorBanner(message: error),
              ],
              const SizedBox(height: AppSpacing.section),
              AuthPrimaryButton(
                label: 'Sign in',
                submitting: _submitting,
                onTap: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: AuthFooterLink(
                  text: "Don't you have an account?",
                  onTap: () => context.push(RoutePaths.register),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
