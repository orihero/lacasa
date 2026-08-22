/// `coworkers-list` (SCREENS.md §35) — header "Coworkers", an optional
/// **"+ Add new coworker"** action, and the team roster.
///
/// **Row content is exactly §35's four fields** (avatar, full name, ads
/// count, phone) — no "last active"/"deals closed" here, since §35's row
/// spec never asks for either (unlike `apps/console`'s own richer table).
/// Ads count is real, from `coworkerSummariesProvider`'s server-folded
/// `CoworkerSummary.adsCreatedCount` (`GET /statistics/coworkers/summary`,
/// per WORK_TAB_CONTRACT.md ruling 7.6) — independent of the roster fetch
/// itself, so a failed summary fetch degrades only that one figure (an em
/// dash) rather than blanking the whole list.
///
/// **"+ Add new coworker" is hidden, not disabled, for a session that would
/// 403 on `POST /coworkers`.** WORK_TAB_CONTRACT.md is explicit: "check
/// `AuthUser.realtor?.kind` client-side to hide the affordance entirely for
/// a solo agent rather than let this 403 surface as a surprise." Extended
/// here to the other real 403 case the same endpoint has — a COWORKER-role
/// caller (`apps/api/src/routes/coworkers.js`'s `POST` handler: "Only
/// agents can create coworkers") — since a coworker viewing their own
/// team's roster (a real, server-supported read per that route's `GET`
/// handler) has exactly the same "cannot actually create" fact about
/// themselves as a solo agent does. The list itself stays visible to both;
/// only the entry point that would 403 disappears.
///
/// **The same predicate now also gates the empty state's action.** An agency
/// agent whose roster is empty gets an "Add coworker" button in the middle of
/// the screen instead of a dead sentence and an unlabelled 38px "+" in the
/// header; a solo agent, who would be 403'd, still gets neither.
///
/// **Pull-to-refresh.** A roster is edited from `apps/console` and from other
/// agents' phones, and `coworkersListProvider` is deliberately not
/// `.autoDispose`, so an invite accepted while this screen sits open never
/// appeared until the app was killed. The pull reloads the roster *and* the
/// per-row ads counts — see [_CoworkersBody._refresh].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/coworker_metrics.dart';
import '../state/coworkers_providers.dart';

class CoworkersListScreen extends ConsumerWidget {
  const CoworkersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final session = ref.watch(authSessionProvider);
    final canManage =
        session.role == UserRole.agent &&
        session.user?.realtor?.kind != RealtorKind.solo;

    return Scaffold(
      backgroundColor: colors.screen,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavRow(
              title: AppLocalizations.of(context).coworkersListScreenTitle,
              onBack: () => _pop(context),
              trailing: [
                if (canManage)
                  _AddCoworkerButton(
                    onTap: () => context.push(RoutePaths.workAddCoworker),
                  ),
              ],
            ),
            // `canManage` is computed once, here, and handed down rather
            // than re-derived in the body: the empty state's "Add coworker"
            // action and the header's "+" are the same permission fact, and
            // two independent copies of that predicate is exactly how they
            // would drift apart.
            Expanded(child: _CoworkersBody(canManage: canManage)),
          ],
        ),
      ),
    );
  }

  void _pop(BuildContext context) {
    // Same reasoning as `agent_profile_screen.dart`'s: a deep link straight
    // into this screen has nothing to pop, and that is not an error — "up"
    // is just the Work root rather than "back".
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.work);
    }
  }
}

/// `.nav .rnd.acc` — a 38px `--pill` circle in the header's trailing slot,
/// exactly like `leads-list`'s own add-lead button, rather than a full-width
/// bar under the header. Its label lives in the semantics tree instead of on
/// screen, which is what the icon-only header affordance calls for.
class _AddCoworkerButton extends StatelessWidget {
  const _AddCoworkerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).coworkersAddNewButtonLabel,
      child: GestureDetector(
        key: const ValueKey('addCoworkerButton'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.pill,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x9915151B),
                blurRadius: 18,
                spreadRadius: -8,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, size: 20, color: colors.pillInk),
        ),
      ),
    );
  }
}

class _CoworkersBody extends ConsumerWidget {
  const _CoworkersBody({required this.canManage});

  /// Whether this session could actually create a coworker — see
  /// `CoworkersListScreen.build`, which owns the predicate.
  final bool canManage;

