/// The header row every Work-tab screen opens with: a back/close icon, a
/// title, and (occasionally) a couple of trailing action icons.
///
/// Two layouts share this widget:
///  - "back" layout (the common case: settings-style screens, list screens,
///    detail screens): back arrow on the left, title, optional [trailing]
///    icons on the right. Padding is `base` on the left / `screenGutter` on
///    the right regardless of how many trailing icons show up — that's the
///    convention every screen that used this shape already followed.
///  - "close" layout (Create Listing's wizard header only, which is a modal
///    flow rather than a back-stack push): a close (X) in the *same leading
///    slot* the back arrow occupies, then the title. The source puts it
///    there too — `.nav--wizard .nav__row` is
///    `<button class="rnd glf">` followed by `<h1 class="nav__t">`, not a
///    trailing X — so both layouts share one geometry and one padding rule.
/// Exactly one of [onBack] / [onClose] must be supplied.
///
/// Both controls render as the source's `.nav .rnd` — a 38px round glass
/// button with an 18px ink glyph — inside an unshrunk 44px tap target, so
/// matching the mockup's visual size costs nothing in touch accuracy.
///
/// Promoted out of thirteen near-identical private `_NavRow`s (one per
/// Work-tab screen file) that six agents independently wrote in parallel.
/// Eleven were byte-for-byte identical apart from the title string; the two
/// Leads screens additionally carry a view-toggle and an add-lead icon,
/// which is what [trailing] exists for.
library;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
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

    // `.nav .rnd{width:38px;height:38px;font-size:18px;color:var(--ink)}`
    // — a glass circle, not a bare glyph. The 44px `GestureDetector` around
    // it (opaque, so the whole box takes the tap) keeps the touch target at
    // the platform minimum even though the visible disc is smaller.
    Widget control({
      required Key? tapKey,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          key: tapKey,
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: GlassSurface(
                variant: GlassVariant.onSurface,
                borderRadius: AppRadii.pill,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                // The lens's default band is tuned for a card and would
                // swallow a 38px disc — same override the two screens that
                // hand-built this control ahead of it already use.
                distortionWidth: 8,
                child: Icon(icon, size: 18, color: colors.ink),
              ),
            ),
          ),
        ),
      );
    }

    final leading = onBack != null
        ? control(
            tapKey: backKey,
            icon: Icons.arrow_back_rounded,
            label: AppLocalizations.of(context).sharedNavRowBackLabel,
            onTap: onBack!,
          )
        : control(
            tapKey: closeKey,
            icon: Icons.close_rounded,
            label: AppLocalizations.of(context).sharedNavRowCloseLabel,
            onTap: onClose!,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: type.navTitle.copyWith(color: colors.ink),
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}
