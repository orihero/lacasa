/// The header row every Work-tab screen opens with: a back/close icon, a
/// title, and (occasionally) a couple of trailing action icons.
///
/// Two layouts share this widget:
///  - "back" layout (the common case: settings-style screens, list screens,
///    detail screens): back arrow on the left, title, optional [trailing]
///    icons on the right. Padding is `base` on the left / `screenGutter` on
///    the right regardless of how many trailing icons show up — that's the
///    convention every screen that used this shape already followed.
///  - "close" layout (Create Listing's first step only, which is a modal
///    flow rather than a back-stack push): title on the left, a close (X)
///    on the right. Padding mirrors the back layout — `screenGutter` on the
///    side with just text, `base` on the side with the icon.
/// Exactly one of [onBack] / [onClose] must be supplied.
///
/// Promoted out of thirteen near-identical private `_NavRow`s (one per
/// Work-tab screen file) that six agents independently wrote in parallel.
/// Eleven were byte-for-byte identical apart from the title string; the two
/// Leads screens additionally carry a view-toggle and an add-lead icon,
/// which is what [trailing] exists for.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
    this.backKey,
    this.closeKey,
    this.trailing = const [],
  }) : assert(
         (onBack == null) != (onClose == null),
         'NavRow needs exactly one of onBack or onClose',
       );

  final String title;

  /// Shows a leading back arrow when set. Mutually exclusive with [onClose].
  final VoidCallback? onBack;

  /// Shows a trailing close (X) when set. Mutually exclusive with [onBack].
  final VoidCallback? onClose;

  /// Optional key on the back arrow's tap target, for widget tests that
  /// need to find it.
  final Key? backKey;

  /// Optional key on the close icon's tap target, for widget tests that
  /// need to find it.
  final Key? closeKey;

  /// Extra widgets rendered after the title, before the close icon (if
  /// any). Used by the Leads screens for their view-toggle + add-lead
  /// buttons; callers own the icon/label/key for each action themselves,
  /// since those are screen-specific and not part of the row's shape.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final backIcon = onBack == null
        ? null
        : Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              key: backKey,
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded, size: 22, color: colors.ink),
              ),
            ),
          );

    final closeIcon = onClose == null
        ? null
        : Semantics(
            button: true,
            label: 'Close',
            child: GestureDetector(
              key: closeKey,
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close_rounded, size: 22, color: colors.ink),
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        onBack != null ? AppSpacing.base : AppSpacing.screenGutter,
        AppSpacing.md,
        onBack != null ? AppSpacing.screenGutter : AppSpacing.base,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          if (backIcon != null) ...[backIcon, const SizedBox(width: AppSpacing.xs)],
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: type.navTitle.copyWith(color: colors.ink),
            ),
          ),
          ...trailing,
          ?closeIcon,
        ],
      ),
    );
  }
}
