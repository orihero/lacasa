/// The Instagram half of `connected-accounts` (§21) — the read-only
/// "Create Instagram post" toggle, one card per connected account (with a
/// per-card **Disconnect** button), and the **Connect Instagram** button.
///
/// **No in-app WebView, ever** (SCREENS.md §21, contract §5.3: "opens the
/// OS system browser / Custom Tabs / SFSafariViewController — never an
/// in-app WebView, per Meta OAuth restrictions"). Tapping Connect fetches
/// the OAuth URL and hands it to [LinkLauncher.open] with
/// [UrlLauncherLinkLauncher.open]'s `LaunchMode.externalApplication` — the
/// compliant choice: it leaves the app entirely for the device's default
/// browser, which is what satisfies Meta's policy, as opposed to
/// `webview_flutter` (in this app's `pubspec.yaml` for other screens'
/// non-OAuth needs) which would render Instagram's login inside our own
/// process and is exactly what the policy forbids.
///
/// This build still **cannot** detect the OAuth callback completing — the
/// browser is a separate app now, not a webview this screen owns — so
/// §21's exact "Instagram account connected!" success toast (written for a
/// build that gets an in-app callback) is not reachable here. The success
/// copy below stays honest about what actually just happened (the browser
/// was opened, not that a connection completed). If nothing on the device
/// can open the link, this falls back to copying it instead, saying so.
/// The failure toast — "Instagram connection failed — please try again." —
/// is spec copy verbatim, reused for "couldn't even fetch the sign-in
/// link," the closest real failure this flow has to the spec's
/// OAuth-return failure.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/platform/link_launcher.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/connected_accounts_providers.dart';
import '../state/connected_accounts_repository_provider.dart';
import 'channel_toggle_row.dart';

/// `.chan__ic.ig{background:linear-gradient(135deg,#f9ce34,#ee2a7b 52%,
/// #6228d7)}` — Instagram's own brand gradient, deliberately not a theme
/// token (see `channel_toggle_row.dart`).
const LinearGradient kInstagramBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
  stops: [0, 0.52, 1],
);

/// The Material stand-in for the mockup's `instagram-logo-fill` Phosphor
/// mark, used everywhere this build has to draw "Instagram" as a glyph
/// (here and `notification_row.dart`'s publish row) so there is one
/// Instagram icon across the app.
const IconData kInstagramGlyph = Icons.camera_alt_rounded;

