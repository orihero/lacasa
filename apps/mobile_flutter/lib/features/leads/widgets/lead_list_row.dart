/// One row of `leads-list` (§30) — `#{id}`, full name, phone, Commit
/// (`Lead.comment`), status pill, source.
///
/// Built as the mockup's own `.trow` shape rather than on `CrmListTile`
/// (`shared/widgets/crm_list_tile.dart`): that widget's leading slot is a
/// mandatory 44×44 avatar, and a lead carries no photo of any kind — the
/// mockup's `.trow` for this screen has only `.trow__b` + `.trow__r`, with
/// `#{id}` flush against the card's own left padding. Routing through
/// `CrmListTile` meant every row was indented 56px behind initials derived
/// from nothing. `my-listings` and `coworkers-list` (which *do* have a
/// thumbnail/avatar) still use `CrmListTile`; this screen doesn't.
///
/// `.trow__b` stacks id → name → **bold** phone → Commit; `.trow__r`
/// right-aligns the status pill over the source label.
///
/// **The bold phone line is its own tap target, dialling through
/// [dialOrCopyPhone]** — the same affordance `leads-kanban`'s card carries,
/// for the same reason: this feature is the CRM an agent works their leads
/// from, and until this pass nothing anywhere in it could place a call.
/// The row's own tap (→ `lead-detail`) still owns every other pixel; only
/// the phone's own line is claimed, and Flutter resolves a tap to the
/// deepest hit-tested recognizer, so the two never contend.
///
/// This is a [ConsumerWidget] purely for that: [dialOrCopyPhone] needs a
/// [WidgetRef] to reach `linkLauncherProvider`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';

class LeadListRow extends ConsumerWidget {
  const LeadListRow({super.key, required this.lead, required this.onTap});

  final Lead lead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final phone = lead.phone?.trim();
    final commit = lead.comment?.trim();
    final source = lead.source?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final hasCommit = commit != null && commit.isNotEmpty;
    final hasSource = source != null && source.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Semantics(
        button: true,
        label: hasPhone ? '${lead.fullName}, $phone' : lead.fullName,
        child: GestureDetector(
          key: ValueKey('leadRow-${lead.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: GlassSurface(
            variant: GlassVariant.onSurface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            // `.trow{padding:11px 13px}`.
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: LayoutBuilder(
              builder: (context, constraints) => _row(
                context,
                ref,
                colors,
                type,
                trailingMaxWidth: constraints.maxWidth.isFinite
                    ? constraints.maxWidth * _trailingWidthShare
                    : double.infinity,
                phone: hasPhone ? phone : null,
                commit: hasCommit ? commit : null,
                source: hasSource ? source : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `.trow__r{flex:none}` doesn't overflow in the browser because
  /// `.trow__b` carries `min-width:0` and collapses first. Flutter's Row
  /// gives an inflexible child *unbounded* main-axis constraints instead,
  /// so a long free-text `Lead.source` — which the wire allows, unlike the
  /// mockup's one-word "Instagram" — pushed the whole row off the card.
  /// Capping the trailing column restores the CSS behaviour: it still sizes
  /// to its content when that content is short, and ellipsizes rather than
  /// overflowing when it isn't.
  static const double _trailingWidthShare = 0.4;

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    LaCasaColors colors,
    LaCasaTypography type, {
    required double trailingMaxWidth,
    required String? phone,
    required String? commit,
    required String? source,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Formatters.adIdBadge(lead.id),
                key: ValueKey('leadRowId-${lead.id}'),
                style: LaCasaTypography.tabular(
                  type.micro,
                ).copyWith(color: colors.faint),
              ),
              // `.trow__t{margin-top:1px}`.
              const SizedBox(height: 1),
              Text(
                lead.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.rowTitle.copyWith(color: colors.ink),
              ),
              if (phone != null) ...[
                // `.trow__m{margin-top:4px;font-size:10px;
                // color:var(--muted)}`; the phone is the one `.trow__m` the
                // mockup wraps in `<b>`, and `<b>` changes weight only — so
                // it shares the Commit line's `--muted` below, unlike
                // kanban's `.kcard__p`, which really is `--ink-2`. The 4px
                // top margin is dropped here: [TapTarget]'s shrink-wrapping
                // centre already contributes more than that above the glyph.
                //
                // `minSize` is below [TapTarget.minimumSize] deliberately —
                // the "say why" that widget's doc comment asks for: `.trow`
                // is a four-line stack inside 11px of vertical padding, and a
                // full 48dp row for the phone alone would roughly double
                // every row on the screen. 30dp still clears the ~13dp of
                // glyph the old inert `Text` occupied by a wide margin.
                TapTarget(
                  key: ValueKey('leadRowCall-${lead.id}'),
                  minSize: 30,
                  semanticsLabel: AppLocalizations.of(
                    context,
                  ).leadsCallSemanticsLabel(phone),
                  onTap: () => dialOrCopyPhone(context, ref, phone),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: 11, color: colors.muted),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LaCasaTypography.tabular(type.bodySmall)
                              .copyWith(
                                color: colors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (commit != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  commit,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
              ],
            ],
          ),
        ),
        // `.trow{gap:11px}`.
        const SizedBox(width: 11),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: trailingMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LeadStatusPill(status: lead.status),
              if (source != null) ...[
                // `.trow__r{gap:5px}`.
                const SizedBox(height: 5),
                Text(
                  source,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: type.micro.copyWith(color: colors.faint),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
