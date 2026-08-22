/// `publish-channels-sheet` (SCREENS.md §28) — opened from both
/// `create-listing`'s (via `edit-listing` only in practice, see
/// `form/publish_section.dart`'s doc comment) and `edit-listing`'s
/// per-channel publish buttons. Not a route — `showPublishChannelsSheet` is
/// the whole integration surface, matching `showFilterSheet`'s convention.
///
/// **Ruling 7.3, applied here.** There is no multi-channel publish
/// endpoint, so **Publish** fans out at most two calls — one
/// `publishInstagram` (with every checked Instagram account's id in
/// `igUserIds`) and one `publishTelegram` (with every checked Telegram
/// chat id in `chatIds`) — never one call per checkbox, since both
/// endpoints already accept a list of targets in a single request. YouTube
/// has no direct-publish call at all (only a report-back), so it does not
/// appear in this sheet's list at all, matching §28's own text (which lists
/// only "connected Instagram accounts / Telegram channels").
///
/// **The sheet ends with five inert rows** — OLX, then the four
/// display-only channels of ruling 7.13 (Threads, Facebook Marketplace, X,
/// LinkedIn) — drawn by [_UnavailableChannelRow] from the file-local
/// [_inertSheetChannels] list. Every one of them is visible-but-disabled
/// with its own reason line from
/// [channelUnavailableHint]: OLX because cross-posting runs from the desktop
/// extension (§5's fixed hint string), Threads because it would need a
/// Threads profile linked to an Instagram professional account, Facebook
/// Marketplace because no compliant automation path exists on any platform,
/// X because it would need a paid-tier X API app, LinkedIn because it would
/// need approved Marketing API credentials. None of them carries a checkbox,
/// so none can ever join the selection **Publish** fans out — which is the
/// point: this sheet's checked set feeds real network calls, and only
/// Instagram and Telegram have one.
///
/// **[_inertSheetChannels] is hand-written and sheet-local on purpose** —
/// it is deliberately *not* [Channel.publishSurfaceChannels] minus the
/// enabled two. That list contains YouTube, and YouTube's absence from this
/// sheet is a decision recorded in the paragraph above; deriving the rows
/// would silently re-add it the moment someone read the two lists as
/// interchangeable. Nor is it [Channel.allChannels], which is the server's
/// status-response contract and has no business shaping a picker.
///
/// **Telegram has no per-channel metadata** (ruling 7.10 — `AuthUser
/// .tgChatIds` is a bare list of ints, no title/avatar/member count per
/// chat), so each Telegram row is labelled by its raw chat id rather than a
/// channel name — the honest amount of information this build actually
/// has, not an invented title.
///
/// **Toast copy**: §28 quotes Instagram's own toasts verbatim
/// ("Instagram post published!" / "Instagram publish failed for
/// {usernames}"). No Telegram-specific copy is quoted anywhere in
/// SCREENS.md — this file extrapolates the identical pattern for Telegram
/// ("Telegram post published!" / "Telegram publish failed for {chat ids}")
/// rather than inventing unrelated wording, and documents that
/// extrapolation here rather than silently presenting it as spec'd text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../listing_editor_error_message.dart';
import '../state/listing_editor_providers.dart';
import '../state/listing_editor_repository_provider.dart';
import 'channel_tile.dart';
import 'form/publish_section.dart' show channelLabel, channelUnavailableHint;

/// The channels this sheet lists but can never publish to, top to bottom,
/// rendered by [_UnavailableChannelRow] after the Telegram section — see
/// this file's doc comment for why each is inert and why this list is
/// written out here rather than derived from
/// [Channel.publishSurfaceChannels].
const List<Channel> _inertSheetChannels = [
  Channel.olx,
  Channel.threads,
  Channel.facebookMarketplace,
  Channel.x,
  Channel.linkedin,
];

Future<void> showPublishChannelsSheet(BuildContext context, {required Ad ad}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Mounts above the floating tab bar — see tab_shell_scaffold.dart's doc
    // comment. Without this, both Cancel and Publish are unclickable.
    useRootNavigator: true,
    builder: (context) => PublishChannelsSheet(ad: ad),
  );
}

