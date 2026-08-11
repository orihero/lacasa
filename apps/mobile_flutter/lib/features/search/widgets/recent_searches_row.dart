/// SCREENS.md §3.4: "'Recent Searches' chip row with 'Clear' link (mobile-
/// only, local storage)." Renders nothing at all (not even the header) when
/// the list is empty — there is nothing to clear and no point taking up
/// vertical rhythm for an empty section, matching `SectionHeader`'s
/// existing "trailing link only if both label and callback are non-null"
/// contract used elsewhere for optional rail actions.
///
/// Selecting a chip re-runs that exact query immediately (no 300ms
/// debounce — this is an explicit tap, not free typing) by writing into the
/// same [TextEditingController] the search field itself edits, via
/// [onSelect], which the parent screen owns (see `search_screen.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

class RecentSearchesRow extends ConsumerWidget {
  const RecentSearchesRow({super.key, required this.onSelect});

  final void Function(String query) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentSearchesProvider);

    return recents.when(
      // A failed/loading recents fetch is silently absent — see
      // `recent_searches_repository.dart`: this row is a convenience, never
      // worth its own retry UI competing with the results list below it.
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (queries) {
        if (queries.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.searchRecentSearchesSectionTitle,
              linkLabel: l10n.searchRecentSearchesClearLabel,
              onLink: () => ref.read(recentSearchesProvider.notifier).clear(),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenGutter,
                ),
                itemCount: queries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final query = queries[index];
                  return _RecentChip(
                    key: ValueKey('recentSearchChip-$index'),
                    label: query,
                    onTap: () => onSelect(query),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      onTap: onTap,
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: AppRadii.pill,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 14, color: colors.muted),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.rowTitle.copyWith(color: colors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
