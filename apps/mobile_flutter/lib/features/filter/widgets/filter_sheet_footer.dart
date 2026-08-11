/// "Reset" (text) / "Apply Filters" (filled, live count) — SCREENS.md
/// §3.5's footer buttons. The Apply label reads the same live
/// result-count preview §5's interaction contract describes for the
/// sheet body ("Apply Filters (3)" — read as "your current filters match
/// 3 listings, tap to apply them", the one number both spec lines can
/// coherently refer to at once — flagged in the build report since
/// SCREENS.md never states outright that these are the same number).
///
/// **[showLiveCount] — the CRM-variant carve-out.** `filter_count_provider.
/// dart`'s preview is wired to the buyer-facing public feed
/// (`FilterRepository`/`GET /ads`, always `stage: "ACTIVE"` — see that
/// provider's own doc comment), which has nothing to do with what
/// `my-listings`'s own agent-scoped, all-stages `GET /my/ads` fetch would
/// actually return for the same draft filters. Showing that number on the
/// CRM variant's Apply button would be a fabricated count — the honesty
/// rule this codebase's build contract calls its strongest convention — so
/// `my-listings` passes `showLiveCount: false` and this button falls back
/// to a plain, static "Apply Filters" label with no [filterCountProvider]
/// read at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../state/filter_count_provider.dart';

class FilterSheetFooter extends ConsumerWidget {
  const FilterSheetFooter({
    super.key,
    required this.onReset,
    required this.onApply,
    this.showLiveCount = true,
  });

  final VoidCallback onReset;
  final VoidCallback onApply;
  final bool showLiveCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    if (!showLiveCount) {
      return _FooterRow(
        colors: colors,
        type: type,
        onReset: onReset,
        onApply: onApply,
        label: l10n.filterApplyButtonLabel,
        isLoading: false,
      );
    }

    final countAsync = ref.watch(filterCountProvider);

    final label = countAsync.when(
      data: (count) => count == null
          ? l10n.filterApplyButtonLabel
          : l10n.filterApplyButtonWithCountLabel(count),
      loading: () => l10n.filterApplyButtonLabel,
      error: (_, _) => l10n.filterApplyButtonLabel,
    );

    return _FooterRow(
      colors: colors,
      type: type,
      onReset: onReset,
      onApply: onApply,
      label: label,
      isLoading: countAsync.isLoading,
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.colors,
    required this.type,
    required this.onReset,
    required this.onApply,
    required this.label,
    required this.isLoading,
  });

  final LaCasaColors colors;
  final LaCasaTypography type;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
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
                AppLocalizations.of(context).filterResetButtonLabel,
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
                  if (isLoading) ...[
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
