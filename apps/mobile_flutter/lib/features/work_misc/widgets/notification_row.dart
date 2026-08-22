/// One row of `notifications` (SCREENS.md §22) — an accent icon, a
/// headline over a muted detail line, the relative time pinned to the
/// right, and (when unread) a dot pinned to the row's left edge.
///
/// **The headline/detail split is derived, not stored.** The mockup's
/// `.nrow` is an `.lrow` with both a `.lrow__t` and a `.lrow__s`, but
/// neither the fixture rows (§4.4 writes each one as a single fused
/// "headline — detail" sentence) nor the live wire model
/// (`api/models/notification.dart` has a `title` and no `body`) carries
/// two fields. So the row splits the sentence at its first `:`/`—`
/// separator and renders the two halves in the source's two roles; a
/// title with no separator renders as the headline alone, with no empty
/// second line. That keeps the type hierarchy the mockup specifies
/// without inventing a wire field the server does not send.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import 'instagram_accounts_section.dart' show kInstagramGlyph;
import '../data/work_notification.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final WorkNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final (headline, detail) = _split(notification.title);

    return Semantics(
      button: true,
      label: notification.unread
          ? AppLocalizations.of(
              context,
            ).notificationsUnreadSemanticsLabel(notification.title)
          : notification.title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              // `.lrow{padding:13px 15px;gap:12px}`.
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: Row(
                // `.nrow{align-items:flex-start}`.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.sunk,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(
                      _iconFor(notification.kind),
                      size: 17,
                      // `.nrow .lrow__ic{color:var(--accent)}` — the icon is
                      // the row's only colour, and it is what separates a
                      // notification list from any other list of rows.
                      color: AppAccent.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // `.lrow__t{font-size:13px;font-weight:600}`.
                        Text(
                          headline,
                          style: type.rowTitle.copyWith(
                            fontSize: 13,
                            color: colors.ink,
                          ),
                        ),
                        if (detail != null) ...[
                          // `.lrow__s{margin-top:2px;font-size:10.5px;
                          // line-height:1.45;color:var(--muted)}`.
                          const SizedBox(height: 2),
                          Text(
                            detail,
                            style: type.bodySmall.copyWith(
                              height: 1.45,
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // `.nrow__t{font-size:9.5px;color:var(--faint);flex:none;
                  // padding-top:2px;white-space:nowrap}` — pinned to the
                  // row's right edge, not stacked under the text.
                  // `.lrow{gap:12px}` is a flex gap: the same gutter on
                  // both sides of the text column, not a narrower one here.
                  const SizedBox(width: AppSpacing.base),
                  // `.nrow__t{flex:none;white-space:nowrap}` — the stamp
                  // keeps its natural width and the [Expanded] text column
                  // absorbs the rest, so a long localized stamp ("2 kun
                  // oldin", "2 дн. назад") narrows the headline rather than
                  // overflowing the row.
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      notification.relativeTime,
                      softWrap: false,
                      style: type.micro.copyWith(color: colors.faint),
                    ),
                  ),
                ],
              ),
            ),
            if (notification.unread)
              // `.nrow.is-new::after{left:7px;top:16px;width:7px;height:7px}`
              // — the unread marker sits in the row's left margin, beside
              // the icon, where a scanning eye finds all of them in one
              // vertical line.
              const Positioned(
                left: 7,
                top: 16,
                child: SizedBox(
                  width: 7,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppAccent.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Splits a fused "headline — detail" sentence at its first separator.
  /// Returns `(title, null)` when there is none — an honest single line
  /// rather than a guess at where the sentence divides.
  static (String, String?) _split(String title) {
    for (final separator in [': ', ' — ', ' - ']) {
      final at = title.indexOf(separator);
      if (at > 0) {
        return (
          title.substring(0, at),
          title.substring(at + separator.length).trim(),
        );
      }
    }
    return (title, null);
  }

  static IconData _iconFor(WorkNotificationKind kind) => switch (kind) {
    // `user-circle-fill` — a person in a filled disc, not a person-plus.
    WorkNotificationKind.lead => Icons.account_circle_rounded,
    // `instagram-logo-fill` — the same Material stand-in the Connect
    // Instagram button uses, so there is one Instagram glyph app-wide.
    WorkNotificationKind.publish => kInstagramGlyph,
    WorkNotificationKind.sold => Icons.sell_rounded,
    WorkNotificationKind.coworkerActivity => Icons.groups_rounded,
  };
}
