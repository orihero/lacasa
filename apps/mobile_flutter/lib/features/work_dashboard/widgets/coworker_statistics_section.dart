/// SCREENS.md §24's "Coworker statistics" section — "bar chart per coworker
/// (Ads count / Lead count / Sale count) plus a list with the same columns
/// ... Tap coworker row → coworker-detail."
///
/// **All three columns are real now.** "Sale count" used to render as a
/// permanent em dash — ruling 7.6 originally read "'deals closed'/a 6th
/// 'Success' lead status does not exist anywhere in the schema" as "there is
/// nothing to derive this from." That first half is still true (no such
/// lead status exists), but it was the wrong question: `AD_SOLD` activity
/// events always carried `coworkerId`, the same stream `GET
/// /statistics/coworkers` already exposes for "Ads count" — so
/// [CoworkerStatRow.saleCount] folds that stream by
/// `ActivityEventStage.adSold` exactly the way `adsCount` folds it by
/// `adCreated`. [CoworkerStatRow.leadCount] is the one column read off a
/// different source — `GET /leads` filtered by [Lead.coworkerId] and
/// [Lead.createdAt], not the event stream (`state/dashboard_providers.dart`'s
/// `coworkerStatRowsProvider` doc comment explains why that tie breaks the
/// way it does). "Different source" is not "different rules": it obeys the
/// time-range chip exactly as the other two do — see below.
///
/// **All three columns — both the bars in [_BarRow] and the numbers in the
/// list below them — are scoped to the time-range chip at the top of the
/// screen.** "Lead count" used to be the exception: it folded every lead the
/// coworker had ever owned while "Ads count"/"Sale count" beside it obeyed
/// the selector, so choosing "Today" drew a full-height middle bar next to
/// two empty ones and a row reading `Ads 0 · Leads 14 · Sales 0`. It now runs
/// [Lead.createdAt] through the same `isWithinTimeRange` predicate the other
/// two use, so a range selection moves all three together.
///
/// **Every bar carries its own number.** [_BarRow] used to print exactly one
/// figure — `row.adsCount` — at the right of a three-bar stack, so the Leads
/// and Sales bars were unreadable lengths: a viewer could see that one was
/// longer than the other but never by how much, and the two colours were the
/// only thing telling them apart. All three are labelled now, which is what
/// makes the chart worth keeping beside the table below it: the table gives
/// the numbers, the bars give relative magnitude at a glance (§24 asks for
/// both, so the chart is not redundant — see this feature's report for the
/// spec question about how much overlap is intended).
///
/// Row tap uses `context.go`, not `context.push`, per
/// `WORK_TAB_CONTRACT.md` §2.2: `coworker-detail` is named there as one of
/// the three Work-only-concept screens that always navigate by `go`, even
/// from inside the Work branch itself.
///
/// The section as a whole is only mounted for a session that can have
/// coworkers at all (`dashboard_screen.dart` gates it on
/// [canManageCoworkersProvider]); the "No coworkers yet." empty state
/// therefore always belongs to an **agency** agent, who can act on it — so
/// it carries an "Add coworker" action straight to `add-coworker` rather
/// than being a dead panel.
///
/// That action uses `context.go` for the same reason the row tap above it
/// does, and this one is the plainer case: `add-coworker` is declared under
/// `RoutePaths.workCoworkers` in `app_router.dart`, i.e. inside the
/// **Coworkers** `StatefulShellBranch`, while this widget renders in the
/// **Dashboard** branch. `WORK_TAB_CONTRACT.md` §2.2 is explicit that
/// `push` "only makes sense within one branch's own stack" and that
/// crossing branches goes by absolute path with `go` — which is also what
/// makes the destination land on a real stack (`[coworkers, add-coworker]`,
/// so Back reveals the roster the new coworker was just added to) instead
/// of a page pushed into a branch navigator that is not the one on screen.
/// `coworkers_list_screen.dart` pushes the identical path and is right to:
/// it is already inside that branch. This is not.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/dashboard_providers.dart';
import 'dashboard_colors.dart';

class CoworkerStatisticsSection extends ConsumerWidget {
  const CoworkerStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(coworkerStatRowsProvider);
    final l10n = AppLocalizations.of(context);

    return rowsAsync.when(
      loading: () => const _Panel(
        child: SizedBox(
          height: 96,
          child: Center(child: ShimmerBox(width: 220, height: 48)),
        ),
      ),
      error: (error, stackTrace) => _Panel(
        child: RailRetryCard(
          width: double.infinity,
          message: l10n.dashboardCoworkerStatisticsLoadErrorMessage,
          onRetry: () => ref.invalidate(dashboardCoworkersProvider),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _Panel(
            child: FullWidthState(
              key: const ValueKey('dashboardNoCoworkersState'),
              icon: Icons.groups_outlined,
              message: l10n.dashboardNoCoworkersMessage,
              // See this file's doc comment: only an agency agent ever
              // reaches this state, and `POST /coworkers` accepts them, so
              // the panel offers the one action that resolves it. The
              // predicate is re-checked here rather than assumed, so this
              // widget stays correct if it is ever mounted from somewhere
              // that does not gate it.
              actionLabel: ref.watch(canManageCoworkersProvider)
                  ? l10n.dashboardAddCoworkerButtonLabel
                  : null,
              // `go`, not `push` — `add-coworker` lives in the Coworkers
              // branch and this panel does not. See this file's doc comment.
              onAction: () => context.go(RoutePaths.workAddCoworker),
            ),
          );
        }
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoworkerBarChart(rows: rows),
              const SizedBox(height: AppSpacing.base),
              _Legend(),
              const SizedBox(height: AppSpacing.section),
              _CoworkerList(rows: rows),
            ],
          ),
        );
      },
    );
  }
}

