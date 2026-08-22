/// `permissions-primer` (SCREENS.md §3.2) — the "why we're about to ask"
/// screen shown before the first photo upload or push opt-in.
///
/// Header, both row titles, both row bodies, and all three button labels are
/// quoted from §3.2 character for character, trailing full stops included
/// (the spec's own two rows are inconsistent about that — one has one, one
/// doesn't — and that inconsistency is preserved rather than tidied, so
/// three implementations building from the spec produce the same strings).
///
/// **Router wiring**: a modal on the root navigator (§1's "Modal
/// (full-screen takeover, explicit dismiss, tab bar hidden)" bucket), so the
/// tab bar is not in its tree. §3.2's **"Continue"** returns "to the screen
/// that triggered it", which is a pop, not a `go` — this screen is always
/// pushed by whatever is about to need the permission and has no
/// destination of its own.
///
/// **"Allow" raises the real OS prompt for Camera & Photos** — see
/// `data/permission_gateway.dart` for the gateway that does it and why
/// Notifications still answers [PermissionOutcome.unavailable] instead
/// (no manifest declaration, no push infrastructure to grant access to).
/// Every reachable outcome — granted, limited, denied, permanently-denied,
/// unavailable — gets its own honest row state; nothing here implies a
/// dialog appeared when it didn't, or that a refusal is fixable in-app when
/// it isn't.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../data/permission_gateway.dart';
import '../state/permission_gateway_provider.dart';

class PermissionsPrimerScreen extends ConsumerStatefulWidget {
  const PermissionsPrimerScreen({super.key});

  @override
  ConsumerState<PermissionsPrimerScreen> createState() =>
      _PermissionsPrimerScreenState();
}

