/// The `.hdr` row: location pill (decorative), notification bell, search
/// icon. Build spec, "Header row".
///
/// ## Two things changed since the transcription
///
/// **The location pill lost its caret.** The mockup draws `.locpill .caret`,
/// but the pill carries no `data-go`/handler in the source markup and this
/// build has nowhere to send it: there is no city switcher anywhere in the
/// app, and `GET /regions` is reached only through `filter-sheet`. A
/// downward chevron is the one glyph in this design system that means
/// "tap me, a menu opens"; drawn on a widget with no `onTap` it is a
/// promise the screen cannot keep, so it is gone. The label stays — it is
/// honest as a *statement* of where the feed is scoped — and the caret
/// comes back the day the pill opens a picker, not before.
///
/// **The bell is agent/coworker-only.** `GET /notifications` answers 403
/// for every other role (`api/resources/notifications_resource.dart`), and
/// the feed behind it is entirely CRM events (lead assigned, ad approved).
/// Rendering the bell to a buyer or a signed-out visitor bought them a
/// shimmer, then "Couldn't load notifications", then a Retry that re-fires
/// the same forbidden request forever. The unread count already branched on
/// [AuthSessionState.canAccessWork] for exactly that reason; the control
/// itself now branches on the same flag, so there is one rule rather than
/// two halves of one. See this file's `left_undone` note in the build
/// report: the screen behind it and the router that reaches it want the
/// same guard, and both belong to other owners.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../../work_misc/state/notifications_providers.dart';

class HomeHeaderRow extends ConsumerWidget {
  const HomeHeaderRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    // The one flag that decides both whether the bell exists and whether
    // its fetch may be fired at all — see this file's doc comment.
    final canAccessWork = ref.watch(authSessionProvider).canAccessWork;

    // `.iconbtn .badge-dot` — driven by the real feed, not by the mockup's
    // demo `aria-label="Notifications, 5 unread"`, which is fixture state
    // and not a spec for a badge every user carries forever.
    // `GET /notifications` is agent/coworker only (403 for any other role
    // — see `api/resources/notifications_resource.dart`), so a buyer or a
    // signed-out visitor must not fire the fetch at all: no dot, and the
    // label announces zero. A loading or failed fetch shows no dot rather
    // than guessing, the same "never claim what the data didn't say" rule
    // `work_dashboard/widgets/dashboard_screen.dart`'s header follows.
    final unreadCount = canAccessWork
        ? ref
              .watch(notificationsProvider)
              .maybeWhen(
                data: (rows) => rows.where((row) => row.unread).length,
                orElse: () => 0,
              )
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.base,
        AppSpacing.screenGutter,
        0,
      ),
      child: Row(
        children: [
          // Decorative: no `data-go`/handler on `.locpill` in the source
          // markup (build spec, "Header row" — confirmed by direct
          // inspection). Deliberately no `onTap`, and therefore — as of
          // this pass — deliberately no caret either; see the "lost its
          // caret" half of this file's doc comment.
          // `.locpill{height:38px;padding:0 13px}` is sized to its content;
          // `.hdr__sp{flex:1}` takes up the slack between it and the bell.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GlassSurface(
                variant: GlassVariant.onSurface,
                borderRadius: AppRadii.pill,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // `.locpill .i{font-size:14px;color:var(--ink-2)}` — the
                    // pin stays a tier below the label it introduces. The
                    // mockup's third tier (`.locpill .caret{font-size:9px;
                    // color:var(--muted)}`) has no widget here any more.
                    Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: colors.ink2,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        l10n.homeLocationPillLabel,
                        overflow: TextOverflow.ellipsis,
                        style: type.rowTitle.copyWith(color: colors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // The bell exists only for the roles whose feed it can actually
          // load — see this file's doc comment. Both the button and the 8px
          // gap that precedes it go together, so a buyer's header closes up
          // around the search icon rather than leaving a hole where the
          // bell used to be.
          if (canAccessWork) ...[
            const SizedBox(width: 8),
            _IconButton(
              key: const ValueKey('homeNotificationsBell'),
              icon: Icons.notifications_rounded,
              semanticLabel: l10n.homeNotificationsBellSemanticLabel(
                unreadCount,
              ),
              showDot: unreadCount > 0,
              onTap: () => context.push(RoutePaths.homeNotifications),
            ),
          ],
          const SizedBox(width: 8),
          _IconButton(
            key: const ValueKey('homeSearchIcon'),
            icon: Icons.search_rounded,
            semanticLabel: l10n.homeSearchIconSemanticLabel,
            onTap: () => context.go(RoutePaths.search),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final String semanticLabel;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.onSurface,
          borderRadius: AppRadii.pill,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 19, color: colors.ink),
              // `.iconbtn .badge-dot{width:8px;height:8px;border-radius:50%;
              // background:var(--accent);box-shadow:0 0 0 2px var(--screen)}`
              // — the 2px ring is what separates the dot from the glyph it
              // overlaps, drawn here as a `screen`-filled circle behind it.
              if (showDot)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.screen,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppAccent.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