/// One `.panel{background:var(--card);border-radius:22px;padding:16px 14px;
/// box-shadow:0 12px 26px -22px rgba(30,24,44,.6)}` — a solid card, not a
/// glass lens: the mockup marks none of its three `.panel`s `gl`, and the
/// contrast against the glass tiles elsewhere on this screen is deliberate.
/// Same box as `ads_statistics_panel.dart`'s own panel.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpacing.lg,
      ),
      child: child,
    );
  }
}

class _CoworkerBarChart extends StatelessWidget {
  const _CoworkerBarChart({required this.rows});

  final List<CoworkerStatRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxCount = rows.fold<int>(
      1,
      (max, row) => [
        max,
        row.adsCount,
        row.leadCount,
        row.saleCount,
      ].reduce((a, b) => a > b ? a : b),
    );

    return Column(
      children: [
        for (final row in rows) ...[
          _BarRow(row: row, maxCount: maxCount),
          if (row != rows.last) const SizedBox(height: AppSpacing.base),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.row, required this.maxCount});

  final CoworkerStatRow row;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);
    final firstName = row.coworker.fullName.trim().split(RegExp(r'\s+')).first;

    double fractionOf(int value) => maxCount == 0 ? 0 : value / maxCount;

    return Semantics(
      // Three bars and three bare numbers read as six unrelated fragments
      // to a screen reader; one sentence per coworker is the whole row.
      // `excludeSemantics` drops those fragments — the name is already in
      // the label, and the same three figures are announced again by the
      // table below, which is the surface a reader can actually navigate
      // cell by cell.
      label: l10n.dashboardCoworkerBarsSemanticsLabel(
        row.coworker.fullName,
        row.adsCount,
        row.leadCount,
        row.saleCount,
      ),
      excludeSemantics: true,
      child: Row(
        key: ValueKey('coworkerBarRow-${row.coworker.id}'),
        children: [
          // `.bar-row__n{width:66px;flex:none;font-size:10.5px;
          // font-weight:500;color:var(--ink-2)}` — `specMeta` is that
          // 10.5/500 role.
          SizedBox(
            width: 64,
            child: Text(
              firstName,
              overflow: TextOverflow.ellipsis,
              style: type.specMeta.copyWith(color: colors.ink2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabelledTrack(
                  fraction: fractionOf(row.adsCount),
                  gradient: AppAccent.gradient,
                  value: row.adsCount,
                ),
                const SizedBox(height: AppSpacing.xs),
                _LabelledTrack(
                  fraction: fractionOf(row.leadCount),
                  gradient: kDashboardLeadBarGradient,
                  value: row.leadCount,
                ),
                const SizedBox(height: AppSpacing.xs),
                _LabelledTrack(
                  fraction: fractionOf(row.saleCount),
                  gradient: kDashboardSaleBarGradient,
                  value: row.saleCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One bar and the number it draws — `.bar-row__b` plus `.bar-row__v`.
///
/// **The value moved from the end of the row onto each bar.** The mockup
/// puts a single `.bar-row__v` at the row's right edge, which works for its
/// one-bar-per-row markup and does not for the three-series stack this
/// section actually renders: one number beside three bars labels the first
/// and silently leaves the other two as lengths (a 4 and a 40 look the same
/// when nothing states the scale). Each bar now carries its own figure in
/// the same `.bar-row__v` box — 30dp, right-aligned, tabular, so a
/// three-digit count still fits on one line and every row's numbers form a
/// straight column.
class _LabelledTrack extends StatelessWidget {
  const _LabelledTrack({
    required this.fraction,
    required this.gradient,
    required this.value,
  });

  final double fraction;
  final Gradient gradient;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      children: [
        Expanded(
          child: _Track(fraction: fraction, gradient: gradient),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            maxLines: 1,
            style: LaCasaTypography.tabular(
              type.specMeta,
            ).copyWith(fontWeight: FontWeight.w600, color: colors.ink),
          ),
        ),
      ],
    );
  }
}

/// One `.bar-row__b` — a 7px gradient-filled bar drawn at its own width.
/// The mockup paints **no** track behind it (`.bar-row__t` holds nothing
/// but the three filled bars), so neither does this: an empty remainder is
/// left as background rather than a `--sunk` rail.
class _Track extends StatelessWidget {
  const _Track({required this.fraction, required this.gradient});

  final double fraction;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 7,
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1).toDouble(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children:
          [
                _dot(context, AppAccent.color, l10n.dashboardLegendAdsCount),
                _dot(
                  context,
                  kDashboardSoldColor,
                  l10n.dashboardLegendLeadCount,
                ),
                _dot(
                  context,
                  kDashboardSaleColor,
                  l10n.dashboardLegendSaleCount,
                ),
              ]
              .map(
                (child) => DefaultTextStyle.merge(
                  style: type.specMeta.copyWith(color: colors.muted),
                  child: child,
                ),
              )
              .toList(),
    );
  }

  /// `.legend i{width:9px;height:9px;border-radius:3px}` — a rounded
  /// square swatch with a 6px gap, matching `ads_statistics_panel.dart`'s
  /// own legend.
  Widget _dot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
      ],
    );
  }
}

