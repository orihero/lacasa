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
/// **"Allow" does not raise an OS prompt in this build.** That is a wiring
/// gap with a documented reason, not an oversight — see
/// `data/permission_gateway.dart`, which explains why the manifest
/// declarations were deliberately not added ahead of any feature using
/// them. The row reports [PermissionOutcome.unavailable] plainly instead of
/// implying a dialog appeared and was dismissed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    extends ConsumerState<PermissionsPrimerScreen> {
  /// Per-row result of the last grant attempt. Absent means "not asked yet",
  /// which is a third state distinct from denied and unavailable.
  final Map<AppPermission, PermissionOutcome> _outcomes = {};

  Future<void> _request(AppPermission permission) async {
    final outcome = await ref
        .read(permissionGatewayProvider)
        .request(permission);
    if (!mounted) return;
    setState(() => _outcomes[permission] = outcome);
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
              Text(
                // §3.2's header, with its ellipsis character.
                'Allow La Casa to…',
                style: type.heroTitle.copyWith(color: colors.ink),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _PermissionRow(
                icon: Icons.photo_camera_outlined,
                title: 'Camera & Photos',
                body: 'To add photos to your listings and profile avatar',
                outcome: _outcomes[AppPermission.cameraAndPhotos],
                onAllow: () => _request(AppPermission.cameraAndPhotos),
              ),
              const SizedBox(height: AppSpacing.base),
              _PermissionRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                body: 'To alert you about new leads and publish status.',
                outcome: _outcomes[AppPermission.notifications],
                onAllow: () => _request(AppPermission.notifications),
              ),
              const Spacer(),
              _SecondaryButton(label: 'Not now', onTap: _notNow),
              const SizedBox(height: AppSpacing.base),
              _PrimaryButton(label: 'Continue', onTap: _continue),
              const SizedBox(height: AppSpacing.xl),
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
  });

  final IconData icon;
  final String title;
  final String body;

  /// Null = not asked yet.
  final PermissionOutcome? outcome;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.cardXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sunk,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 19, color: AppAccent.color),
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
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _AllowControl(outcome: outcome, onAllow: onAllow),
        ],
      ),
    );
  }
}

/// The per-row **"Allow"** button and, once asked, what came back. Every
/// outcome gets its own honest line rather than collapsing to a checkmark —
/// "we never asked" and "you said no" are different facts, and a build with
/// no permission backend must not display the first as the second.
class _AllowControl extends StatelessWidget {
  const _AllowControl({required this.outcome, required this.onAllow});

  final PermissionOutcome? outcome;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return switch (outcome) {
      null => Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAllow,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.sunk,
                borderRadius: AppRadii.pill,
              ),
              child: Text(
                'Allow',
                style: type.label.copyWith(color: AppAccent.color),
              ),
            ),
          ),
        ),
      ),
      PermissionOutcome.granted => _StatusLine(
        icon: Icons.check_circle_rounded,
        color: AppStatusColors.successText,
        text: 'Allowed',
      ),
      PermissionOutcome.denied => _StatusLine(
        icon: Icons.block_rounded,
        color: colors.muted,
        text: 'Not allowed — you can change this in system settings',
      ),
      PermissionOutcome.unavailable => _StatusLine(
        icon: Icons.info_outline_rounded,
        color: colors.muted,
        // See `permission_gateway.dart`: nothing was asked, and saying so is
        // the only thing this build can honestly report.
        text: 'Not available in this build yet',
      ),
    };
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: type.bodySmall.copyWith(color: color)),
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
          width: double.infinity,
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
        child: Container(
          width: double.infinity,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.sunk,
            borderRadius: BorderRadius.circular(AppRadii.pillButton),
          ),
          child: Text(label, style: type.label.copyWith(color: colors.ink2)),
        ),
      ),
    );
  }
}
