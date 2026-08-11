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
/// only "connected Instagram accounts / Telegram channels"). OLX is
/// always visible-but-disabled with §5's fixed hint string.
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
import '../state/listing_editor_providers.dart';
import '../state/listing_editor_repository_provider.dart';
import 'form/publish_section.dart' show channelLabel, olxUnavailableHint;

Future<void> showPublishChannelsSheet(BuildContext context, {required Ad ad}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
        failedIgUsernames.add(_messageFor(l10n, e));
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
        telegramError = _messageFor(l10n, e);
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

  static String _messageFor(AppLocalizations l10n, ApiException e) {
    if (e is ApiErrorException) return e.message;
    if (e is NetworkException) {
      return l10n.listingEditorNetworkErrorMessage;
    }
    return l10n.listingEditorGenericErrorMessage;
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadii.sheet),
              topRight: Radius.circular(AppRadii.sheet),
            ),
          ),
          child: Column(
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
                  AppSpacing.screenGutter,
                  AppSpacing.lg,
                  AppSpacing.base,
                  AppSpacing.base,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.listingEditorPublishChannelsSheetTitle,
                        style: type.sheetTitle.copyWith(color: colors.ink),
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('publishChannelsSheet-close'),
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.ink2,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
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
                        const SizedBox(height: AppSpacing.section),
                        _TelegramSection(
                          chatIds: tgChatIds,
                          selected: _selectedChatIds,
                          onToggle: (id) => setState(() {
                            if (!_selectedChatIds.remove(id)) {
                              _selectedChatIds.add(id);
                            }
                          }),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        const _OlxRow(),
                        const SizedBox(height: AppSpacing.section),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  AppSpacing.base,
                  AppSpacing.screenGutter,
                  AppSpacing.lg,
                ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channelLabel(l10n, Channel.instagram),
          style: type.panelHeading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (accounts.isEmpty)
          Text(
            l10n.listingEditorNoInstagramAccountMessage,
            style: type.bodySmall.copyWith(color: colors.faint),
          )
        else
          for (final account in accounts)
            _CheckRow(
              key: ValueKey('publishChannelsSheet-ig-${account.igUserId}'),
              label: account.username ?? account.igUserId,
              checked: selected.contains(account.igUserId),
              onTap: () => onToggle(account.igUserId),
            ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channelLabel(l10n, Channel.telegram),
          style: type.panelHeading.copyWith(color: colors.ink),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (chatIds.isEmpty)
          Text(
            l10n.listingEditorNoTelegramChannelMessage,
            style: type.bodySmall.copyWith(color: colors.faint),
          )
        else
          for (final chatId in chatIds)
            _CheckRow(
              key: ValueKey('publishChannelsSheet-tg-$chatId'),
              // No per-channel title exists on this build's wire data
              // (ruling 7.10) — the raw chat id is the honest label.
              label: l10n.listingEditorTelegramChannelRowLabel(chatId),
              checked: selected.contains(chatId),
              onTap: () => onToggle(chatId),
            ),
      ],
    );
  }
}

class _OlxRow extends StatelessWidget {
  const _OlxRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Opacity(
      opacity: 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_box_outline_blank_rounded,
                size: 20,
                color: colors.faint,
              ),
              const SizedBox(width: AppSpacing.base),
              Text(
                channelLabel(l10n, Channel.olx),
                style: type.rowTitle.copyWith(color: colors.ink2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            olxUnavailableHint(l10n),
            style: type.caption.copyWith(color: colors.faint),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              checked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: checked ? AppAccent.color : colors.muted,
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(
                label,
                style: type.rowTitle.copyWith(color: colors.ink),
              ),
            ),
          ],
        ),
      ),
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
