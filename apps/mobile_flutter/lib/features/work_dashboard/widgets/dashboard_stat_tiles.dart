/// SCREENS.md §24's 2×2 stat-tile grid — "Ads created" / "Ads sold" /
/// "Active leads" / "Coworkers", matching `mockup-e-liquid-glass.html`'s
/// `.tile gl` rows exactly (the shipped mockup has four tiles; SCREENS.md
/// §3.24's own prose only names the first two, but §4.5's seed-data table is
/// titled "Dashboard stat metrics (4)" and `apps/console`'s own
/// `StatisticsScreen` renders the identical four — see this feature's own
/// `dashboard_repository.dart` doc comment for the same "shipped mockup over
/// terse prose" precedent `home_feed_screen.dart` already established).
///
/// Each tile reads its own [AsyncValue] independently (`WORK_TAB_CONTRACT.md`
/// §6's "independent providers per independently-failable section") — a
/// failed leads fetch shows "—" on the Active leads tile without touching
/// the other three.
///
/// **The "Active leads" tile counts [countActiveLeads], not `leads.length`.**
/// It used to render the raw size of the `GET /leads` table, which counts
/// every lead ever created — archived rows and closed (`rejected`/`accepted`)
/// conversations included — so the tile contradicted its own label as soon as
/// an agent had any history at all. `dashboard_workspace_links.dart`'s Leads
/// row calls that same shared helper for its `{n} active` figure; see the
/// helper's own doc comment for exactly which leads it excludes and why.
///
/// **The tile's subtitle counts callbacks over the same population as its
/// value** — [countCallbacksDueToday] applies [countActiveLeads]' own
/// predicate before folding, so the subtitle can never claim more callbacks
/// than the number printed above it. That relationship was free while the
/// value was `leads.length` (nothing can be a larger subset of the table
/// than the table) and had to be made explicit the moment the value became a
/// filtered count: one closed lead left carrying a stale `callbackDate`
/// would otherwise render this tile as "0" over "1 needs a call back".
/// Nothing here re-derives the rule — both figures come from the two helpers
/// in `state/dashboard_providers.dart`, which share the predicate.
///
/// **Every tile is tappable, and each tap lands on the list its own number
/// counts.** Only "Coworkers" used to carry an `onTap`, which made the other
/// three read as decoration — a number with no way to see what is behind it —
/// and made the one gesture that did exist undiscoverable, since nothing
/// about the tile set said which of the four answered a tap. Each tile now
/// opens the screen it names, and nothing more.
///
/// **No tile presets `my-listings`' stage filter on the way in.** The
/// "Ads sold" tile briefly did — it is the one figure on this screen with no
/// affordance that reaches the rows behind it, so writing
/// `myListingsStatusProvider` looked like the missing half of the tap. It is
/// not: that provider is a plain global `Notifier`, not `autoDispose`, and
/// nothing anywhere clears it. One tap here left the user's My Ads screen
/// narrowed to Sold for the rest of the session — reachable again by the tab
/// bar, by a deep link, by anything, and always missing most of their
/// listings, with the CRM filter sheet the only surface that reveals why.
/// The two ways to keep the preset both need code inside
/// `lib/features/my_listings/` (a stage read off the route and applied for
/// that visit only, or a clear when the screen is disposed); a *dashboard*
/// that writes another screen's session-long state and cannot un-write it is
/// the one option that strands someone, so this navigates and leaves the
/// filter exactly as the user last set it. See this feature's report for the
/// one-shot seam My Ads would have to grow.
///
/// The subtitles stay what they were (the selected range, the callback
/// count): they carry information the Workspace rows below do not repeat, so
/// none of them is given up for a "tap to …" hint. The hint is attached as
/// [Semantics.hint] instead, for the one audience that cannot see a tile
/// respond to a press.
///
/// **The "Coworkers" tile is hidden for a solo realtor**
/// ([canManageCoworkersProvider]) — see `dashboard_screen.dart`'s doc
/// comment. The "Active leads" tile then takes the whole second row rather
/// than leaving a hole beside it.
///
/// **The four labels render uppercased, which they did not use to.** They
/// were drawn verbatim from the ARB ("Ads created", "Коллеги") while the
/// mockup's `.tile__l` carries `text-transform:uppercase` and the theme role
/// they use says so out loud — `LaCasaTypography.label` is documented as
/// "10/600, ALWAYS uppercase (apply `.toUpperCase()` to the string)". This
/// is a deliberate copy change, not a refactor: "ADS CREATED" is what ships
/// now. `coworker_statistics_section.dart`'s `_HeaderCell` was fixed the
/// other way round in the same pass — its ARB values held pre-uppercased
/// text, which is unreadable for a translator and wrong for a locale with
/// no case — so the two surfaces on this screen now follow one rule:
/// sentence case in the ARB, `.toUpperCase()` at the call site.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../state/dashboard_providers.dart';

