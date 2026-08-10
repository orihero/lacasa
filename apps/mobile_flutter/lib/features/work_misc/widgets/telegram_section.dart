/// The Telegram half of `connected-accounts` (§21) — read-only
/// "Create Telegram post" toggle plus a single count-only row.
///
/// **Ruling 7.10, not the literal spec text.** §21 describes per-channel
/// cards (avatar, username, title, `Members {members_count}`) with "(no
/// disconnect action)" — but `AuthUser.tgChatIds.length` is the *only*
/// Telegram data that exists anywhere on the wire: no per-channel avatar,
/// title, or member count. This renders the one real number honestly
/// instead of fabricating per-channel cards the API cannot back — and it is
/// deliberately labelled "channels connected", not spec's "Members", since
/// `tgChatIds.length` counts connected chats, not one chat's audience size;
/// reusing "Members" for a different quantity would be its own small lie.
/// The count comes straight off the signed-in session
/// (`authSessionProvider`), not a repository fetch — see
/// `connected_accounts_repository.dart`'s doc comment for why there is no
/// seam to build here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/auth_session.dart';
import '../../../theme/theme.dart';
import 'channel_toggle_row.dart';

class TelegramSection extends ConsumerWidget {
  const TelegramSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final chatCount = ref.watch(
      authSessionProvider.select((s) => s.user?.tgChatIds.length ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelToggleRow(
          key: const ValueKey('connectedAccountsTelegramToggle'),
          title: 'Create Telegram post',
          on: chatCount > 0,
        ),
        const SizedBox(height: AppSpacing.base),
        GlassSurface(
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
                  color: colors.sunk,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(Icons.send_rounded, size: 17, color: colors.ink),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Text(
                  key: const ValueKey('connectedAccountsTelegramCount'),
                  chatCount > 0
                      ? '$chatCount channel${chatCount == 1 ? '' : 's'} connected'
                      : 'No Telegram channels connected',
                  style: type.rowTitle.copyWith(color: colors.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
