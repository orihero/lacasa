/// The tap-to-open row shape `my-listings` (§25), `leads-list` (§30) and
/// `coworkers-list` (§35) all reduce to: a leading thumbnail/avatar, a
/// title line, an optional subtitle line, and a trailing slot (a status
/// pill, an edit icon button, a count — each screen's own). Promoted here
/// rather than each of the three features building a near-identical
/// `Row`+`GlassSurface` wrapper, following this codebase's own "second
/// caller promotes it" rule (see `list_row.dart`'s doc comment for the
/// precedent this follows) — three real, independently-planned call sites
/// clear that bar on day one, unlike a hypothetical single-feature need.
///
/// Deliberately **not** [ListRow] (`list_row.dart`) reused as-is: that
/// widget's leading slot is a fixed 36×36 icon chip (`IconData`), but every
/// CRM row here needs an actual photo/avatar image, sized larger (44×44,
/// matching `AgentAvatar`'s own default) — forcing a photo through an
/// `IconData`-shaped slot isn't possible, and widening [ListRow]'s
/// contract to accept `Widget? leadingIcon` as well would make its own
/// icon-chip styling (fixed background tint, fixed icon size) ambiguous for
/// every existing caller. Two rows sharing 80% of their layout but
/// disagreeing on "what kind of thing sits on the left" get two widgets,
/// not one with a leading-widget escape hatch — see [ListRow]'s own
/// `subtitle`/`trailingIcon` doc comments for the same reasoning applied to
/// its own two extra features.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// One row: [leading] (typically a small [ListingPhoto] or [AgentAvatar]),
/// [title] + optional [subtitle], and an arbitrary [trailing] widget
/// (typically a [StatusPill], an [IconButton], or a plain count [Text]).
class CrmListTile extends StatelessWidget {
  const CrmListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: onTap != null,
      label: subtitle == null ? title : '$title, $subtitle',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: SizedBox(width: 44, height: 44, child: leading),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    if (subtitle case final s?) ...[
                      const SizedBox(height: 2),
                      Text(
                        s,
                        overflow: TextOverflow.ellipsis,
                        style: type.bodySmall.copyWith(color: colors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing case final t?) ...[
                const SizedBox(width: AppSpacing.sm),
                t,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