class _PermissionsPrimerScreenState
    extends ConsumerState<PermissionsPrimerScreen>
    with WidgetsBindingObserver {
  /// Per-row result of the last grant attempt or re-check. Absent means
  /// "not asked yet", which is a third state distinct from denied and
  /// unavailable.
  final Map<AppPermission, PermissionOutcome> _outcomes = {};

  @override
  void initState() {
    super.initState();
    // Only foreground *returns* re-check (below) — not this initState.
    // Calling `check` here would fire the plugin the instant this modal
    // mounts, for a status nobody asked about yet; the row is meant to
    // start blank until the user taps "Allow".
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckOutstanding();
    }
  }

  /// A user who left for Settings (from a [PermissionOutcome.limited] or
  /// [PermissionOutcome.permanentlyDenied] row) must see the row update on
  /// return without restarting the app. Re-checks only rows this screen has
  /// already asked about and that weren't already a dead end either way:
  /// [PermissionOutcome.unavailable] has no backend to re-check, and
  /// [PermissionOutcome.granted] cannot regress by leaving the app.
  Future<void> _recheckOutstanding() async {
    // A gateway without a status half (see `PermissionStatusGateway`'s doc
    // comment) has nothing this can call — nothing to re-check, silently.
    // `case` rather than `is`/`as` because [PermissionStatusGateway] isn't
    // a subtype of [PermissionGateway] — Dart only promotes a local
    // variable's type through a pattern match, not a bare `is` test,
    // when the tested type sits outside the variable's declared hierarchy.
    if (ref.read(permissionGatewayProvider)
        case final PermissionStatusGateway gateway) {
      for (final entry in Map.of(_outcomes).entries) {
        if (entry.value == PermissionOutcome.unavailable ||
            entry.value == PermissionOutcome.granted) {
          continue;
        }
        final outcome = await gateway.check(entry.key);
        if (!mounted) return;
        setState(() => _outcomes[entry.key] = outcome);
      }
    }
  }

  Future<void> _request(AppPermission permission) async {
    final outcome = await ref
        .read(permissionGatewayProvider)
        .request(permission);
    if (!mounted) return;
    setState(() => _outcomes[permission] = outcome);
  }

  /// [PermissionOutcome.limited] and [PermissionOutcome.permanentlyDenied]
  /// both route here — it's the only lever this screen has left to offer
  /// once the OS itself refuses to raise another in-app prompt. Reachable
  /// only from rows whose outcome came from a [PermissionStatusGateway] in
  /// the first place (see that class's doc comment), so the gateway here is
  /// always capable in practice; the type check just keeps this callable
  /// without a cast.
  Future<void> _openSettings() async {
    if (ref.read(permissionGatewayProvider)
        case final PermissionStatusGateway gateway) {
      await gateway.openSettings();
      // No further state change here: whether the settings page actually
      // opened or the user changed anything is unknowable until they come
      // back, which `_recheckOutstanding` (via app-resumed) handles.
    }
  }

  /// §3.2's "Not now" — dismisses without asking for anything. Recorded as
  /// [PermissionOutcome.denied] for both rows rather than left blank: the
  /// user answered the question this screen asked, and the answer was no.
  void _notNow() {
    setState(() {
      for (final permission in AppPermission.values) {
        _outcomes[permission] = PermissionOutcome.denied;
      }
    });
    _continue();
  }

  void _continue() {
    // §3.2: "returns to the screen that triggered it". A pop, not a `go` —
    // there is no fixed destination. The Home fallback only covers a deep
    // link straight to this route, which has nothing to return to.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              // The mockup's `.hero-ic gl` — a 66px glass badge with an
              // accent sparkle, the same shape `login`/`register` use
              // (`auth_form_widgets.dart`'s `AuthHeroIcon`), followed by
              // its own 20px bottom margin.
              GlassSurface(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                borderRadius: BorderRadius.circular(AppRadii.cardXl),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 29,
                  color: AppAccent.color,
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              Text(
                // §3.2's header, with its ellipsis character. `.lead`
                // (23px) — not `.hero`/`.nav__t`.
                l10n.permissionsHeaderTitle,
                style: type.displayLead.copyWith(color: colors.ink),
              ),
              // `.lead__p{margin-top:10px;font-size:12px;line-height:1.65;
              // color:var(--muted)}` — `type.body` is that rule exactly.
              const SizedBox(height: 10),
              Text(
                l10n.permissionsPrimerLeadBody,
                style: type.body.copyWith(color: colors.muted),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _PermissionRow(
                icon: Icons.photo_camera_outlined,
                title: l10n.permissionsCameraRowTitle,
                body: l10n.permissionsCameraRowBody,
                outcome: _outcomes[AppPermission.cameraAndPhotos],
                onAllow: () => _request(AppPermission.cameraAndPhotos),
                onOpenSettings: _openSettings,
              ),
              const SizedBox(height: AppSpacing.base),
              _PermissionRow(
                icon: Icons.notifications_none_rounded,
                title: l10n.permissionsNotificationsRowTitle,
                body: l10n.permissionsNotificationsRowBody,
                outcome: _outcomes[AppPermission.notifications],
                onAllow: () => _request(AppPermission.notifications),
                onOpenSettings: _openSettings,
              ),
              // `.btns` sits directly under `.stack`, not pinned to the
              // bottom of the screen — the pair is part of the copy block.
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      label: l10n.permissionsNotNowButtonLabel,
                      onTap: _notNow,
                    ),
                  ),
                  // `.btns{gap:10px}` — between AppSpacing.md (8) and
                  // AppSpacing.base (12), so stated outright.
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrimaryButton(
                      label: l10n.permissionsContinueButtonLabel,
                      onTap: _continue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.outcome,
    required this.onAllow,
    required this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String body;

  /// Null = not asked yet.
  final PermissionOutcome? outcome;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // `.lrow gl` — the same glass row, radius, padding and icon chip
    // `shared/widgets/list_row.dart` already renders this element with;
    // this screen was the one outlier drawing an opaque card instead.
    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sunk,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 17, color: colors.ink),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: type.bodySmall.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              // The `.btn--sm.btn--ink` pill sits inline at the row's
              // right edge, vertically centred against the copy.
              if (outcome == null) ...[
                const SizedBox(width: AppSpacing.base),
                _AllowButton(onTap: onAllow),
              ],
            ],
          ),
          // Once asked, the answer replaces the pill — but it stays under
          // the copy rather than in the pill's slot: three of the five
          // outcome strings ("Not allowed — you can change this in system
          // settings" and friends) are full sentences that cannot be read
          // inside a 44px pill's footprint.
          if (outcome case final answered?) ...[
            const SizedBox(height: AppSpacing.base),
            _OutcomeStatus(outcome: answered, onOpenSettings: onOpenSettings),
          ],
        ],
      ),
    );
  }
}

