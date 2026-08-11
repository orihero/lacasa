/// `notifications` (SCREENS.md §22) — header "Notifications", back arrow,
/// a dispatch-only list of rows that each route to the screen implied by
/// their kind (§5's "Notification tap-through" rule: this screen never
/// opens a detail view of its own).
///
/// **Router wiring**: reached from `RoutePaths.workNotifications` and (the
/// integration pass's job) `RoutePaths.homeNotifications` — same
/// no-`branchPrefix` shape as `ConnectedAccountsScreen`/`MessagesScreen`
/// (contract §8's "known risks" note): every tap target here is either a
/// cross-branch `context.go` to an absolute Work path (contract §2.2 — a
/// Work-only concept like `edit-listing`/`publish-status`/`coworker-detail`
/// always uses `go`, never `push`, regardless of which branch opened this
/// screen) or the `lead-detail` sheet, so nothing here needs to know which
/// branch it was pushed from.
///
/// **`lead-detail`'s cross-feature dependency (contract §3.4).** The lead
/// tap target calls `showLeadDetailSheet` from
/// `package:lacasa_mobile/features/leads/leads.dart` — the one place in
/// this whole build where a feature imports directly from another feature
/// rather than through a route. `leads` (feature D) owns that file.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../leads/leads.dart' show showLeadDetailSheet;
import '../state/notifications_providers.dart';
import 'notification_row.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final notificationsAsync = ref.watch(notificationsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(title: l10n.notificationsScreenTitle, onBack: () => _pop(context)),
            Expanded(
              child: notificationsAsync.when(
                loading: () => ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                    ),
                    children: const [
                      ShimmerBox(
                        height: 72,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadii.card),
                        ),
                      ),
                      SizedBox(height: AppSpacing.base),
                      ShimmerBox(
                        height: 72,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadii.card),
                        ),
                      ),
                      SizedBox(height: AppSpacing.base),
                      ShimmerBox(
                        height: 72,
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppRadii.card),
                        ),
                      ),
                    ],
                  ),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenGutter,
                  ),
                  child: FullWidthState(
                    icon: Icons.error_outline_rounded,
                    message: l10n.notificationsLoadErrorMessage,
                    actionLabel: l10n.sharedRetryLabel,
                    onAction: () => ref.invalidate(notificationsProvider),
                  ),
                ),
                data: (notifications) => notifications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenGutter,
                        ),
                        child: FullWidthState(
                          icon: Icons.notifications_none_rounded,
                          message: l10n.notificationsEmptyMessage,
                        ),
                      )
                    : ScrollConfiguration(
                        behavior: const MaterialScrollBehavior().copyWith(
                          overscroll: false,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenGutter,
                            0,
                            AppSpacing.screenGutter,
                            AppSpacing.xxl,
                          ),
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.base),
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return NotificationRow(
                              key: ValueKey(
                                'notificationRow-${notification.id}',
                              ),
                              notification: notification,
                              onTap: () => _handleTap(context, notification),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }

  /// §22's tap-through table: lead -> `lead-detail` sheet; publish ->
  /// `publish-status`; sold -> `edit-listing`; coworker activity ->
  /// `coworker-detail`. A row with no [WorkNotificationFixture.targetId]
  /// (none of §4.4's 5 seed rows hit this, but a hypothetical future kind
  /// might) does nothing rather than navigate to a route missing its `:id`.
  void _handleTap(
    BuildContext context,
    WorkNotificationFixture notification,
  ) {
    final targetId = notification.targetId;
    if (targetId == null) return;

    switch (notification.kind) {
      case WorkNotificationKind.lead:
        showLeadDetailSheet(context, leadId: targetId);
      case WorkNotificationKind.publish:
        context.go(RoutePaths.workPublishStatus.replaceFirst(':id', targetId));
      case WorkNotificationKind.sold:
        context.go(RoutePaths.workEditListing.replaceFirst(':id', targetId));
      case WorkNotificationKind.coworkerActivity:
        context.go(
          RoutePaths.workCoworkerDetail.replaceFirst(':id', targetId),
        );
    }
  }
}
