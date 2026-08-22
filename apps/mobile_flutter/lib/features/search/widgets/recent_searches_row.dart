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
            // Owned here rather than by the parent screen so it collapses
            // with the row itself when there are no recents.
            const SizedBox(height: AppSpacing.section),
            SectionHeader(
              title: l10n.searchRecentSearchesSectionTitle,
              linkLabel: l10n.searchRecentSearchesClearLabel,
              onLink: () => ref.read(recentSearchesProvider.notifier).clear(),
            ),
            // 9px per the mockup's `<div class="opts" style="margin-top:9px">`.
            const SizedBox(height: 9),
            // A plain wrapping `.opts` group — the nowrap/scroll override is
            // scoped to `.tools .opts` and doesn't reach these chips, so a
            // fourth chip drops to a second row instead of being clipped off
            // the right edge with no affordance.
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenGutter,
              ),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (var index = 0; index < queries.length; index++)
                    _RecentChip(
                      key: ValueKey('recentSearchChip-$index'),
                      label: queries[index],
                      onTap: () => onSelect(queries[index]),
                    ),
                ],
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
      // `.opt{height:38px;border-radius:19px;padding:0 15px;font-size:12px;
      // font-weight:500}` — text only, the mockup's chips carry no leading
      // glyph. `body` is the 12px role and the weight is the override, the
      // same pairing `choice_chip_group.dart` uses for its own `.opt`.
      //
      // The height is stated by a [SizedBox] and the vertical centring by a
      // shrink-wrapping [Center], rather than by `GlassSurface`'s own
      // `height`/`alignment`: that pair puts an `alignment` on the widget's
      // outer [Container], which makes the box *expand* to the width it is
      // offered. Inside the [Wrap] above that is the full gutter-to-gutter
      // width, so every chip became a full-width bar on its own line
      // (`.opt` is an inline-flex pill sized to its label). Under the old
      // horizontal [ListView] the offered width was unbounded, so the same
      // code shrink-wrapped and the bug could not show.
      child: SizedBox(
        height: 38,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: AppRadii.pill,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Center(
            widthFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
