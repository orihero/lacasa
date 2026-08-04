/// The Top Agents rail: 5 compact chips bound to [topAgentsProvider]
/// (build spec, "Top Agents rail"). First-name-only caption per the
/// mockup's `.agent__n` content, deliberately distinct from every other
/// screen's `fullName` convention.
///
/// - loading: 5 skeleton circles + two text-line placeholders.
/// - error: compact rail-scoped [RailRetryCard].
/// - empty: hide the rail **and its header** entirely (build spec's own
///   judgment call, flagged there: "an empty 'top agents' slot isn't worth
///   alarming the buyer with copy").
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';
import 'agent_avatar.dart';
import 'rail_states.dart';
import 'section_header.dart';

class TopAgentsRail extends ConsumerWidget {
  const TopAgentsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final agents = ref.watch(topAgentsProvider);

    return agents.when(
      loading: () => _Shell(
        child: SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenGutter,
            ),
            itemCount: 5,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.base),
            itemBuilder: (context, index) => SizedBox(
              width: 62,
              child: Column(
                children: [
                  const ShimmerBox(
                    width: 62,
                    height: 62,
                    borderRadius: BorderRadius.all(Radius.circular(31)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const ShimmerBox(width: 44, height: 8),
                  const SizedBox(height: 3),
                  const ShimmerBox(width: 34, height: 7),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => _Shell(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenGutter,
          ),
          child: RailRetryCard(
            width: 230,
            message: "Couldn't load agents",
            onRetry: () => ref.invalidate(topAgentsProvider),
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return _Shell(
          child: SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              itemCount: list.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.base),
              itemBuilder: (context, index) {
                final agent = list[index];
                final nameParts = agent.fullName.trim().split(RegExp(r'\s+'));
                final firstName =
                    nameParts.isNotEmpty && nameParts.first.isNotEmpty
                    ? nameParts.first
                    : agent.fullName;
                return GestureDetector(
                  key: ValueKey('agentChip-${agent.id}'),
                  onTap: () => context.push('/home/agent/${agent.id}'),
                  child: SizedBox(
                    width: 62,
                    child: Column(
                      children: [
                        AgentAvatar(
                          avatarUrl: agent.avatar,
                          fullName: agent.fullName,
                          size: 62,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          firstName,
                          overflow: TextOverflow.ellipsis,
                          style: type.rowTitle.copyWith(
                            color: colors.ink,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${agent.adsCount} ads',
                          overflow: TextOverflow.ellipsis,
                          style: type.micro.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Top Agents',
          linkLabel: 'Explore',
          onLink: () => context.go(RoutePaths.agents),
        ),
        const SizedBox(height: AppSpacing.base),
        child,
      ],
    );
  }
}
