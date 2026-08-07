/// `.lrow` — the icon-chip/title/subtitle/trailing list row every Profile
/// (§3.14/§3.15/§3.16) and Settings (§3.19) row is built from, plus
/// `.grouplab`, the bare uppercase label above a group of rows
/// ("Preferences" / "Account" / "Session").
///
/// **Consolidated from two near-identical implementations.** `features/
/// profile/` originally built this as its own `ProfileRow`/`ProfileGroupLabel`
/// (`GlassSurface`-backed, matching `mockup-e-liquid-glass.html`'s `.lrow gl`
/// class); `features/settings/` independently built the same icon-chip-
/// title-chevron shape as a private `_SettingsRow` (a solid `colors.card`
/// container instead of glass, plus a `trailing` slot for its Notifications
/// switch that [ProfileRow] didn't originally have). Promoted here once
/// three call sites (`profile-signed-out`, `profile-buyer`/`profile-agent`,
/// `settings`) needed the same shape, per this repo's own "two of the three
/// screens are mostly rows" guidance. [ListRow] keeps [ProfileRow]'s glass
/// material (the more consistent match to the mockup's own `.lrow gl` class
/// across every screen that uses it) and gains `_SettingsRow`'s two extra
/// features: an optional [trailing] widget override (for a switch or a
/// spinner) and a nullable [onTap] (Settings' Notifications row has no
/// row-level tap target — only its switch is interactive).
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// `.lrow` — a list row: icon chip, title (+ optional subtitle), and a
/// trailing glyph/widget/nothing.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;

  /// Not spec copy (§3.14–§3.16/§3.19 name only the row title) — a short
  /// descriptive line taken from the mockup's own `.lrow__s`/subtitle text
  /// for the same row. Omit rather than invent one for a row the mockup
  /// doesn't caption.
  final String? subtitle;

  /// `null` renders no trailing glyph — the mockup's own `.lrow--danger`
  /// (the Logout row) never pairs with `.lrow__go`, so [danger] rows should
  /// pass `null` here rather than the default chevron. Ignored when
  /// [trailing] is set.
  final IconData? trailingIcon;

  /// Overrides [trailingIcon] entirely — e.g. Settings' Notifications
  /// switch, or a small spinner while Logout is in flight.
  final Widget? trailing;

  /// `.lrow--danger` — red icon chip and title, for the Logout row.
  final bool danger;

  /// `null` for a row with no row-level tap target (Settings' Notifications
  /// row: only its [trailing] switch is interactive).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final Color foreground = danger ? AppStatusColors.errorText : colors.ink;
    final Color chipBackground = danger
        ? AppStatusColors.dangerIconBg
        : colors.sunk;

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
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, size: 17, color: foreground),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: type.rowTitle.copyWith(color: foreground),
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
              ] else if (trailingIcon case final go?) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(go, size: 18, color: colors.faint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `.grouplab` — a bare uppercase label above a group of [ListRow]s
/// ("Preferences", "Account", "Session"). Not spec copy either, same
/// provenance note as [ListRow.subtitle].
class ListRowGroupLabel extends StatelessWidget {
  const ListRowGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.base),
      child: Text(
        text.toUpperCase(),
        style: type.label.copyWith(color: colors.muted),
      ),
    );
  }
}