class InstagramAccountsSection extends ConsumerWidget {
  const InstagramAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final accountsAsync = ref.watch(instagramAccountsProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelToggleRow(
          key: const ValueKey('connectedAccountsInstagramToggle'),
          title: l10n.connectedAccountsInstagramToggleTitle,
          subtitle: l10n.connectedAccountsInstagramToggleSubtitle,
          icon: kInstagramGlyph,
          iconGradient: kInstagramBrandGradient,
          on: accountsAsync.value?.isNotEmpty ?? false,
        ),
        // Each branch below owns its own `.chan__card{margin-top:12px}`, so
        // the empty case collapses to the Connect button's single 11px gap
        // instead of stacking two.
        accountsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.base),
            child: ShimmerBox(
              height: 64,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.control)),
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.base),
            child: RailRetryCard(
              width: double.infinity,
              message: l10n.connectedAccountsInstagramLoadErrorMessage,
              onRetry: () => ref.invalidate(instagramAccountsProvider),
            ),
          ),
          data: (accounts) => Column(
            children: [
              for (final account in accounts)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.base),
                  child: _InstagramAccountCard(
                    key: ValueKey(
                      'connectedAccountsInstagram-${account.igUserId}',
                    ),
                    account: account,
                  ),
                ),
            ],
          ),
        ),
        // `<button class="btn btn--ink" style="margin-top:11px">`.
        const Padding(
          padding: EdgeInsets.only(top: 11),
          child: _ConnectInstagramButton(
            key: ValueKey('connectedAccountsConnectInstagram'),
          ),
        ),
        // `.chan .hint{margin-top:9px}` — `.hint{padding-left:3px;
        // font-size:10.5px;line-height:1.5;color:var(--faint)}`.
        Padding(
          padding: const EdgeInsets.only(top: 9, left: 3),
          child: Text(
            l10n.connectedAccountsInstagramBrowserHint,
            style: type.bodySmall.copyWith(color: colors.faint, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _InstagramAccountCard extends ConsumerStatefulWidget {
  const _InstagramAccountCard({super.key, required this.account});

  final ConnectedInstagramAccount account;

  @override
  ConsumerState<_InstagramAccountCard> createState() =>
      _InstagramAccountCardState();
}

class _InstagramAccountCardState extends ConsumerState<_InstagramAccountCard> {
  bool _disconnecting = false;

  Future<void> _disconnect() async {
    setState(() => _disconnecting = true);
    final l10n = AppLocalizations.of(context);
    try {
      await LaCasaToast.run(
        context: context,
        action: () => ref
            .read(instagramAccountsProvider.notifier)
            .disconnect(widget.account.igUserId),
        pending: l10n.connectedAccountsDisconnectingToastLabel,
        success: l10n.connectedAccountsDisconnectedToastMessage,
      );
    } catch (_) {
      // LaCasaToast.run already showed the error toast; nothing else to do.
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final account = widget.account;
    final l10n = AppLocalizations.of(context);

    // Ruling 7.9: each of these three is independently optional on the wire
    // (the Graph API call filling them in can fail independent of the token
    // being valid) — render only what's actually present, never a
    // fabricated "0" for an absent field. `.chan__st` is one dot-joined
    // line, so the present ones are joined rather than chipped out
    // separately.
    final stats = <String>[
      if (account.mediaCount case final n?)
        l10n.connectedAccountsPostsStatLabel(n),
      if (account.followersCount case final n?)
        l10n.connectedAccountsFollowersStatLabel(n),
      if (account.followsCount case final n?)
        l10n.connectedAccountsFollowingStatLabel(n),
    ];

    // `.chan__card{border-radius:18px;padding:11px 13px;gap:11px}` on the
    // `.glf` material. Painted opaquely rather than as a nested
    // [GlassSurface]: this card sits inside the `.chan` lens, and lenses
    // must not nest (see `glass_surface.dart`).
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          // `.av--42`.
          AgentAvatar(
            avatarUrl: account.profilePictureUrl,
            fullName:
                account.username ?? l10n.connectedAccountsAvatarFallbackName,
            size: 42,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.username ?? account.igUserId,
                  overflow: TextOverflow.ellipsis,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
                if (stats.isNotEmpty) ...[
                  // `.chan__st{margin-top:3px;font-size:10px;
                  // color:var(--muted)}`.
                  const SizedBox(height: 3),
                  Text(
                    stats.join(' · '),
                    style: type.bodySmall.copyWith(
                      fontSize: 10,
                      color: colors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 11),
          Semantics(
            button: true,
            label: l10n.connectedAccountsDisconnectSemanticsLabel(
              account.username ?? l10n.connectedAccountsFallbackAccountName,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _disconnecting ? null : _disconnect,
              child: Opacity(
                opacity: _disconnecting ? 0.6 : 1,
                // `.btn--sm{height:44px;border-radius:22px;font-size:12.5px;
                // padding:0 18px}` + `.btn--danger{color:#e0355f;
                // box-shadow:inset 0 0 0 1px rgba(224,53,95,.4)}` — a ring
                // and a colour, no fill.
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppStatusColors.dangerBorder),
                  ),
                  child: _disconnecting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppStatusColors.errorText,
                            ),
                          ),
                        )
                      : Text(
                          l10n.connectedAccountsDisconnectButtonLabel,
                          style: type.rowTitle.copyWith(
                            fontSize: 12.5,
                            color: AppStatusColors.errorText,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectInstagramButton extends ConsumerStatefulWidget {
  const _ConnectInstagramButton({super.key});

  @override
  ConsumerState<_ConnectInstagramButton> createState() =>
      _ConnectInstagramButtonState();
}

class _ConnectInstagramButtonState
    extends ConsumerState<_ConnectInstagramButton> {
  bool _loading = false;

  Future<void> _connect() async {
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      final url = await ref
          .read(connectedAccountsRepositoryProvider)
          .instagramConnectUrl();
      final opened = await ref.read(linkLauncherProvider).open(Uri.parse(url));
      if (!mounted) return;
      if (opened) {
        LaCasaToast.showSuccess(
          context,
          l10n.connectedAccountsOpeningBrowserToastMessage,
        );
      } else {
        // No browser on this device, or the OS declined the launch — fall
        // back to the previous copy-and-toast behaviour rather than a tap
        // that looks like it did nothing.
        await Clipboard.setData(ClipboardData(text: url));
        if (!mounted) return;
        LaCasaToast.showSuccess(
          context,
          l10n.connectedAccountsLinkCopiedToastMessage,
        );
      }
    } catch (_) {
      if (!mounted) return;
      LaCasaToast.showError(
        context,
        l10n.connectedAccountsConnectionFailedToastMessage,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final label = AppLocalizations.of(
      context,
    ).connectedAccountsConnectButtonLabel;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _loading ? null : _connect,
        child: Opacity(
          opacity: _loading ? 0.6 : 1,
          // `.btn{height:54px;border-radius:27px;gap:8px;font-size:13.5px;
          // font-weight:600;letter-spacing:.1px}` +
          // `.btn--ink{background:var(--pill);color:var(--pill-ink)}`.
          child: Container(
            height: 54,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.pill,
              borderRadius: BorderRadius.circular(AppRadii.pillButton),
              boxShadow: AppShadows.selectedPillLarge,
            ),
            child: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(colors.pillInk),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // `.btn .i{font-size:17px}`.
                      Icon(kInstagramGlyph, size: 17, color: colors.pillInk),
                      const SizedBox(width: AppSpacing.md),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.cardTitle.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: colors.pillInk,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
