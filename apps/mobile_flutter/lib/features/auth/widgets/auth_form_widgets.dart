/// Shared building blocks for `login` (SCREENS.md §3.12) and `register`
/// (§3.13) — the two screens this directory owns. Both are single-column
/// forms on the same `.glf` flat-glass material every other form in this
/// app already uses: [AuthField]/[AuthVisibilityToggle]/[AuthPrimaryButton]
/// are the same trio as `edit_profile_screen.dart`'s private
/// `_FormField`/`_VisibilityToggle`/`_PrimaryButton` (and, for the button,
/// `contact_sheet.dart`'s `_SendButton`), made public and generalized so two
/// sibling screens in this directory can share one copy instead of each
/// retyping it. Kept inside `features/auth/widgets/` rather than promoted to
/// `shared/` because nothing outside login/register needs it yet — see
/// `shared/shared.dart`'s own doc comment on what earns a promotion.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';

/// `.inp{font-size:13px}` — the value and placeholder step for form
/// inputs, one notch above [LaCasaTypography.body] (12px, which is running
/// prose). No token sits at 13px, so it is stated here once and shared by
/// the input and its hint rather than typed twice at each call site.
TextStyle _inputStyle(LaCasaTypography type) =>
    type.body.copyWith(fontSize: 13);

/// A labelled `.glf` input — mirrors `edit_profile_screen.dart`'s private
/// `_FormField`. [errorText] renders directly under this one field (not a
/// single form-level line, unlike `contact_sheet.dart`) because §3.13's
/// "Email is already registered" (409) is specifically an Email-field
/// error — `mockup-e-liquid-glass.html`'s `register` section puts its own
/// `.err` span in exactly that spot, right under the Email input.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.inputFormatters,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final String? hintText;

  /// A quiet caption under the field with no error connotation — e.g.
  /// "Agency name"'s "shown on the team's listings…" note. Never shown
  /// alongside [errorText]; an error always takes precedence, matching the
  /// spec's own single-message-per-field shape.
  final String? helperText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? trailing;
  final VoidCallback? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// What the platform password manager should offer for this field, e.g.
  /// `[AutofillHints.username, AutofillHints.email]`. **This is the only
  /// thing that registers a field with iOS Keychain / Android Autofill /
  /// 1Password / Bitwarden** — a [TextField] without it is invisible to all
  /// of them, no matter what [keyboardType] says. Nothing in this app set it
  /// before, which meant no credential could be filled *or saved*, and with
  /// `login`'s only self-service recovery being the "Forgot password?" link
  /// (there is still no `POST /auth/forgot-password` — see
  /// `login_screen.dart`) a password nobody's manager ever captured was a
  /// password the user could not get back. Every caller must also sit inside
  /// an [AutofillGroup], which is what tells the platform "these fields are
  /// one credential" and what makes
  /// [TextInput.finishAutofillContext] offer to save on submit.
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassSurface(
          variant: GlassVariant.flatForm,
          // `.inp{height:52px;padding:0 16px;border-radius:18px}` — a
          // stated height, not one derived from the text's own line box.
          height: 52,
          borderRadius: BorderRadius.circular(AppRadii.control),
          // `.pw .eye{position:absolute;right:6px;…;width:40px;height:40px}`
          // — the mockup overlays the eye on the input, so its 40px box sits
          // 6px from the field's edge, not 16px. Laid out in-row here, so
          // the trailing edge drops to 6px whenever a [trailing] control is
          // present and keeps `.inp`'s own 16px otherwise.
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: trailing == null ? AppSpacing.lg : 6,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscureText,
                  inputFormatters: inputFormatters,
                  autofillHints: autofillHints,
                  onChanged: (_) => onChanged?.call(),
                  onSubmitted: onSubmitted,
                  style: _inputStyle(type).copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: _inputStyle(type).copyWith(color: colors.faint),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppStatusColors.errorText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  errorText!,
                  style: type.bodySmall.copyWith(
                    color: AppStatusColors.errorText,
                  ),
                ),
              ),
            ],
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Text(
              helperText!,
              style: type.bodySmall.copyWith(color: colors.faint),
            ),
          ),
        ],
      ],
    );
  }
}

