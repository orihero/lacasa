/// The `.hdr` row: location pill (decorative), notification bell, search
/// icon. Build spec, "Header row".
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';

/// Hardcoded to match the mockup's own demo `aria-label="Notifications, 5
/// unread"` — no notifications-count endpoint exists anywhere in the API
/// contract this client was built against (`lib/api/` has no
/// `NotificationsResource`), so this is fixture-only until one exists.
const int _fixtureUnreadNotificationsCount = 5;

class HomeHeaderRow extends StatelessWidget {
  const HomeHeaderRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.base,
        AppSpacing.screenGutter,
        0,
      ),
      child: Row(
        children: [
          // Decorative: no `data-go`/handler on `.locpill` in the source
          // markup (build spec, "Header row" — confirmed by direct
          // inspection). Deliberately no `onTap`.
          Expanded(
            child: GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, size: 15, color: colors.ink),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.homeLocationPillLabel,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: colors.ink,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconButton(
            icon: Icons.notifications_rounded,
            semanticLabel: l10n.homeNotificationsBellSemanticLabel(
              _fixtureUnreadNotificationsCount,
            ),
            showDot: _fixtureUnreadNotificationsCount > 0,
            onTap: () => context.push(RoutePaths.homeNotifications),
          ),
          const SizedBox(width: AppSpacing.sm),
          _IconButton(
            icon: Icons.search_rounded,
            semanticLabel: l10n.homeSearchIconSemanticLabel,
            onTap: () => context.go(RoutePaths.search),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String semanticLabel;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: AppRadii.pill,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 19, color: colors.ink),
              if (showDot)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppAccent.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