String _rangeSubtitle(AppLocalizations l10n, StatisticsFilter filter) =>
    switch (filter) {
      StatisticsFilter.all => l10n.dashboardRangeSubtitleAll,
      StatisticsFilter.thisMonth => l10n.dashboardRangeSubtitleThisMonth,
      StatisticsFilter.thisWeek => l10n.dashboardRangeSubtitleThisWeek,
      StatisticsFilter.today => l10n.dashboardRangeSubtitleToday,
    };

String _callbackSubtitle(AppLocalizations l10n, int dueToday) =>
    l10n.dashboardCallbackSubtitle(dueToday);

class DashboardStatTiles extends ConsumerWidget {
  const DashboardStatTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashboardTimeRangeProvider);
    final adsStats = ref.watch(adsStatisticsProvider);
    final leadsAsync = ref.watch(dashboardLeadsProvider);
    final canManageCoworkers = ref.watch(canManageCoworkersProvider);
    // See `dashboard_workspace_links.dart`'s identical guard: a solo
    // realtor renders no coworker surface, so the roster is not fetched.
    final coworkersAsync = canManageCoworkers
        ? ref.watch(dashboardCoworkersProvider)
        : const AsyncValue<List<Coworker>>.data(<Coworker>[]);
    final l10n = AppLocalizations.of(context);
    final rangeLabel = _rangeSubtitle(l10n, range);
    final tapHint = l10n.dashboardTileTapToViewSubtitle;

    // Both ad tiles open `my-listings` as the user left it — see this
    // file's doc comment for why neither writes that screen's stage filter
    // on the way in.
    void openMyListings() => context.push(RoutePaths.workMyListings);

    return Column(
      children: [
        // `CrossAxisAlignment.stretch` under an `IntrinsicHeight`, not the
        // default centre alignment: two tiles whose content differs in
        // height (a two-line subtitle in ru, a `Retry` row on one of them
        // only) otherwise render as two differently-sized cards floating
        // about a shared centre line. Stretch alone cannot do it here —
        // this column sits in a `SingleChildScrollView`, so the row's
        // incoming `maxHeight` is infinite and `stretch` would hand its
        // children a tight infinite height; `IntrinsicHeight` resolves the
        // taller tile's height first and makes that constraint finite. Two
        // children per row keeps the intrinsic pass cheap.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  key: const ValueKey('dashboardTile-adsCreated'),
                  label: l10n.dashboardTileAdsCreatedLabel,
                  valueAsync: adsStats.whenData((s) => s.adsNewCount),
                  subtitle: rangeLabel,
                  onRetry: () => ref.invalidate(adsStatisticsProvider),
                  onTap: openMyListings,
                  tapHint: tapHint,
                ),
              ),
              // `.two{gap:11px}` applies to both axes.
              const SizedBox(width: 11),
              Expanded(
                child: _StatTile(
                  key: const ValueKey('dashboardTile-adsSold'),
                  label: l10n.dashboardTileAdsSoldLabel,
                  valueAsync: adsStats.whenData((s) => s.adsSoldCount),
                  subtitle: rangeLabel,
                  onRetry: () => ref.invalidate(adsStatisticsProvider),
                  onTap: openMyListings,
                  tapHint: tapHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  key: const ValueKey('dashboardTile-activeLeads'),
                  label: l10n.dashboardTileActiveLeadsLabel,
                  valueAsync: leadsAsync.whenData(countActiveLeads),
                  subtitle: leadsAsync.whenOrNull(
                    data: (leads) =>
                        _callbackSubtitle(l10n, countCallbacksDueToday(leads)),
                  ),
                  onRetry: () => ref.invalidate(dashboardLeadsProvider),
                  onTap: () => context.push(RoutePaths.workLeads),
                  tapHint: tapHint,
                ),
              ),
              if (canManageCoworkers) ...[
                // `.two{gap:11px}` applies to both axes.
                const SizedBox(width: 11),
                Expanded(
                  child: _StatTile(
                    key: const ValueKey('dashboardTile-coworkers'),
                    label: l10n.dashboardTileCoworkersLabel,
                    valueAsync: coworkersAsync.whenData((list) => list.length),
                    // The one tile whose subtitle already states its own
                    // gesture, so it needs no separate hint.
                    subtitle: l10n.dashboardTileTapToManageSubtitle,
                    onRetry: () => ref.invalidate(dashboardCoworkersProvider),
                    onTap: () => context.push(RoutePaths.workCoworkers),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.label,
    required this.valueAsync,
    required this.onRetry,
    this.subtitle,
    this.onTap,
    this.tapHint,
  });

  final String label;
  final AsyncValue<int> valueAsync;
  final String? subtitle;
  final VoidCallback onRetry;
  final VoidCallback? onTap;

  /// Spoken after the tile's own label/subtitle, never drawn: the visible
  /// subtitles here carry real data (the selected range, the callback
  /// count) and are not given up for a "tap to view" line. Left `null` on
  /// the one tile whose visible subtitle already announces its gesture.
  final String? tapHint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final Widget valueWidget = valueAsync.when(
      loading: () =>
          Text('…', style: type.numericDisplay.copyWith(color: colors.faint)),
      error: (error, stackTrace) => Text(
        '—',
        style: type.numericDisplay.copyWith(color: AppStatusColors.errorText),
      ),
      data: (value) => Text(
        '$value',
        style: type.numericDisplay.copyWith(color: colors.ink),
      ),
    );

    final Widget? subtitleWidget = valueAsync.hasError
        ? GestureDetector(
            onTap: onRetry,
            child: Text(
              AppLocalizations.of(context).sharedRetryLabel,
              style: type.bodySmall.copyWith(
                color: AppAccent.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : (subtitle == null
              ? null
              // `.tile__d{margin-top:3px;font-size:10.5px;color:var(--faint)}`
              // — `--faint`, a step below the `--muted` label above it, and
              // no `font-weight`, so `bodySmall`'s w400 is the right one
              // (`specMeta` would wrongly bring w500).
              : Text(
                  subtitle!,
                  // Two lines, then ellipsis: "1 needs a call back" and the
                  // ru/uz range labels do not fit one 10.5px line in half a
                  // 360dp screen, and truncating a count mid-sentence is
                  // worse than a second line. The tiles stay level with each
                  // other regardless — see the `IntrinsicHeight` above.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(
                    fontSize: 10.5,
                    color: colors.faint,
                  ),
                ));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // `.tile__l` is `text-transform:uppercase` — the uppercasing lives
        // at the call site, never in the ARB, so ru/uz strings stay
        // human-readable (see `AppTypography.label`'s own doc comment).
        //
        // One line, always. Uppercased ru labels ("АКТИВНЫЕ ЛИДЫ") run past
        // half a 360dp screen at the `label` role, and a label that wraps
        // pushes its own tile's value and subtitle down past the tile
        // beside it — the misalignment this whole grid reads as broken.
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 6),
        valueWidget,
        if (subtitleWidget != null) ...[
          // `.tile__d{margin-top:3px}`.
          const SizedBox(height: 3),
          subtitleWidget,
        ],
      ],
    );

    final tile = GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );

    if (onTap == null) return tile;

    // **The number goes in the spoken label.** It used to read "Ads
    // created, this month" — the label and the subtitle with the one figure
    // the tile exists to show missing from between them, so the tile
    // announced its own caption and nothing else. Only a *resolved* value
    // is spoken: the loading "…" and the failed "—" are glyphs standing in
    // for a number, and reading them aloud would state a magnitude the tile
    // does not have. On failure the visible subtitle is replaced by the
    // Retry control too, so the stale range line is dropped with it rather
    // than spoken over a tile showing no value.
    //
    // Composed with ", " only — no words — so nothing here needs an ARB
    // string or a per-locale word order, exactly as the label/subtitle pair
    // already was.
    final spokenValue = valueAsync.whenOrNull(data: (value) => '$value');
    final spokenSubtitle = valueAsync.hasError ? null : subtitle;

    return Semantics(
      button: true,
      label: [label, ?spokenValue, ?spokenSubtitle].join(', '),
      hint: tapHint,
      // Carried on the annotation itself, not left to the [GestureDetector]
      // below — `excludeSemantics` drops the whole descendant subtree, the
      // detector's own `tap` action included, which is exactly the bug
      // `category_chip_row.dart`'s chips already shipped once: a node that
      // announced itself as a button and did nothing when TalkBack
      // double-tapped it.
      onTap: onTap,
      // One node per tile while there is a value to speak, so the label,
      // the number and the subtitle are not three stray fragments a reader
      // has to reassemble. Not excluded in the error case: the Retry inside
      // is the whole point of that state and has to stay reachable.
      excludeSemantics: !valueAsync.hasError,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}
