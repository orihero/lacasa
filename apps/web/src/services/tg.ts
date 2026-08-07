// Telegram integration for apps/web.
//
// Publishing used to POST straight to
// https://api.telegram.org/bot${VITE_TG_BOT_TOKEN}/sendMediaGroup from the
// browser, which meant a live bot token was compiled into the public JS
// bundle (docs/05-migration-plan.md Phase E — a real credential leak, not
// just bad practice). The bot token must never reach the browser again.
// Publishing now goes through the server's stored token via
// POST /api/publish/telegram (apps/api/src/routes/publish.js), reached here
// through the app's authed @lacasa/api-client instance (../lib/apiClient) —
// the same client crosspost.ts already uses for server-side Instagram
// publishing.
//
// Account *enrichment* (title, username, avatar, member count) used to be
// fetched the same insecure way, via getChat / getChatMembersCount /
// getFile. There is no server-side equivalent for that today — no
// GET /publish/telegram/accounts route exists (see the API agent's own
// scope notes: "did not build a GET /publish/telegram/accounts endpoint").
// Rather than leave those calls half-working against a token that no
// longer exists here, they have been removed outright. init() now only
// wraps the caller's raw chat ids — which aren't secret in themselves, see
// apps/web/src/lib/userStore.js's enrichTelegramAccounts comment — into stub
// accounts with nothing but `id` set; every display field is intentionally
// left undefined rather than fabricated. This mirrors apps/console's
// ConnectedAccountsScreen, which shows tgChatIds's *count* only for the
// identical reason ("tgChatIds has no per-channel name field; never
// fabricate channel names" — mockups/f/PLAN.md §4). Consumers
// (TgProfileCard, AdsAdd, AdsEdit) render an honest "unavailable" state for
// the missing fields.
//
// LOST: per-channel title/username/avatar/member count. Call sites that
// relied on it: TgProfileCard.tsx (all four fields), AdsAdd.tsx's and
// AdsEdit.tsx's inline Telegram preview cards (file_path/title/username).
import type { TgPublishResult } from "@lacasa/api-client";
import { apiClient } from "../lib/apiClient";

export interface ITGAccount {
  id?: number;
  title?: string;
  username?: string;
  file_path?: string;
  members_count?: number;
}

export interface TgPublishArgs {
  adId: string;
  caption: string;
  imageUrls: string[];
  chatIds: Array<string | number>;
}

export class TGService {
  public static TgAccounts: ITGAccount[] = [];

  // Wraps the user's raw Telegram chat ids into placeholder accounts — no
  // network call. See file header for why the old getChat enrichment was
  // removed instead of kept half-working.
  public static init = async (chats: number[]): Promise<ITGAccount[]> => {
    this.TgAccounts = chats.map((id) => ({ id }));
    return this.TgAccounts;
  };

  // Publishes photos + caption to the given chats via the server's stored
  // bot token (POST /api/publish/telegram). Replaces the old raw
  // sendMediaGroup POST to api.telegram.org.
  public static publish = async (
    input: TgPublishArgs,
  ): Promise<{ results: TgPublishResult[] }> => {
    const { results } = await apiClient.publish.publishTelegram({
      adId: input.adId,
      caption: input.caption,
      imageUrls: input.imageUrls,
      chatIds: input.chatIds.map(String),
    });
    return { results };
  };
}
