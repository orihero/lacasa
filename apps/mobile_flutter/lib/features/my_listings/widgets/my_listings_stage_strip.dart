/// The segmented "All · 12 active · 3 sold · 2 drafts" strip that rides
/// directly under `my-listings`' header (UX audit §1 "Relocate" / §5.6).
///
/// **Why this exists.** The one aggregate an agent acts on daily — *how
/// many of my listings are still unpublished drafts* — used to live nowhere
/// near the listings. It was an 11px subtitle on a dashboard workspace link
/// (`work_dashboard/widgets/dashboard_workspace_links.dart`), three scrolls
/// below a range selector, four stat tiles and two charts, and the endpoint
/// that answers it properly — `GET /my/ads/stage-counts`, wrapped by
/// [AgentAdsResource.stageCounts] — had **zero call sites in `lib/`**. The
/// numbers now sit on top of the rows they count.
///
/// **The counts come from the endpoint, never from the loaded page.** See
/// `MyListingsRepository.fetchStageCounts` — SCREENS.md §25's "Infinite
/// scroll" is real keyset paging, so folding whatever ten ads happen to be
/// in memory would print a number that is wrong by construction and grows
/// as the user scrolls.
///
/// **Each segment is also a filter shortcut, and that is safe *because* the
/// strip is always on screen.** UX audit §5.7 warns that
/// [myListingsStatusProvider] is a non-`autoDispose` global: a stage filter
/// set once survives every tab switch, every push and pop, for the whole
/// session. A shortcut that set it invisibly would be a defect, not a
/// feature — the agent would come back tomorrow to a list quietly missing
/// two thirds of their ads. The selected segment is painted filled
/// (`--pill`/`--pill-ink`) against three sunk ones and re-renders on every
/// build of this screen, and the header's Filter badge counts Status too
/// (`activeMyListingsFilterCount`), so the persistence is stated twice on
/// the surface it affects. "All" is a real segment for the same reason:
/// clearing the filter has to be one tap from where it was set, not a trip
/// back through the filter sheet.
///
/// **Hidden, not degraded, while the counts are unavailable.** A failed or
/// in-flight `stage-counts` renders nothing at all (build contract §6:
/// independent providers per independently-failable section). There is no
/// count-less fallback rendering because a segmented control whose segments
/// have lost their numbers is a filter control the CRM filter sheet already
/// provides in full — the strip's whole contribution is the numbers. During
/// a refresh Riverpod keeps the previous `AsyncValue.value`, so a pull-to-
/// refresh does not make the strip blink out and back.
///
/// **The counts are unfiltered.** `GET /my/ads/stage-counts` takes no query
/// params, so with a City filter applied the strip still reports the whole
/// table while the list below shows one city. That is deliberate and it is
/// the question the strip answers: "how many drafts do I have?", not "how
/// many drafts match the filter I set". A count that collapsed to the
/// filtered set would leave "2 drafts" reading "2 drafts" with nothing to
/// compare it against.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/my_listings_providers.dart';

class MyListingsStageStrip extends ConsumerWidget {
  const MyListingsStageStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // `.value`, not `.when` — see this file's doc comment: loading and
    // error are the same answer here (render nothing), and `.value` is
    // additionally what preserves the previous counts through a refresh.
    final counts = ref.watch(myListingsStageCountsProvider).value;
    if (counts == null) return const SizedBox.shrink();

    final selected = ref.watch(myListingsStatusProvider);

    // `(stage, label, stageName, keySuffix)`. `stage: null` is the All
    // segment — the same `null` [myListingsStatusProvider] holds when no
    // stage narrowing is applied, so selection is a plain `==` for every
    // segment including that one.
    final segments = <(AdStage?, String, String, String)>[
      (
        null,
        l10n.myListingsStageAllLabel,
        l10n.myListingsStageAllLabel,
        'all',
      ),
      (
        AdStage.active,
        l10n.myListingsStageCountActiveLabel(counts.active),
        l10n.sharedAdStageActiveLabel,
        'active',
      ),
      (
        AdStage.sold,
        l10n.myListingsStageCountSoldLabel(counts.sold),
        l10n.sharedAdStageSoldLabel,
        'sold',
      ),
      (
        AdStage.draft,
        l10n.myListingsStageCountDraftLabel(counts.draft),
        l10n.sharedAdStageDraftLabel,
        'draft',
      ),
    ];

    // The strip owns its own vertical breathing room rather than taking a
    // spacer from `my_listings_screen.dart`'s Column, so that hiding it
    // (no counts yet, or the endpoint failed) collapses the whole thing to
    // zero height instead of leaving an empty gap under the header. It is
    // small because each segment is a [TapTarget]: the visible pill is
    // 28dp, the hit box 48, and that 10dp of transparent padding above and
    // below already reads as spacing.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: SingleChildScrollView(
        key: const ValueKey('myListingsStageStrip'),
        scrollDirection: Axis.horizontal,
        // Horizontal scroll rather than a `Wrap` or a `Row` of `Expanded`s:
        // the Russian plural forms ("3 проданных", "2 черновика") and the
        // Uzbek ones ("2 ta qoralama") are materially longer than the
        // English ones, and four segments plus a 360dp screen is the case
        // where a fixed-width segmented control either truncates its own
        // numbers or overflows. Scrolling keeps every count fully legible
        // at every width; the leftmost segments (All/Active, the ones
        // tapped most) are the ones always visible without scrolling.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        child: Row(
          children: [
            for (final (stage, label, stageName, keySuffix) in segments) ...[
              _StageSegment(
                key: ValueKey('myListingsStageSegment-$keySuffix'),
                label: label,
                semanticsLabel: l10n.myListingsStageFilterSemanticsLabel(
                  stageName,
                ),
                selected: selected == stage,
                onTap: () => ref
                    .read(myListingsStatusProvider.notifier)
                    .setStatus(stage),
              ),
              if (keySuffix != 'draft') const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _StageSegment extends StatelessWidget {
  const _StageSegment({
    super.key,
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // `selected` is carried by a wrapping [Semantics] rather than by
    // [TapTarget] itself, which owns only `button`/`label`/`onTap`.
    // [MergeSemantics] folds the two nodes into one, so a screen reader
    // announces "Show Draft ads, selected, button" instead of a selected
    // container with an unrelated button inside it.
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: TapTarget(
          semanticsLabel: semanticsLabel,
          onTap: onTap,
          child: Container(
            height: 28,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            decoration: BoxDecoration(
              color: selected ? colors.pill : colors.sunk,
              borderRadius: AppRadii.pill,
            ),
            child: Text(
              label,
              // Tabular so the digits do not shuffle sideways when a count
              // ticks over from 9 to 10 while the strip is on screen.
              style: LaCasaTypography.tabular(type.bodySmall).copyWith(
                color: selected ? colors.pillInk : colors.ink2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