/// The password field's show/hide control — renders identically to
/// `shared/widgets/visibility_toggle.dart`'s `VisibilityToggle` (the
/// promoted form of what `edit_profile_screen.dart` used to keep private);
/// see that file's doc comment for why the two stay separate, and keep the
/// mockup's `.pw .eye` box below in step across both.
class AuthVisibilityToggle extends StatelessWidget {
  const AuthVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onTap,
  });

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: obscured
          ? AppLocalizations.of(context).authVisibilityToggleShowLabel
          : AppLocalizations.of(context).authVisibilityToggleHideLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // `.pw .eye{width:40px;height:40px;border-radius:20px;
        // font-size:17px;color:var(--muted)}` — the mockup gives the eye a
        // button-sized box, not a bare glyph. Stated as a [SizedBox] because
        // `HitTestBehavior.opaque` makes the child's own box the whole
        // tappable region, and an 18px icon alone is under half the 48dp
        // minimum target (same reasoning [AuthCloseButton] records).
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(
              obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: colors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// The accent-gradient submit button both screens end on — "Sign in"
/// (§3.12), "Sign up"/"Create realtor account" (§3.13). Same material as
/// `contact_sheet.dart`'s `_SendButton` (56px tall — this is each screen's
/// one consequential action, the same weight as "Send message").
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.submitting,
    required this.onTap,
  });

  final String label;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: submitting ? null : onTap,
        child: Opacity(
          opacity: submitting ? 0.6 : 1,
          child: Container(
            height: 56,
            width: double.infinity,
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
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: type.rowTitle.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Form-level error line — login's single combined message (§3.12 gives it
/// no per-field split) and register's non-email failures (required fields,
/// phone format, the generic 400 fallback). Same visual language as
/// `contact_sheet.dart`'s inline error row.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.detail});

  final String message;

  /// An optional second line under [message] telling the user what to do
  /// next — today only `login`'s "Forgot it? Tap Forgot password.", pointing
  /// at the recovery link a user who just failed authentication is the one
  /// person who needs.
  ///
  /// It is a separate string, and a separate line, on purpose: SCREENS.md
  /// §3.12 pins "Invalid email or password" character for character across
  /// three implementations, so the pointer cannot be appended to it without
  /// desyncing the other two. Rendered in [LaCasaColors.ink2] rather than
  /// the error red because it is guidance, not a second failure — and
  /// because §10.1 of this run's audit records `muted` as failing WCAG AA in
  /// light mode, so `ink2` is the quiet-text colour to reach for.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 15,
          color: AppStatusColors.errorText,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: type.bodySmall.copyWith(
                  color: AppStatusColors.errorText,
                ),
              ),
              if (detail case final d?) ...[
                const SizedBox(height: 2),
                Text(
                  d,
                  style: type.bodySmall.copyWith(color: colors.ink2),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The informational note both realtor branches of `register` share (§3.13:
/// "Either realtor choice carries the note…") — mirrors the mockup's
/// `.callout gl` treatment (a glass chip, accent-colored icon).
class AuthCallout extends StatelessWidget {
  const AuthCallout({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadii.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.base,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppAccent.color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: type.bodySmall.copyWith(color: colors.ink2),
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular accent-icon badge atop both screens (mockup's `.hero-ic
/// gl`) — 66px, [AppRadii.cardXl] corners, [GlassVariant.onSurface] glass,
/// an accent-colored icon. Not in SCREENS.md's terse §3.12/§3.13 text
/// (which only lists fields/buttons/copy), but every "lead" screen this
/// theme has built so far (`permissions_primer_screen.dart`'s icon rows,
/// `contact_sheet.dart`/`language_sheet.dart`'s chrome) makes the same kind
/// of judgment call for its non-normative visual shell — this is that call
/// for login/register, taken from `mockup-e-liquid-glass.html`'s own
/// `login`/`register` sections (Direction E is what this theme package
/// implements throughout).
class AuthHeroIcon extends StatelessWidget {
  const AuthHeroIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      width: 66,
      height: 66,
      alignment: Alignment.center,
      borderRadius: BorderRadius.circular(AppRadii.cardXl),
      child: Icon(icon, size: 29, color: AppAccent.color),
    );
  }
}

/// The top-right "X" every modal screen in §1's "Modal (full-screen
/// takeover, explicit dismiss…)" bucket needs — the mockup's round
/// `.modal__x` chip: 38px of `.glf` flat glass, a 16px ink glyph.
///
/// This used to be a bare 20px icon, on the argument that
/// `contact_sheet.dart`/`language_sheet.dart` ship the same treatment. Two
/// things overrule that: the mockup governs visual form, and a
/// [HitTestBehavior.opaque] gesture wrapped around a bare 20px glyph makes
/// the *glyph's own box* the entire tappable region — under half the 48dp
/// minimum target. The chip fixes both at once.
class AuthCloseButton extends StatelessWidget {
  const AuthCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).authCloseButtonLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          width: 38,
          height: 38,
          alignment: Alignment.center,
          borderRadius: BorderRadius.circular(19),
          child: Icon(Icons.close_rounded, size: 16, color: colors.ink),
        ),
      ),
    );
  }
}

/// The single-line "already have/don't have an account" navigation prompt
/// under each form's submit button. §3.12 quotes login's half verbatim
/// ("Don't you have an account?" — the entire phrase is the tappable link,
/// exactly as written, with no separate "Sign up" word appended the way
/// `mockup-e-liquid-glass.html` renders it — SCREENS.md's own text is what
/// three independent implementations are meant to agree on, not one
/// mockup's decoration). §3.13 has no reciprocal text at all; `register`'s
/// use of this widget is flagged as a non-spec addition where it's built —
/// see `register_screen.dart`'s doc comment.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Text(
          text,
          style: type.bodySmall.copyWith(
            color: AppAccent.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A two-state selectable chip — glass when unselected, a solid
/// [LaCasaColors.pill]/[LaCasaColors.pillInk] fill when selected. Mirrors
/// the mockup's `.seg`/`.opt` swap (`.seg.on{background:var(--pill)...}`),
/// shared by `register`'s "Realtor type" segmented pair and its "Team size"
/// option row — both are the same interaction (one selection from a short
/// list of labelled pills), so one widget serves both instead of two
/// near-identical copies.
class AuthChip extends StatelessWidget {
  const AuthChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final text = Text(
      label,
      style: type.bodySmall.copyWith(
        color: selected ? colors.pillInk : colors.ink,
        fontWeight: FontWeight.w600,
      ),
    );

    final child = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.base,
      ),
      child: text,
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: selected
            ? Container(
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: AppRadii.pill,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99151517),
                      blurRadius: 18,
                      spreadRadius: -8,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              )
            : GlassSurface(borderRadius: AppRadii.pill, child: child),
      ),
    );
  }
}

