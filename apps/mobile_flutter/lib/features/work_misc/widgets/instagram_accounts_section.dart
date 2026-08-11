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

class InstagramAccountsSection extends ConsumerWidget {
  const InstagramAccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(instagramAccountsProvider);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelToggleRow(
          key: const ValueKey('connectedAccountsInstagramToggle'),
          title: l10n.connectedAccountsInstagramToggleTitle,
          on: accountsAsync.value?.isNotEmpty ?? false,
        ),
        const SizedBox(height: AppSpacing.base),
        accountsAsync.when(
          loading: () => const Column(
            children: [
              ShimmerBox(
                height: 76,
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
              ),
            ],
          ),
          error: (error, stackTrace) => RailRetryCard(
            width: double.infinity,
            message: l10n.connectedAccountsInstagramLoadErrorMessage,
            onRetry: () => ref.invalidate(instagramAccountsProvider),
          ),
          data: (accounts) => accounts.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    for (final account in accounts) ...[
                      _InstagramAccountCard(
                        key: ValueKey(
                          'connectedAccountsInstagram-${account.igUserId}',
                        ),
                        account: account,
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],
                  ],
                ),
        ),
        _ConnectInstagramButton(
          key: const ValueKey('connectedAccountsConnectInstagram'),
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

class _InstagramAccountCardState
    extends ConsumerState<_InstagramAccountCard> {
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

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(
                avatarUrl: account.profilePictureUrl,
                fullName: account.username ?? l10n.connectedAccountsAvatarFallbackName,
                size: 44,
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(
                  account.username ?? account.igUserId,
                  overflow: TextOverflow.ellipsis,
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
          // Ruling 7.9: each of these three is independently optional on
          // the wire (the Graph API call filling them in can fail
          // independent of the token being valid) — render only what's
          // actually present, never a fabricated "0" for an absent field.
          if (account.mediaCount != null ||
              account.followersCount != null ||
              account.followsCount != null) ...[
            const SizedBox(height: AppSpacing.base),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                if (account.mediaCount case final n?)
                  _StatText(l10n.connectedAccountsPostsStatLabel(n)),
                if (account.followersCount case final n?)
                  _StatText(l10n.connectedAccountsFollowersStatLabel(n)),
                if (account.followsCount case final n?)
                  _StatText(l10n.connectedAccountsFollowingStatLabel(n)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: l10n.connectedAccountsDisconnectSemanticsLabel(
                account.username ?? l10n.connectedAccountsFallbackAccountName,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _disconnecting ? null : _disconnect,
                child: Opacity(
                  opacity: _disconnecting ? 0.6 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppStatusColors.dangerIconBg,
                      borderRadius: AppRadii.pill,
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
                            style: type.label.copyWith(
                              color: AppStatusColors.errorText,
                            ),
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

class _StatText extends StatelessWidget {
  const _StatText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    return Text(text, style: type.bodySmall.copyWith(color: colors.ink2));
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
      final opened = await ref
          .read(linkLauncherProvider)
          .open(Uri.parse(url));
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
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final label = AppLocalizations.of(context).connectedAccountsConnectButtonLabel;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _loading ? null : _connect,
        child: Opacity(
          opacity: _loading ? 0.6 : 1,
          child: Container(
            height: 48,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppAccent.gradient,
              borderRadius: BorderRadius.circular(AppRadii.pillButton),
              boxShadow: const [
                BoxShadow(
                  color: AppAccent.shadowColor,
                  blurRadius: 22,
                  spreadRadius: -8,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: type.rowTitle.copyWith(color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
