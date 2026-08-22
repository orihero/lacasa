/**
 * channelCapability — static, verified product facts about *how* each
 * publish channel works (docs/06-cross-posting.md §2, docs/08-publish-
 * tracking.md §1/§4). These are NOT per-ad API data — the mechanism doesn't
 * change from one ad to the next — so hand-maintaining them here doesn't
 * violate the "trace every value to a real API response" rule the way a
 * fabricated per-ad number would: the thing being described is the
 * channel's own engineering, not a fact about a specific AdPublication row.
 *
 * PUBLISH_STATUS_CHANNELS is every channel @lacasa/domain's ALL_CHANNELS
 * carries.
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