/// The two account-type cards ("Buyer"/"Realtor") atop `register` — the
/// mockup's `.pick` tile: an icon chip, a title and a one-line subtitle,
/// glass when unselected and a solid pill fill when selected (same swap
/// [AuthChip] uses, just in a taller card shape since these two carry a
/// subtitle `.seg`/`.opt` don't).
class AuthPickCard extends StatelessWidget {
  const AuthPickCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // `.pick{padding:13px 12px}`
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.pillInk : colors.sunk,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              icon,
              size: 17,
              color: selected ? colors.pill : colors.ink,
            ),
          ),
          // `.pick__ic{margin-bottom:10px}`
          const SizedBox(height: 10),
          Text(
            title,
            style: type.pickSubtitle.copyWith(
              color: selected ? colors.pillInk : colors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: type.bodySmall.copyWith(
              color: selected
                  ? colors.pillInk.withValues(alpha: 0.62)
                  : colors.muted,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: selected
            ? Container(
                decoration: BoxDecoration(
                  color: colors.pill,
                  // `.picks .pick{border-radius:22px}` — AppRadii.cardLg
                  // names this exact element.
                  borderRadius: BorderRadius.circular(AppRadii.cardLg),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99151517),
                      blurRadius: 22,
                      spreadRadius: -10,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: content,
              )
            : GlassSurface(
                borderRadius: BorderRadius.circular(AppRadii.cardLg),
                child: content,
              ),
      ),
    );
  }
}

/// A full-screen submitting overlay — §3.13's literal "Full-screen spinner
/// while submitting" for `register` (§3.12 has no such instruction for
/// `login`, which instead uses [AuthPrimaryButton]'s own inline spinner,
/// the same as every other form in this app). [AbsorbPointer] blocks every
/// tap underneath so a second submit/edit can't race the one in flight.
class AuthFullScreenSpinner extends StatelessWidget {
  const AuthFullScreenSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: colors.screen.withValues(alpha: 0.72),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppAccent.color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
