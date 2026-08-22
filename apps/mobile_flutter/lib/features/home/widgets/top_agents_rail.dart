/// The Top Agents rail: 5 compact chips bound to [topAgentsProvider]
/// (build spec, "Top Agents rail"). First-name-only caption per the
/// mockup's `.agent__n` content, deliberately distinct from every other
/// screen's `fullName` convention.
///
/// ## The caption is the rating, not the ad count
/// It used to read "24 ads", under a heading that says "Top Agents", in a
/// rail ranked by `adsCount` descending
/// (`data/live_home_feed_repository.dart`). Three things pointing the same
/// way turn a volume statistic into an endorsement the data never made: the
/// agent who posts most is not the agent a buyer should call, and the
/// caption was the only part of that claim visible enough to matter.
/// [AgentSummary.ratingAverage]/[AgentSummary.ratingCount] arrive on the
/// very same objects and were being thrown away, so the caption now prints
/// what the heading implies — `homeAgentRatingCaption`'s compact
/// "★ 4.6 (12)".
///
/// **`ratingAverage == null` renders "No reviews yet", never a zero-star
/// row** — the rule `shared/widgets/rating_stars.dart` and
/// [AgentSummary.ratingAverage]'s own doc comment pin down: a SQL aggregate
/// over zero rows produces no row, not a row averaging to zero, so `null`
/// and `0.0` are different facts and collapsing them would invent the
/// worst possible signal (a one-star-looking agent who has simply never
/// been reviewed). [RatingStars] itself is not reused here: it lays out
/// five 13px icons plus "Review: 4.6/5", which cannot fit a 62px column at
/// the 9px `.agent__c` tier — the glyph in the localized caption is that
/// widget's star rendered as punctuation.
///
/// **Still ranked by `adsCount`, still called "Top Agents".** Both need
/// product sign-off (ranking by rating changes who is promoted; renaming
/// the section changes what the screen promises) and are reported rather
/// than changed here.
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

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';

/// `.agents{gap:14px}`, `.agent{width:62px;gap:6px}`,
/// `.agent__av{width:56px;height:56px}` — a 56px avatar centred in a 62px
/// column, not a 62px avatar.
const double _avatarSize = 56;
const double _railGap = 14;
const double _captionGap = 6;

/// Tall enough for the **two-line** caption, which is the common case rather
/// than the exotic one: `sharedNoReviewsYetLabel` is what every agent nobody
/// has rated yet gets, and at the `.agent__c` micro tier (9.25px Poppins) it
/// measures ~69px against a 62px column in English — ~86px as "Пока нет
/// отзывов", ~80px as "Hali sharhlar yo'q". One line therefore ships
/// ellipsized ("No reviews ye…") for most of the rail, which is the one
/// caption a reader most needs to read whole: truncated, it no longer
/// distinguishes "unreviewed" from a rating.
///
/// Widening the column was the other option and does not actually work —
/// 62 → 86px would fit English and still clip both other locales — so the
/// caption wraps instead and the rail grows to fit it (see [_Rail]). The
/// mockup itself centres both captions
/// (`.agent__n`/`.agent__c{text-align:center}`), which is what makes the
/// wrapped second line read as part of the same column.
///
/// `.agent__n{font-size:10.5px}`.
const double _nameFontSize = 10.5;

/// `.agent{width:62px}`.
const double _columnWidth = 62;

class TopAgentsRail extends ConsumerWidget {
  const TopAgentsRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final l10n = AppLocalizations.of(context);
    final agents = ref.watch(topAgentsProvider);

