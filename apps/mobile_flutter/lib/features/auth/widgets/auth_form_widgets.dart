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
          borderRadius: BorderRadius.circular(AppRadii.control),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
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
                  onChanged: (_) => onChanged?.call(),
                  onSubmitted: onSubmitted,
                  style: type.body.copyWith(color: colors.ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: hintText,
                    hintStyle: type.body.copyWith(color: colors.faint),
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

/// The password field's show/hide control — identical to
/// `edit_profile_screen.dart`'s private `_VisibilityToggle`.
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
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.sm),
          child: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 18,
            color: colors.muted,
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
                : Text(label, style: type.rowTitle.copyWith(color: Colors.white)),
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
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
          child: Text(
            message,
            style: type.bodySmall.copyWith(color: AppStatusColors.errorText),
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
          const Icon(Icons.info_outline_rounded, size: 15, color: AppAccent.color),
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
/// takeover, explicit dismiss…)" bucket needs. Deliberately a bare icon,
/// not the mockup's round glass `.modal__x` chip — this matches the two
/// close controls already shipped in this codebase
/// (`contact_sheet.dart`/`language_sheet.dart`'s identical
/// `Icons.close_rounded`, same treatment), which is a stronger consistency
/// signal within this Flutter build than one more HTML mockup's own choice.
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
        child: Icon(Icons.close_rounded, size: 20, color: colors.ink2),
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

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
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
          const SizedBox(height: AppSpacing.base),
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
              color: selected ? colors.pillInk.withValues(alpha: 0.62) : colors.muted,
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
                  borderRadius: BorderRadius.circular(AppRadii.cardXl),
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
                borderRadius: BorderRadius.circular(AppRadii.cardXl),
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
