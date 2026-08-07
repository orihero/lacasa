/**
 * channelCapability — static, verified product facts about *how* each
 * publish channel works (docs/06-cross-posting.md §2, docs/08-publish-
 * tracking.md §1/§4). These are NOT per-ad API data — the mechanism doesn't
 * change from one ad to the next — so hand-maintaining them here doesn't
 * violate the "trace every value to a real API response" rule the way a
 * fabricated per-ad number would: the thing being described is the
 * channel's own engineering, not a fact about a specific AdPublication row.
 *
 * REALTING is deliberately excluded from PUBLISH_STATUS_CHANNELS even
 * though @lacasa/domain's ALL_CHANNELS (and therefore the real
 * GET /publish/ads/:adId/status response) includes it: docs/06 §2 calls it
 * "passive batch, not a 'click' at all" — a scheduled feed job with zero
 * per-ad user action — and docs/08 §6 confirms no route writes an
 * AdPublication row for it yet (Phase H, still backlog). The Listing
 * editor's own Publish panel (mockups/f/PLAN.md §3.3) never offers Realting
 * as a channel to select either. Rendering a 5th row an agent can never act
 * on, sitting next to four they can, would read as a broken button rather
 * than an honest "not built yet" — so it's scoped out here the same way the
 * editor scopes it out of its own channel checklist. (Reported to the
 * orchestrator as a deliberate scoping call, not an oversight.)
 */
import {
  InstagramLogoIcon,
  StorefrontIcon,
  TelegramLogoIcon,
  YoutubeLogoIcon,
  type IconComponent,
} from "@/ui/icons";

export const PUBLISH_STATUS_CHANNELS = ["TELEGRAM", "INSTAGRAM", "OLX", "YOUTUBE"] as const;
export type PublishStatusChannelKey = (typeof PUBLISH_STATUS_CHANNELS)[number];

export const CHANNEL_ICON: Record<PublishStatusChannelKey, IconComponent> = {
  TELEGRAM: TelegramLogoIcon,
  INSTAGRAM: InstagramLogoIcon,
  OLX: StorefrontIcon,
  YOUTUBE: YoutubeLogoIcon,
};

export interface ChannelCapability {
  /** Short Automation-column badge — mirrors f-console.src.html's own tag--mute copy verbatim. */
  tag: string;
  /** One-line "how it publishes" fact for CellMain's subtitle, verified against docs/06 §2. */
  description: string;
}

export const CHANNEL_CAPABILITY: Record<PublishStatusChannelKey, ChannelCapability> = {
  TELEGRAM: {
    tag: "Bot API",
    description: "Server bot token · sendMediaGroup",
  },
  INSTAGRAM: {
    tag: "Full API",
    description: "Server-held Graph API token · carousel publish",
  },
  OLX: {
    tag: "Form fill",
    description: "Extension fills the form; you click Publish",
  },
  YOUTUBE: {
    tag: "Browser OAuth",
    description: "Your browser uploads via your own Google session",
  },
};
