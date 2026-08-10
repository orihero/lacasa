/// `coworkers-list` (SCREENS.md §35) — header "Coworkers", an optional
/// **"+ Add new coworker"** action, and the team roster.
///
/// **Row content is exactly §35's four fields** (avatar, full name, ads
/// count, phone) — no "last active"/"deals closed" here, since §35's row
/// spec never asks for either (unlike `apps/console`'s own richer table).
/// Ads count is real, derived client-side from `coworkerAdsProvider` per
/// WORK_TAB_CONTRACT.md ruling 7.6 (`coworker_metrics.dart`'s
/// [coworkerListingsCount]) — independent of the roster fetch itself, so a
/// failed ads fetch degrades only that one figure (an em dash) rather than
/// blanking the whole list.
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
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
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
            NavRow(title: 'Coworkers', onBack: () => _pop(context)),
            if (canManage)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  0,
                  AppSpacing.screenGutter,
                  AppSpacing.base,
                ),
                child: _AddCoworkerButton(
                  onTap: () => context.push(RoutePaths.workAddCoworker),
                ),
              ),
            const Expanded(child: _CoworkersBody()),
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

/// Full-width so its label — verbatim §35 copy, including the leading "+"
/// — never has to compete for horizontal space with the header title, the
/// way a compact header-trailing button would at 360px.
class _AddCoworkerButton extends StatelessWidget {
  const _AddCoworkerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('addCoworkerButton'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
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
          child: Text(
            '+ Add new coworker',
            style: type.rowTitle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _CoworkersBody extends ConsumerWidget {
  const _CoworkersBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coworkersAsync = ref.watch(coworkersListProvider);

    return coworkersAsync.when(
      loading: () => const _ListSkeleton(),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
        child: FullWidthState(
          icon: Icons.cloud_off_rounded,
          message: "Couldn't load your coworkers",
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(coworkersListProvider),
        ),
      ),
      data: (coworkers) {
        if (coworkers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
            child: FullWidthState(
              icon: Icons.groups_outlined,
              message: 'No coworkers yet.',
            ),
          );
        }

        final adsAsync = ref.watch(coworkerAdsProvider);

        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
          child: ListView.separated(
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
                adsAsync: adsAsync,
                onTap: () =>
                    context.push('${RoutePaths.workCoworkers}/${coworker.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

class _CoworkerRow extends StatelessWidget {
  const _CoworkerRow({
    required this.coworker,
    required this.adsAsync,
    required this.onTap,
  });

  final Coworker coworker;
  final AsyncValue<List<Ad>> adsAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final countLabel = adsAsync.when(
      data: (ads) {
        final count = coworkerListingsCount(coworker.id, ads);
        return '$count listing${count == 1 ? '' : 's'}';
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
      subtitle: (phone == null || phone.isEmpty) ? '—' : phone,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(countLabel, style: type.bodySmall.copyWith(color: colors.muted)),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded, size: 18, color: colors.faint),
        ],
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