class PublishChannelsSheet extends ConsumerStatefulWidget {
  const PublishChannelsSheet({super.key, required this.ad});

  final Ad ad;

  @override
  ConsumerState<PublishChannelsSheet> createState() =>
      _PublishChannelsSheetState();
}

class _PublishChannelsSheetState extends ConsumerState<PublishChannelsSheet> {
  final Set<String> _selectedIgUserIds = {};
  final Set<int> _selectedChatIds = {};
  bool _publishing = false;

  String get _caption {
    final ad = widget.ad;
    return [
      ad.title,
      if (ad.description case final d? when d.trim().isNotEmpty) d,
      if (ad.hashtags case final h? when h.trim().isNotEmpty) h,
    ].join('\n\n');
  }

  Future<void> _publish({
    required List<ConnectedInstagramAccount> igAccounts,
  }) async {
    if (_publishing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _publishing = true);

    final repository = ref.read(listingEditorRepositoryProvider);
    var anyFailure = false;
    final failedIgUsernames = <String>[];

    if (_selectedIgUserIds.isNotEmpty) {
      try {
        final response = await repository.publishInstagram(
          adId: widget.ad.id,
          caption: _caption,
          imageUrls: widget.ad.photos,
          igUserIds: _selectedIgUserIds.toList(),
        );
        for (final result in response.results) {
          if (!result.ok) {
            anyFailure = true;
            final username = igAccounts
                .firstWhere(
                  (a) => a.igUserId == result.target,
                  orElse: () => ConnectedInstagramAccount(
                    igUserId: result.target,
                    username: result.target,
                    expiresAt: null,
                    profilePictureUrl: null,
                    mediaCount: null,
                    followersCount: null,
                    followsCount: null,
                  ),
                )
                .username;
            failedIgUsernames.add(username ?? result.target);
          }
        }
      } on ApiException catch (e) {
        anyFailure = true;
        failedIgUsernames.add(listingEditorErrorMessage(l10n, e));
      }
    }

    var telegramFailed = false;
    String? telegramError;
    if (_selectedChatIds.isNotEmpty) {
      try {
        final response = await repository.publishTelegram(
          adId: widget.ad.id,
          caption: _caption,
          imageUrls: widget.ad.photos,
          chatIds: _selectedChatIds.map((id) => id.toString()).toList(),
        );
        if (response.results.any((r) => !r.ok)) telegramFailed = true;
      } on ApiException catch (e) {
        telegramFailed = true;
        telegramError = listingEditorErrorMessage(l10n, e);
      }
    }

    ref.invalidate(publishStatusProvider(widget.ad.id));

    if (!mounted) return;
    setState(() => _publishing = false);

    if (_selectedIgUserIds.isNotEmpty) {
      if (anyFailure) {
        LaCasaToast.showError(
          context,
          l10n.listingEditorInstagramPublishFailedMessage(
            failedIgUsernames.join(', '),
          ),
        );
      } else {
        LaCasaToast.showSuccess(
          context,
          l10n.listingEditorInstagramPublishSuccessMessage,
        );
      }
    }
    if (_selectedChatIds.isNotEmpty) {
      if (telegramFailed) {
        LaCasaToast.showError(
          context,
          telegramError ??
              l10n.listingEditorTelegramPublishFailedMessage(
                _selectedChatIds.join(', '),
              ),
        );
      } else {
        LaCasaToast.showSuccess(
          context,
          l10n.listingEditorTelegramPublishSuccessMessage,
        );
      }
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final igAsync = ref.watch(instagramAccountsProvider);
    final tgChatIds =
        ref.watch(authSessionProvider).user?.tgChatIds ?? const <int>[];

    final canPublish =
        (_selectedIgUserIds.isNotEmpty || _selectedChatIds.isNotEmpty) &&
        !_publishing;

    // `.sh{left:8px;right:8px;bottom:8px;border-radius:34px;padding:10px
    // 18px 22px;max-height:86%}` — an inset, fully-rounded sheet sized to
    // its content, not a full-bleed panel pinned to a fixed height.
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            AppSpacing.md,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(34),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: AppRadii.pill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  AppSpacing.md,
                  18,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.listingEditorPublishChannelsSheetTitle,
                        style: type.sheetTitle.copyWith(color: colors.ink),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // `.sh__h .rnd{width:34px;height:34px;background:
                    // var(--sunk)}` — the ✕ sits in its own grey circle.
                    Semantics(
                      button: true,
                      label: l10n.sharedNavRowCloseLabel,
                      child: GestureDetector(
                        key: const ValueKey('publishChannelsSheet-close'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colors.sunk,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: colors.ink,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      AppSpacing.lg,
                      18,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        igAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.base,
                            ),
                            child: ShimmerBox(
                              height: 56,
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          error: (error, stackTrace) => _SectionError(
                            message:
                                l10n.listingEditorInstagramLoadErrorMessage,
                            onRetry: () =>
                                ref.invalidate(instagramAccountsProvider),
                          ),
                          data: (accounts) => _InstagramSection(
                            accounts: accounts,
                            selected: _selectedIgUserIds,
                            onToggle: (id) => setState(() {
                              if (!_selectedIgUserIds.remove(id)) {
                                _selectedIgUserIds.add(id);
                              }
                            }),
                          ),
                        ),
                        const SizedBox(height: kChannelRowGap),
                        _TelegramSection(
                          chatIds: tgChatIds,
                          selected: _selectedChatIds,
                          onToggle: (id) => setState(() {
                            if (!_selectedChatIds.remove(id)) {
                              _selectedChatIds.add(id);
                            }
                          }),
                        ),
                        for (final channel in _inertSheetChannels) ...[
                          const SizedBox(height: kChannelRowGap),
                          _UnavailableChannelRow(
                            key: ValueKey(
                              'publishChannelsSheet-${channel.name}',
                            ),
                            channel: channel,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.section),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, AppSpacing.lg, 18, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey('publishChannelsSheet-cancel'),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              AppRadii.pillButton,
                            ),
                            border: Border.all(
                              color: AppStatusColors.dangerBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            l10n.listingEditorCancelButtonLabel,
                            style: type.rowTitle.copyWith(
                              color: AppStatusColors.errorText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: GestureDetector(
                        key: const ValueKey('publishChannelsSheet-publish'),
                        onTap: canPublish
                            ? () => _publish(
                                igAccounts: igAsync.value ?? const [],
                              )
                            : null,
                        child: Opacity(
                          opacity: canPublish ? 1 : 0.5,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppAccent.gradient,
                              borderRadius: BorderRadius.circular(
                                AppRadii.pillButton,
                              ),
                            ),
                            child: _publishing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    l10n.listingEditorPublishButtonLabel,
                                    style: type.rowTitle.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.stack{gap:11px}` — the vertical gap between two `.lrow` channel rows.
const double kChannelRowGap = 11;

class _InstagramSection extends StatelessWidget {
  const _InstagramSection({
    required this.accounts,
    required this.selected,
    required this.onToggle,
  });

  final List<ConnectedInstagramAccount> accounts;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    if (accounts.isEmpty) {
      return Text(
        l10n.listingEditorNoInstagramAccountMessage,
        style: type.bodySmall.copyWith(color: colors.faint),
      );
    }

    // No section heading: the mockup's sheet is one flat `.stack` of rows,
    // each carrying its own channel name as the row's subtitle
    // ("Instagram · 4,210 followers"). `followersCount` is independently
    // optional on the wire (ruling 7.9 — the Graph API call filling it in
    // can fail while the token stays valid), so an account without one
    // falls back to the bare channel name rather than a fabricated "0".
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final account in accounts) ...[
          if (account != accounts.first) const SizedBox(height: kChannelRowGap),
          _CheckRow(
            key: ValueKey('publishChannelsSheet-ig-${account.igUserId}'),
            channel: Channel.instagram,
            label: account.username ?? account.igUserId,
            subtitle: switch (account.followersCount) {
              final n? => l10n.listingEditorInstagramFollowersSubtitle(
                Formatters.groupedNumber(n),
              ),
              null => channelLabel(l10n, Channel.instagram),
            },
            checked: selected.contains(account.igUserId),
            onTap: () => onToggle(account.igUserId),
          ),
        ],
      ],
    );
  }
}

class _TelegramSection extends StatelessWidget {
  const _TelegramSection({
    required this.chatIds,
    required this.selected,
    required this.onToggle,
  });

  final List<int> chatIds;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    if (chatIds.isEmpty) {
      return Text(
        l10n.listingEditorNoTelegramChannelMessage,
        style: type.bodySmall.copyWith(color: colors.faint),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final chatId in chatIds) ...[
          if (chatId != chatIds.first) const SizedBox(height: kChannelRowGap),
          _CheckRow(
            key: ValueKey('publishChannelsSheet-tg-$chatId'),
            channel: Channel.telegram,
            // No per-channel title exists on this build's wire data
            // (ruling 7.10) — the raw chat id is the honest label, and
            // the mockup's "· 1,864 members" has no wire source at all,
            // so no follower/member count is invented here.
            label: l10n.listingEditorTelegramChannelRowLabel(chatId),
            subtitle: channelLabel(l10n, Channel.telegram),
            checked: selected.contains(chatId),
            onTap: () => onToggle(chatId),
          ),
        ],
      ],
    );
  }
}

/// One of the sheet's trailing inert rows — was `_OlxRow`, generalized to
/// take its [channel] once the four display-only channels of ruling 7.13
/// needed exactly the same treatment. The rendering is unchanged from the
/// OLX-only version (same [GlassSurface], same 0.55 opacity, same
/// [ChannelIconTile], same two text styles, still no checkbox), so OLX's
/// shipped appearance and its widget tests are untouched; only the two
/// strings and the tile's brand now come from the channel.
///
/// Structurally distinct from [_CheckRow], not a disabled variant of it:
/// there is no `.chk` box to disable, no `onTap`, and no [Semantics]
/// `checked` state — a row that cannot be selected should not announce
/// itself as an unselected checkbox to a screen reader.
class _UnavailableChannelRow extends StatelessWidget {
  const _UnavailableChannelRow({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    // Non-null for every member of [_inertSheetChannels] — the `!` is
    // pinned by that list's contents, and `channelUnavailableHint` returns
    // null only for the two enabled channels and the decode fallback,
    // neither of which this sheet ever renders.
    final hint = channelUnavailableHint(l10n, channel)!;

    // `.lrow glf is-off` — same card shape as a channel row, dimmed, with
    // the neutral `.lrow__ic` tile and no checkbox at all.
    return Opacity(
      opacity: 0.55,
      child: GlassSurface(
        variant: GlassVariant.flatForm,
        borderRadius: BorderRadius.circular(AppRadii.card),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        child: Row(
          children: [
            ChannelIconTile(channel: channel),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channelLabel(l10n, channel),
                    style: type.rowTitle.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: type.specMeta.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One `.lrow glf` channel row: brand tile, account handle over the
/// channel name, and a `.chk` box on the right — accent-gradient with a
/// white check when on, a 1.5px inset hairline when off.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    super.key,
    required this.channel,
    required this.label,
    required this.subtitle,
    required this.checked,
    required this.onTap,
  });

  final Channel channel;
  final String label;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      checked: checked,
      label: '$label, $subtitle',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.card),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              ChannelIconTile(channel: channel),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: type.rowTitle.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: type.specMeta.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              _CheckBox(checked: checked),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.chk{width:24px;height:24px;border-radius:8px;box-shadow:inset 0 0 0
/// 1.5px var(--line)}` / `.chk.on{background:var(--accent-grad);color:#fff}`.
class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: checked ? AppAccent.gradient : null,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: checked ? null : Border.all(color: colors.line, width: 1.5),
        boxShadow: checked ? AppShadows.accentGlow : null,
      ),
      child: checked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppStatusColors.warningText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: type.bodySmall.copyWith(
                color: AppStatusColors.warningText,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              AppLocalizations.of(context).sharedRetryLabel,
              style: type.label.copyWith(color: AppAccent.color),
            ),
          ),
        ],
      ),
    );
  }
}