class _CoworkerList extends StatelessWidget {
  const _CoworkerList({required this.rows});

  final List<CoworkerStatRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _HeaderCell(
                l10n.dashboardHeaderCoworkers,
                width: null,
                textAlign: TextAlign.left,
              ),
            ),
            _HeaderCell(l10n.dashboardHeaderAds),
            _HeaderCell(l10n.dashboardHeaderLeads),
            _HeaderCell(l10n.dashboardHeaderSales),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Divider(height: 1, color: colors.line),
        // `.cw__r:last-child{border-bottom:0}` — the table's last row draws
        // no rule under itself.
        for (final row in rows)
          _CoworkerListRow(row: row, isLast: row == rows.last),
      ],
    );
  }
}

/// The width of each numeric column — header cell and data cell alike, which
/// is the only reason the two rows line up at all.
///
/// **56, not 44.** Russian needs ~65dp for "ОБЪЯВЛЕНИЯ" at the 10px `label`
/// role, so at 44 the header wrapped to two or three lines while the row
/// below it stayed one line tall, and the header row drifted out of
/// alignment with its own table. 56 plus the single-line ellipsis below
/// keeps the header honest at a width three columns of it still fit inside
/// a 360dp screen.
const double _numericColumnWidth = 56;

/// One column heading. Also the one place the table's headings are
/// uppercased.
///
/// **The `.toUpperCase()` is here, not in the ARB.** The four
/// `dashboardHeader*` values used to be stored pre-uppercased in all three
/// locales ("ОБЪЯВЛЕНИЯ", "E'LONLAR"), which is unreadable for a translator
/// and contradicts `LaCasaTypography.label`'s own rule — that role is
/// "ALWAYS uppercase (apply `.toUpperCase()` to the string)", i.e. at the
/// call site. The ARBs hold sentence case now and this call is what renders
/// them the way `.cw__h{text-transform:uppercase}` asks for, so it is
/// **required**, not cosmetic: drop it and the table headings silently
/// become sentence case.
///
/// `dashboard_stat_tiles.dart` came at the same rule from the other side in
/// the same pass — its ARB values were already sentence case but it drew
/// them verbatim, so its tile labels were the ones rendering wrong. Both
/// surfaces on this screen now do the same thing.
class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    this.width = _numericColumnWidth,
    this.textAlign = TextAlign.right,
  });

  final String label;

  /// `null` for the coworker-name column, which is an [Expanded] flex-3
  /// cell rather than a fixed box.
  final double? width;

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    // One line, always: a wrapped heading is exactly the misalignment this
    // column width exists to prevent, and an ellipsised "ОБЪЯВЛ…" over a
    // column of numbers still reads as the right heading.
    final text = Text(
      label.toUpperCase(),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: type.label.copyWith(color: colors.muted),
    );

    return width == null ? text : SizedBox(width: width, child: text);
  }
}

class _CoworkerListRow extends StatelessWidget {
  const _CoworkerListRow({required this.row, required this.isLast});

  final CoworkerStatRow row;

  /// The bottom rule is skipped on the final row (`.cw__r:last-child`).
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: row.coworker.fullName,
      child: GestureDetector(
        key: ValueKey('coworkerStatListRow-${row.coworker.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => context.go(
          RoutePaths.workCoworkerDetail.replaceFirst(':id', row.coworker.id),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          decoration: isLast
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.line)),
                ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    AgentAvatar(
                      avatarUrl: row.coworker.avatar,
                      fullName: row.coworker.fullName,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        row.coworker.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: type.rowTitle.copyWith(color: colors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              // Same [_numericColumnWidth] as the headings above — the two
              // rows only line up because they share the constant.
              _ValueCell(value: row.adsCount),
              _ValueCell(value: row.leadCount),
              _ValueCell(value: row.saleCount),
            ],
          ),
        ),
      ),
    );
  }
}

/// One number in the table — the data-row counterpart of [_HeaderCell], and
/// pinned to the same [_numericColumnWidth] so the two rows share a grid.
class _ValueCell extends StatelessWidget {
  const _ValueCell({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return SizedBox(
      width: _numericColumnWidth,
      child: Text(
        '$value',
        textAlign: TextAlign.right,
        maxLines: 1,
        style: LaCasaTypography.tabular(
          type.bodySmall,
        ).copyWith(color: colors.ink2),
      ),
    );
  }
}
