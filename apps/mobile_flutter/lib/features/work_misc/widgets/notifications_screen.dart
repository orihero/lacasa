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
///
/// **Who is allowed to load this at all.** `GET /notifications` is an
/// agent/coworker endpoint — `api/resources/notifications_resource.dart`
/// documents the 403 a `user` role gets — and every row this screen can
/// render is a CRM event (a new lead, a publish result, a sold ad, a
/// coworker's activity), so there is nothing here for a buyer even in the
/// success case. Home's bell is already hidden for those roles, but a
/// hidden entry point is not a guard: a deep link, a restored back stack,
/// or a session that changes role while this screen is mounted all reach
/// [NotificationsScreen.build] directly. Without a check here that lands
/// the user in an unbreakable loop — shimmer, "Couldn't load your
/// notifications.", a Retry that re-fires the same forbidden request, for
/// ever. So [build] resolves [authSessionProvider] *before* it touches
/// [notificationsProvider] and, for a role that cannot load the feed,
/// never subscribes to it at all: the request is not made, so it cannot
/// fail, and the screen says which of the two reasons applies (signed out
/// → sign in; signed in as a buyer → this is an agent surface) with a way
/// out of each.
///
/// Note the deliberate third branch: while
/// [AuthSessionState.isRestoring] is true the app does not yet *know* the
/// role (see `auth_session.dart`'s startup-restore section), so asserting
/// "you're signed out" for that frame would be a lie told to the exact user
/// who is about to be signed in. That window renders the same skeleton the
/// feed's own first load does — no claim at all until there is one to make.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../../leads/leads.dart' show showLeadDetailSheet;
import '../state/notifications_providers.dart';
import 'notification_row.dart';
import '../data/work_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider);

    // Conditional on purpose — see this file's doc comment. A role that
    // would be 403'd never subscribes, so the forbidden request is never
    // issued and there is no failure to retry.
    final notificationsAsync = session.canAccessWork
        ? ref.watch(notificationsProvider)
        : null;

    final hasUnread =
        notificationsAsync?.maybeWhen(
          data: (rows) => rows.any((row) => row.unread),
          orElse: () => false,
        ) ??
        false;
    // `.body{padding-bottom:var(--pb,104px)}` — the floating [GlassTabBar]
    // paints over this body (`TabShellScaffold` sets `extendBody: true`),
    // so every scroller here reserves the same clearance
    // `leads_list_screen.dart` already does.
    final bottomInset = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: colors.screen,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: l10n.notificationsScreenTitle,
              onBack: () => _pop(context),
              trailing: [
                // `<button class="link">Mark all read</button>` — hidden
                // outright when there is nothing unread to clear, rather
                // than offered as a tap that would do nothing.
                if (hasUnread)
                  _MarkAllReadLink(
                    key: const ValueKey('notificationsMarkAllRead'),
                  ),
              ],
            ),
            Expanded(
              child: notificationsAsync == null
                  ? _AccessState(
                      session: session,
                      bottomInset: bottomInset,
                      onGoBack: () => _pop(context),
                    )
                  : notificationsAsync.when(
                      loading: () =>
                          _LoadingSkeleton(bottomInset: bottomInset),
                      error: (error, stackTrace) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenGutter,
                        ),
                        child: FullWidthState(
                          key: const ValueKey('notificationsErrorState'),
                          // §9.5: a read that never reached the server says
                          // so, in the one sentence every other read path in
                          // the app now uses for it. The per-screen string
                          // below stays exactly right for a 500 or a
                          // malformed body, where "which screen failed" is
                          // the most specific thing the app knows.
                          icon: readErrorIcon(error),
                          message: describeReadError(
                            l10n,
                            error,
                            fallback: l10n.notificationsLoadErrorMessage,
                          ),
                          actionLabel: l10n.sharedRetryLabel,
                          onAction: () => ref.invalidate(notificationsProvider),
                        ),
                      ),
                      data: (notifications) => RefreshIndicator(
                        // §9.3: `notificationsProvider` is deliberately not
                        // `.autoDispose` (its own doc comment explains why:
                        // the dashboard header watches it for the unread
                        // dot), so the rows this screen holds survive every
                        // tab switch and every backgrounding for the whole
                        // session. Without this gesture a lead that arrived
                        // while the app was open is invisible until the
                        // process is killed — and pull-to-refresh is the
                        // gesture a user already tries on a feed.
                        onRefresh: () => _refresh(ref),
                        child: notifications.isEmpty
                            ? _EmptyState(
                                bottomInset: bottomInset,
                                onRefresh: () => ref.invalidate(
                                  notificationsProvider,
                                ),
                              )
                            : ScrollConfiguration(
                                behavior: const MaterialScrollBehavior()
                                    .copyWith(overscroll: false),
                                child: ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    AppSpacing.screenGutter,
                                    AppSpacing.sm,
                                    AppSpacing.screenGutter,
                                    bottomInset,
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
                                      onTap: () =>
                                          _handleTap(context, notification),
                                    );
                                  },
                                ),
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

  /// The pull-to-refresh handler.
  ///
  /// [RefreshIndicator] awaits whatever this returns purely to decide when
  /// to retract its spinner, and a future that completes with an error
  /// there escapes as an unhandled zone error — which in a widget test is a
  /// hard failure and on device is a silent crash report. The failure is
  /// already fully expressed on screen: `ref.refresh` puts the provider in
  /// its error state, and the `error:` branch above swaps the list for a
  /// named message and a Retry. So the throw is swallowed here on purpose,
  /// having already been rendered.
  Future<void> _refresh(WidgetRef ref) async {
    try {
      // `invalidate` + `read` rather than `refresh`, whose return value
      // would be discarded here (`unused_result`): this handler wants the
      // re-fetch and its completion, never the rows themselves — the list
      // rebuilds from the provider.
      ref.invalidate(notificationsProvider);
      await ref.read(notificationsProvider.future);
    } catch (_) {
      // Rendered by the `error:` branch — see above.
    }
  }

  /// §22's tap-through table: lead -> `lead-detail` sheet; publish ->
  /// `publish-status`; sold -> `edit-listing`; coworker activity ->
  /// `coworker-detail`. A row with no [WorkNotification.targetId]
  /// (none of §4.4's 5 seed rows hit this, but a hypothetical future kind
  /// might) does nothing rather than navigate to a route missing its `:id`.
  void _handleTap(BuildContext context, WorkNotification notification) {
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
        context.go(RoutePaths.workCoworkerDetail.replaceFirst(':id', targetId));
    }
  }
}

