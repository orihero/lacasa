/// One row of `notifications` (SCREENS.md §22) — icon (per
/// [WorkNotificationKind]), the fixture's single combined title sentence
/// (§4.4's seed rows are already written as one fused "headline — detail"
/// string, not separate title/body fields — see
/// `WorkNotificationFixture`'s own doc comment), relative time, and an
/// unread dot.
library;

import 'package:flutter/material.dart';

import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final WorkNotificationFixture notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: notification.unread
          ? '${notification.title}, unread'
          : notification.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sunk,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  _iconFor(notification.kind),
                  size: 17,
                  color: colors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.relativeTime,
                      style: type.micro.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              if (notification.unread) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    color: AppAccent.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(WorkNotificationKind kind) => switch (kind) {
    WorkNotificationKind.lead => Icons.person_add_alt_1_rounded,
    WorkNotificationKind.publish => Icons.send_rounded,
    WorkNotificationKind.sold => Icons.sell_rounded,
    WorkNotificationKind.coworkerActivity => Icons.groups_rounded,
  };
}