/// The per-row **"Allow"** pill, shown only before the row has been asked
/// about — the mockup's `.btn.btn--sm.btn--ink`.
class _AllowButton extends StatelessWidget {
  const _AllowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // `.btn--sm{height:44px;border-radius:22px;font-size:12.5px;
        // width:auto;padding:0 18px}` + `.btn--ink`.
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: colors.pill,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppShadows.selectedPillLarge,
          ),
          child: Text(
            AppLocalizations.of(context).permissionsAllowButtonLabel,
            style: type.rowTitle.copyWith(
              fontSize: 12.5,
              letterSpacing: 0.1,
              color: colors.pillInk,
            ),
          ),
        ),
      ),
    );
  }
}

/// What came back once a row has been asked about. Every outcome gets its
/// own honest line rather than collapsing to a checkmark — "you said no",
/// "you can't say yes from here anymore", and "this build can't ask" are
/// three different facts, and none may be displayed as another. (The
/// fourth state, "we never asked", is the [_AllowButton] itself.)
class _OutcomeStatus extends StatelessWidget {
  const _OutcomeStatus({required this.outcome, required this.onOpenSettings});

  final PermissionOutcome outcome;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);

    return switch (outcome) {
      PermissionOutcome.granted => _StatusLine(
        icon: Icons.check_circle_rounded,
        color: AppStatusColors.successText,
        text: l10n.permissionsAllowedStatusLabel,
      ),
      PermissionOutcome.limited => _StatusLine(
        icon: Icons.photo_library_outlined,
        color: colors.muted,
        // permission_handler has no API for the native "choose more
        // photos" picker (that's `PHPhotoLibrary`, not this package) — the
        // only lever this screen can offer is the same Settings page the
        // permanently-denied row uses, which also lets the user widen a
        // limited grant.
        text: l10n.permissionsLimitedStatusLabel,
        onTap: onOpenSettings,
      ),
      PermissionOutcome.denied => _StatusLine(
        icon: Icons.block_rounded,
        color: colors.muted,
        text: l10n.permissionsDeniedStatusLabel,
      ),
      PermissionOutcome.permanentlyDenied => _StatusLine(
        icon: Icons.settings_outlined,
        color: colors.muted,
        // Distinct from plain `denied`: the OS will not raise another
        // in-app prompt no matter how many times "Allow" is tapped, so the
        // row must not offer a retry it can't deliver — Settings is the
        // only path left, and it's the one this line performs.
        text: l10n.permissionsPermanentlyDeniedStatusLabel,
        onTap: onOpenSettings,
      ),
      PermissionOutcome.unavailable => _StatusLine(
        icon: Icons.info_outline_rounded,
        color: colors.muted,
        // See `permission_gateway.dart`: nothing was asked, and saying so is
        // the only thing this build can honestly report.
        text: l10n.permissionsUnavailableStatusLabel,
      ),
    };
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;

  /// Present only for outcomes with a real next step (open Settings). Null
  /// for the two dead-end-with-nothing-to-do states (`denied`,
  /// `unavailable`) so tapping them does nothing rather than pretending an
  /// action exists.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final line = Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: type.bodySmall.copyWith(color: color)),
        ),
      ],
    );

    if (onTap == null) return line;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: line,
      ),
    );
  }
}

/// `.btn{font-size:13.5px;font-weight:600;letter-spacing:.1px}` — the
/// footer-button label shared by both halves of the `.btns` pair.
/// [LaCasaTypography.cardTitle] is the 13.5px step; the weight and tracking
/// are the button variant's own.
TextStyle _buttonLabel(LaCasaTypography type) =>
    type.cardTitle.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1);

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
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // `.btn--acc` — the accent *gradient* plus its glow, the same
            // material `auth_form_widgets.dart`'s AuthPrimaryButton uses,
            // not a flat accent fill.
            gradient: AppAccent.gradient,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
            boxShadow: AppShadows.accentGlow,
          ),
          child: Text(
            label,
            style: _buttonLabel(type).copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // `.btn--ghost glf` — `.btn--ghost` contributes only
        // `color:var(--ink)`, so the surface is the flat-form glass (white
        // with a hairline rim), not a grey fill.
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          // `.btn` is one height for every variant — the ghost half of a
          // `.btns` pair is not shorter than the accent half.
          height: 54,
          alignment: Alignment.center,
          borderRadius: BorderRadius.circular(AppRadii.pillButton),
          child: Text(
            label,
            style: _buttonLabel(type).copyWith(color: colors.ink),
          ),
        ),
      ),
    );
  }
}