    return agents.when(
      loading: () => _Shell(
        child: _Rail(
          children: List.generate(
            5,
            (index) => const SizedBox(
              width: _columnWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(
                    width: _avatarSize,
                    height: _avatarSize,
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                  SizedBox(height: _captionGap),
                  ShimmerBox(width: 44, height: 8),
                  SizedBox(height: 3),
                  ShimmerBox(width: 34, height: 7),
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
            message: l10n.homeTopAgentsRetryMessage,
            // `asReload: true` for the reason spelled out in full at
            // `featured_listings_rail.dart`'s matching retry: a plain
            // invalidate is a refresh, `when`'s `skipLoadingOnRefresh`
            // defaults to true, and the `error:` arm would simply re-render
            // itself — a Retry tap with no visible consequence until the
            // request lands. A reload produces a real `AsyncLoading`, so the
            // five skeleton columns above come back while the fetch runs.
            onRetry: () => ref.invalidate(topAgentsProvider, asReload: true),
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        return _Shell(
          child: _Rail(
            children: [
              for (final agent in list)
                Builder(
                  builder: (context) {
                    final nameParts = agent.fullName.trim().split(
                      RegExp(r'\s+'),
                    );
                    final firstName =
                        nameParts.isNotEmpty && nameParts.first.isNotEmpty
                        ? nameParts.first
                        : agent.fullName;
                    final rating = agent.ratingAverage;
                    return GestureDetector(
                      key: ValueKey('agentChip-${agent.id}'),
                      onTap: () => context.push('/home/agent/${agent.id}'),
                      child: SizedBox(
                        width: _columnWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AgentAvatar(
                              avatarUrl: agent.avatar,
                              fullName: agent.fullName,
                              size: _avatarSize,
                            ),
                            const SizedBox(height: _captionGap),
                            // `.agent__n{font-size:10.5px;font-weight:600;
                            // text-align:center}`. `maxLines: 1` is what makes
                            // the ellipsis above actually apply: the column's
                            // height is unbounded from this [Text]'s point of
                            // view, so without it a long first name wraps and
                            // pushes the caption out of the rail instead of
                            // truncating.
                            Text(
                              firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: type.rowTitle.copyWith(
                                color: colors.ink,
                                fontSize: _nameFontSize,
                              ),
                            ),
                            // `.agent__c{font-size:9px;font-weight:400;
                            // color:var(--faint);text-align:center}` — one step
                            // quieter than the name above it, the same tier the
                            // feed's listing cards paint their `.where` line in.
                            //
                            // The null branch is the one that matters: see this
                            // file's doc comment. `ratingAverage` is printed at
                            // the server's own one-decimal precision, never
                            // rounded further and never defaulted.
                            //
                            // Two lines, because that null branch does not
                            // fit one in any of the three locales. The rail
                            // grows to whatever those two lines actually
                            // measure rather than reserving a guess — see
                            // this file's doc comment. The rating caption
                            // ("★ 4.6 (12)", ~48px) still takes a single
                            // line everywhere; nothing about it changes.
                            Text(
                              rating == null
                                  ? l10n.sharedNoReviewsYetLabel
                                  : l10n.homeAgentRatingCaption(
                                      rating.toStringAsFixed(1),
                                      agent.ratingCount,
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: type.micro.copyWith(color: colors.faint),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The rail itself: a horizontally scrolling [Row] rather than a
/// fixed-height [ListView], because **it states no height at all**.
///
/// This was `SizedBox(height: _railHeight)` over a `ListView.separated`,
/// where `_railHeight` was the constant 104 — hand-derived as "56 avatar +
/// 6 gap + one 10.5px name line + two 9.25px caption lines, all at Poppins'
/// 1.4 line height = 102.6px, rounded up". Every agent column overflowed it
/// by 3px on a simulator, clipping the second line of "Пока нет отзывов"
/// away and leaving the caption reading as a bare "Пока нет" — precisely
/// the truncation the two-line caption exists to prevent.
///
/// Two rounds of arithmetic failed to close that gap, and that is the point
/// rather than an aside: nothing about the column's height is knowable up
/// front. `app_typography.dart`'s `_s` leaves `height` null, so the line box
/// comes from whichever font actually resolves — Poppins over
/// `google_fonts`, or a platform fallback while that download is in flight,
/// and *a different fallback again* for a caption's Cyrillic run, with
/// metrics of its own. Add [MediaQuery.textScalerOf] and any constant,
/// measured or not, is a guess carrying a per-locale failure mode.
///
/// At most five items ship here, which is exactly the case a lazy
/// [ListView] buys nothing for. So: a [SingleChildScrollView] over a [Row]
/// of shrink-wrapping columns, where the tallest column sets the rail's
/// height — whatever the font, the script and the text scale conspire to
/// make that. Nothing here can overflow.
///
/// [CrossAxisAlignment.start] hangs every column from the avatars' shared
/// top edge, so a two-line caption beside a one-line one grows downward
/// instead of shunting its own avatar out of line.
class _Rail extends StatelessWidget {
  const _Rail({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            // `.agents{gap:14px}`, between items only.
            if (i > 0) const SizedBox(width: _railGap),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeTopAgentsSectionTitle,
          linkLabel: l10n.homeTopAgentsExploreLinkLabel,
          onLink: () => context.go(RoutePaths.agents),
        ),
        const SizedBox(height: AppSpacing.base),
        child,
      ],
    );
  }
}
