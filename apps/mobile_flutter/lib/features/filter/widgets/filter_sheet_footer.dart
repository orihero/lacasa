/// "Reset" (text) / "Apply Filters" (filled, live count) — SCREENS.md
/// §3.5's footer buttons. The Apply label reads the same live
/// result-count preview §5's interaction contract describes for the
/// sheet body ("Apply Filters (3)" — read as "your current filters match
/// 3 listings, tap to apply them", the one number both spec lines can
/// coherently refer to at once — flagged in the build report since
/// SCREENS.md never states outright that these are the same number).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../state/filter_count_provider.dart';

class FilterSheetFooter extends ConsumerWidget {
  const FilterSheetFooter({
    super.key,
    required this.onReset,
    required this.onApply,
  });

  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final countAsync = ref.watch(filterCountProvider);

    final label = countAsync.when(
      data: (count) =>
          count == null ? 'Apply Filters' : 'Apply Filters ($count)',
      loading: () => 'Apply Filters',
      error: (_, _) => 'Apply Filters',
    );

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            key: const ValueKey('filterSheet-reset'),
            onTap: onReset,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              child: Text(
                'Reset',
                style: type.rowTitle.copyWith(color: colors.ink2),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          flex: 2,
          child: GestureDetector(
            key: const ValueKey('filterSheet-apply'),
            onTap: onApply,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              decoration: BoxDecoration(
                gradient: AppAccent.gradient,
                borderRadius: AppRadii.pill,
                boxShadow: AppShadows.accentGlow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (countAsync.isLoading) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    label,
                    style: type.rowTitle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