  /// Reloads the whole roster, plus the derived ads counts hanging off it.
  ///
  /// The summary fetch is invalidated alongside the list rather than left
  /// alone: it is the source of the "2 ads" half of every row, and a pull
  /// that refreshed the names while leaving the counts at yesterday's
  /// numbers would be a refresh gesture that half-lies. Only the roster's
  /// own future is awaited, because that is the one the spinner should
  /// track — a slow summary degrades to "…" on the row it belongs to
  /// (see `_CoworkerRow`) instead of holding the indicator open.
  Future<void> _refresh(WidgetRef ref) {
    ref.invalidate(coworkerSummariesProvider);
    return ref.refresh(coworkersListProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coworkersAsync = ref.watch(coworkersListProvider);
    final l10n = AppLocalizations.of(context);

    // Leads are team-wide and a roster changes from the web console and
    // from other agents' phones, so "what this screen shows" can go stale
    // while the screen is open — and `coworkersListProvider` is
    // deliberately not `.autoDispose` (see its doc comment), so nothing
    // re-fetches it for the rest of the Work-tab visit. A pull is the
    // gesture a user already reaches for; before this there was no gesture
    // on the screen that could reload it at all.
    return RefreshIndicator(
      key: const ValueKey('coworkersRefreshIndicator'),
      onRefresh: () => _refresh(ref),
      child: coworkersAsync.when(
        loading: () => const _ListSkeleton(),
        // Still centred in the body's `Expanded`, like `leads-list`'s
        // matching states — a terminal error/empty state owns the whole
        // body, so it sits in the middle of it rather than tucked under the
        // header. The `Center` moved inside [_ScrollableState], which has to
        // wrap both states in a scroller for the pull gesture to survive
        // them.
        error: (error, stackTrace) => _ScrollableState(
          child: FullWidthState(
            key: const ValueKey('coworkersErrorState'),
            // Offline outranks "couldn't load your coworkers": with the
            // network down this screen is one of a dozen showing its own
            // private version of the same sentence. See
            // `shared/widgets/read_error.dart`.
            icon: readErrorIcon(error, fallback: Icons.cloud_off_rounded),
            message: describeReadError(
              l10n,
              error,
              fallback: l10n.coworkersLoadErrorMessage,
            ),
            actionLabel: l10n.sharedRetryLabel,
            onAction: () => ref.invalidate(coworkersListProvider),
          ),
        ),
        data: (coworkers) {
          if (coworkers.isEmpty) {
            return _ScrollableState(
              child: FullWidthState(
                key: const ValueKey('coworkersEmptyState'),
                icon: Icons.groups_outlined,
                message: l10n.coworkersEmptyMessage,
                // Gated on the same predicate the header's "+" uses, and for
                // the same reason: for a solo realtor — the default register
                // choice — `POST /coworkers` 403s, so an "Add coworker"
                // button here would be an invitation into a wall. For an
                // agency agent with an empty roster this is the whole point
                // of the screen, and until now the state offered nothing to
                // tap at all: the only way forward was an unlabelled 38px
                // "+" in the header.
                actionLabel: canManage
                    ? l10n.coworkersEmptyStateActionLabel
                    : null,
                onAction: canManage
                    ? () => context.push(RoutePaths.workAddCoworker)
                    : null,
              ),
            );
          }

          final summariesAsync = ref.watch(coworkerSummariesProvider);

          return ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              overscroll: false,
            ),
            child: ListView.separated(
              // A roster short enough not to fill the viewport must still
              // accept the pull — the empty-ish list is exactly when a user
              // pulls to see whether an invite has landed yet.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                0,
                AppSpacing.screenGutter,
                MediaQuery.of(context).padding.bottom + 100,
              ),
              itemCount: coworkers.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.base),
              itemBuilder: (context, index) {
                final coworker = coworkers[index];
                return _CoworkerRow(
                  coworker: coworker,
                  summariesAsync: summariesAsync,
                  onTap: () => context.push(
                    '${RoutePaths.workCoworkers}/${coworker.id}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Wraps a non-scrolling state in a scroll view so [RefreshIndicator]'s pull
/// gesture still works when the roster is empty or errored — the two moments
/// a user is *most* likely to want to retry by pulling. Same private widget,
/// same reasoning, as `agents_directory_screen.dart` and
/// `saved_listings_grid.dart`.
///
/// The `Center` the error/empty states used to sit in is kept as the
/// scroller's own vertical centring: `ListView` cannot centre a single short
/// child, so the child is padded down instead by giving it the full viewport
/// height to sit in the middle of.
class _ScrollableState extends StatelessWidget {
  const _ScrollableState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _CoworkerRow extends StatelessWidget {
  const _CoworkerRow({
    required this.coworker,
    required this.summariesAsync,
    required this.onTap,
  });

  final Coworker coworker;
  final AsyncValue<List<CoworkerSummary>> summariesAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);

    final countLabel = summariesAsync.when(
      data: (summaries) {
        final summary = summaryFor(coworker.id, summaries);
        // A missing row (shouldn't happen — the endpoint always returns one
        // per coworker) gets the same em dash as a fetch error, not a
        // fabricated "0 listings".
        if (summary == null) return '—';
        final count = summary.adsCreatedCount;
        return l10n.coworkersListingsCount(count);
      },
      loading: () => '…',
      // An em dash, not "0 listings" — the count genuinely couldn't be
      // determined, which is a different fact than "determined to be zero".
      error: (error, stackTrace) => '—',
    );

    final phone = coworker.phoneNumber;

    return CrmListTile(
      key: ValueKey('coworkerRow-${coworker.id}'),
      leading: AgentAvatar(
        avatarUrl: coworker.avatar,
        fullName: coworker.fullName,
      ),
      title: coworker.fullName,
      // `.lrow__s` is one line joining both facts — "11 ads · +998 90 444 55
      // 66" — leaving the caret as the row's only trailing element, rather
      // than the count competing with the name for width.
      subtitle:
          '$countLabel · ${(phone == null || phone.isEmpty) ? '—' : phone}',
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: colors.faint,
      ),
      onTap: onTap,
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            child: ShimmerBox(
              height: 68,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
          ),
        ),
      ),
    );
  }
}