/// The three-row shimmer §22's first load paints, shared by the feed's own
/// `loading` state and by the session-restore window (see this file's doc
/// comment): in both cases the honest thing on screen is "we don't know
/// yet", and it should look identical either way.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.sm,
          AppSpacing.screenGutter,
          bottomInset,
        ),
        children: const [
          ShimmerBox(
            height: 72,
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
          ),
          SizedBox(height: AppSpacing.base),
          ShimmerBox(
            height: 72,
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
          ),
          SizedBox(height: AppSpacing.base),
          ShimmerBox(
            height: 72,
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
          ),
        ],
      ),
    );
  }
}

/// §9.4: the empty feed, with something to say and something to tap.
///
/// "No notifications yet." on its own is true and useless — it names a
/// state without saying what would end it, so an agent who has never seen a
/// row cannot tell an empty inbox from a broken one. The second line is the
/// answer: it lists the events that land here, which doubles as the
/// explanation of why the screen is blank for someone who has not yet had a
/// lead. The action exists because "yet" invites exactly one gesture, and
/// on an empty list the pull-to-refresh that would serve it has almost no
/// travel to discover — so the same refresh is offered as a button.
///
/// Scrollable rather than a bare column so the [RefreshIndicator] wrapping
/// it still has something to drag; [AlwaysScrollableScrollPhysics] keeps
/// that true when the content is shorter than the viewport, which for an
/// empty state it always is.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.bottomInset, required this.onRefresh});

  final double bottomInset;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: colors.faint,
                  size: 36,
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  l10n.notificationsEmptyMessage,
                  key: const ValueKey('notificationsEmptyMessage'),
                  textAlign: TextAlign.center,
                  style: type.body.copyWith(color: colors.ink2),
                ),
                const SizedBox(height: AppSpacing.xs),
                // A tier below the headline: it explains, it does not
                // announce. Same relationship `NotificationRow` draws
                // between its own title and subtitle.
                Text(
                  l10n.notificationsEmptyStateDetailMessage,
                  key: const ValueKey('notificationsEmptyDetail'),
                  textAlign: TextAlign.center,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
                const SizedBox(height: AppSpacing.base),
                TapTarget(
                  key: const ValueKey('notificationsEmptyRefresh'),
                  semanticsLabel: l10n.notificationsEmptyStateActionLabel,
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.base,
                    ),
                    decoration: BoxDecoration(
                      color: colors.pill,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Text(
                      l10n.notificationsEmptyStateActionLabel,
                      style: type.label.copyWith(color: colors.pillInk),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What this screen shows to someone who can never load it — see this
/// file's doc comment for why the guard is here and not only on the bell.
///
/// Three cases, and the distinction between them is the whole point:
///
/// * **restoring** — the role is not known yet, so nothing is asserted:
///   the same skeleton the feed's first load paints. Telling a signed-in
///   agent "sign in" for one frame of a cold start is precisely the §7.6
///   mistake.
/// * **signed out** — the fix is a session, and the way to get one is one
///   tap away, so it is offered rather than described.
/// * **signed in, not an agent** — a session will not help; this is an
///   agent surface. Saying so and pointing back out is the only honest
///   move, and it is strictly better than the shimmer → error → Retry loop
///   this branch replaces.
class _AccessState extends StatelessWidget {
  const _AccessState({
    required this.session,
    required this.bottomInset,
    required this.onGoBack,
  });

  final AuthSessionState session;
  final double bottomInset;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (session.isRestoring) {
      return _LoadingSkeleton(bottomInset: bottomInset);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: session.isSignedIn
          ? FullWidthState(
              key: const ValueKey('notificationsAgentOnlyState'),
              icon: Icons.notifications_off_rounded,
              message: l10n.notificationsAgentOnlyMessage,
              actionLabel: l10n.notificationsGoBackLabel,
              onAction: onGoBack,
            )
          : FullWidthState(
              key: const ValueKey('notificationsSignInState'),
              icon: Icons.notifications_none_rounded,
              message: l10n.notificationsSignInPromptMessage,
              actionLabel: l10n.sharedSignInActionLabel,
              onAction: () => context.push(RoutePaths.login),
            ),
    );
  }
}

/// `.nav .link{font-size:11.5px;font-weight:500;color:var(--muted)}` — the
/// header's one action. Wrapped in the same 44px-tall tap box the row's
/// other controls use, so the small label is still a full-size target.
class _MarkAllReadLink extends ConsumerWidget {
  const _MarkAllReadLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.notificationsMarkAllReadLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _markAllRead(context, ref, l10n),
        // Capped so no locale's rendering of this label can push the
        // [NavRow]'s Expanded title negative — the title ellipsizes first,
        // then this does.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150, minHeight: 44),
          child: Center(
            widthFactor: 1,
            child: Text(
              l10n.notificationsMarkAllReadLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: type.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Clears every loaded row's unread dot, through the full
  /// pending → success/error sequence SCREENS.md §5 requires of every
  /// mutating action.
  ///
  /// This used to `await` the write and then toast success
  /// *unconditionally*, with no `try`/`catch` anywhere on the path —
  /// [NotificationsNotifier.markAllRead] awaits the repository before it
  /// rewrites `state`, so a failed write left the dots exactly where they
  /// were while the screen claimed the opposite, and the exception escaped
  /// an un-awaited async `onTap` as an unhandled zone error: no toast, no
  /// change, no explanation. Routing it through [LaCasaToast.run] gives the
  /// failure the same visible treatment every Work form's save already has.
  ///
  /// [LaCasaToast.run] rethrows after showing its error toast so a caller
  /// can react; there is nothing further for this one to do, and letting it
  /// escape would reinstate the very defect above — hence the deliberate
  /// swallow, after rendering.
  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      await LaCasaToast.run(
        context: context,
        action: () => ref.read(notificationsProvider.notifier).markAllRead(),
        pending: l10n.notificationsMarkAllReadPendingLabel,
        success: l10n.notificationsMarkedAllReadToastMessage,
        errorMessage: (_) => l10n.notificationsMarkAllReadErrorMessage,
      );
    } catch (_) {
      // Already rendered by the error toast — see above.
    }
  }
}
