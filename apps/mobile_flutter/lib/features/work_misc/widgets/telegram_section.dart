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

import '../../../l10n/generated/app_localizations.dart';
import '../../../navigation/auth_session.dart';
import '../../../theme/theme.dart';
import 'channel_toggle_row.dart';

/// `.chan__ic.tg{background:linear-gradient(135deg,#41bce7,#1c93d2)}` —
/// Telegram's own brand gradient, deliberately not a theme token (see
/// `channel_toggle_row.dart`).
const LinearGradient kTelegramBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF41BCE7), Color(0xFF1C93D2)],
);

class TelegramSection extends ConsumerWidget {
  const TelegramSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final chatCount = ref.watch(
      authSessionProvider.select((s) => s.user?.tgChatIds.length ?? 0),
    );
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChannelToggleRow(
          key: const ValueKey('connectedAccountsTelegramToggle'),
          title: l10n.connectedAccountsTelegramToggleTitle,
          subtitle: l10n.connectedAccountsTelegramToggleSubtitle,
          icon: Icons.send_rounded,
          iconGradient: kTelegramBrandGradient,
          on: chatCount > 0,
        ),
        // `.chan__card{margin-top:12px;border-radius:18px;padding:11px 13px;
        // gap:11px}` on the `.glf` material — painted opaquely rather than
        // as a nested [GlassSurface], since this card sits inside the
        // `.chan` lens and lenses must not nest.
        const SizedBox(height: AppSpacing.base),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: colors.line),
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              // Ruling 7.10: `AuthUser.tgChatIds.length` is the only
              // Telegram data on the wire — no per-channel avatar, title or
              // member count — so the mockup's `.av--42` portrait stays an
              // honest icon tile at the same 42px rather than a fabricated
              // face.
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.sunk,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(Icons.send_rounded, size: 19, color: colors.ink),
              ),
              const SizedBox(width: 11),
              Expanded(
                // `.chan__st{font-size:10px;color:var(--muted)}` — the
                // count is the detail line; there is no primary channel
                // label on the wire to sit above it.
                child: Text(
                  key: const ValueKey('connectedAccountsTelegramCount'),
                  chatCount > 0
                      ? l10n.connectedAccountsTelegramChannelsConnected(
                          chatCount,
                        )
                      : l10n.connectedAccountsTelegramNoChannelsMessage,
                  style: type.bodySmall.copyWith(
                    fontSize: 10,
                    color: colors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
