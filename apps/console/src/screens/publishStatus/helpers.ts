/**
 * helpers — pure functions PublishStatusScreen.tsx renders with, split into
 * their own module (not just co-located with the components) so
 * react-refresh/only-export-components stays happy and so this folder's
 * test suite can import them directly without pulling in the screen's
 * react-router-dom-flavoured exports.
 */
import type { Ad } from "@lacasa/api-client";
import type { Tone } from "@/ui/Tag";
import { PUBLISH_STATUS_KEYS, PUBLISH_STATUS_LABEL, PUBLISH_STATUS_TONE } from "@/lib/labels";

export const RETRY_GAP_MESSAGE =
  "No retry endpoint exists yet — apps/api/src/routes/publish.js has no way to re-run a failed publish from this screen. Re-publish the channel from the Listing editor instead.";

export function adTitle(ad: Ad): string {
  return typeof ad.title === "string" && ad.title.trim().length > 0 ? ad.title : "Untitled listing";
}

export function adReference(ad: Ad): string | null {
  return typeof ad.reference === "string" && ad.reference.length > 0 ? ad.reference : null;
}

/** Maps a wire status to its Tag copy/tone, surfacing an unrecognized value
 * verbatim (mute) rather than silently relabelling it "Not published" —
 * ErrorState's "show the real thing" philosophy applies here too. */
export function publishStatusView(status: string): { label: string; tone: Tone } {
  const key = PUBLISH_STATUS_KEYS.find((candidate) => candidate === status);
  if (key) return { label: PUBLISH_STATUS_LABEL[key], tone: PUBLISH_STATUS_TONE[key] };
  return { label: status, tone: "mute" };
}
