/**
 * src/screens/myAds/deriveMyAds — every non-trivial piece of display logic
 * the My ads screen needs, pulled out of MyAdsScreen.tsx as plain functions
 * so they're directly testable without mounting a component (this
 * workspace's react-dom hoisting conflict — see __tests__/testUtils.tsx —
 * makes rendering expensive to set up, so logic that doesn't need a DOM
 * shouldn't be forced through one).
 *
 * `Ad`'s own type only names a handful of fields explicitly and falls back
 * to an index signature (`[key: string]: unknown`) for the rest — title,
 * district, rooms, area, stage all arrive typed `unknown` at this call site
 * even though the wire always sends them. `str`/`num`/`stageKey` narrow them
 * defensively rather than casting, so a genuinely missing/malformed field
 * degrades to "omit it" instead of a runtime crash or a fabricated value.
 */
import type { Ad, AuthUser, Coworker } from '@lacasa/api-client';
import { ALL_CHANNELS, type AdStageKey, type Channel } from '@lacasa/domain';
import {
  AD_STAGE_LABEL,
  PUBLISH_STATUS_KEYS,
  PUBLISH_STATUS_LABEL,
  PUBLISH_STATUS_TONE,
  type PublishStatusKey,
} from '@/lib/labels';
import type { Tone } from '@/ui/Tag';

function str(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0 ? value : undefined;
}

function num(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

/** `Ad.stage` is the "1"|"2"|"3" wire key (see the build brief's CRITICAL
 * WIRE-FORMAT FACT) — never "ACTIVE"/"SOLD"/"DRAFT". Anything else (a stage
 * the client doesn't know about yet, or a malformed value) narrows to
 * `undefined` rather than being assumed. */
export function stageKey(value: unknown): AdStageKey | undefined {
  return value === '1' || value === '2' || value === '3' ? value : undefined;
}

/** Real title, per-ad — falls back to a plain "missing field" label, never a
 * placeholder that could be mistaken for a real listing name. */
export function titleOf(ad: Ad): string {
  return str(ad.title) ?? 'Untitled listing';
}

/**
 * Folds district/rooms/area into the one subtitle line the toolbar-simplified
 * column set (see MyAdsScreen's file header) asks for, in place of the
 * prototype's separate Ref/Rooms/Area columns. Omits whichever parts aren't
 * present rather than rendering "undefined" or a placeholder dash per part.
 */
export function buildListingSubtitle(ad: Ad): string | undefined {
  const parts: string[] = [];
  const district = str(ad.district);
  if (district) parts.push(district);
  const rooms = num(ad.rooms);
  if (rooms !== undefined) parts.push(`${rooms} ${rooms === 1 ? 'room' : 'rooms'}`);
  const area = num(ad.area);
  if (area !== undefined) parts.push(`${area} m²`);
  return parts.length > 0 ? parts.join(' · ') : undefined;
}

export interface StageCounts {
  all: number;
  '1': number;
  '2': number;
  '3': number;
}

/** Counts are derived from the already-fetched ads list (not a second call
 * to GET /my/ads/stage-counts) so the segmented control's numbers can never
 * drift from the rows actually on screen. */
export function deriveStageCounts(ads: readonly Ad[]): StageCounts {
  const counts: StageCounts = { all: ads.length, '1': 0, '2': 0, '3': 0 };
  for (const ad of ads) {
    const stage = stageKey(ad.stage);
    if (stage) counts[stage] += 1;
  }
  return counts;
}

export type StageFilter = 'all' | AdStageKey;

export function filterAdsByStage(ads: readonly Ad[], filter: StageFilter): Ad[] {
  if (filter === 'all') return [...ads];
  return ads.filter((ad) => stageKey(ad.stage) === filter);
}

export interface SegOption {
  value: StageFilter;
  label: string;
}

export function buildSegOptions(counts: StageCounts): SegOption[] {
  return [
    { value: 'all', label: `All ${counts.all}` },
    { value: '1', label: `${AD_STAGE_LABEL['1']} ${counts['1']}` },
    { value: '2', label: `${AD_STAGE_LABEL['2']} ${counts['2']}` },
    { value: '3', label: `${AD_STAGE_LABEL['3']} ${counts['3']}` },
  ];
}

export interface AuthorInfo {
  name: string;
  avatar: string | null;
}

/**
 * `Ad.coworkerId` (explicitly typed on the Ad interface, unlike most fields)
 * names which coworker made the listing; ads with none are the agent's own.
 * Returns `null` — never a guess — when a coworkerId is set but that
 * coworker hasn't loaded yet (or no longer exists in the roster): showing
 * the wrong person's photo next to a listing is worse than showing nothing.
 */
export function resolveAdAuthor(
  ad: Ad,
  coworkers: readonly Coworker[],
  currentUser: AuthUser | null,
): AuthorInfo | null {
  const coworkerId = ad.coworkerId;
  if (coworkerId) {
    const match = coworkers.find((coworker) => coworker.id === coworkerId);
    return match ? { name: match.fullName, avatar: match.avatar } : null;
  }
  return currentUser ? { name: currentUser.fullName, avatar: currentUser.avatar ?? null } : null;
}

// Table-cell abbreviations for the Channels column — not part of
// @/lib/labels' PUBLISH_CHANNEL_LABEL (full names: "Instagram", "Telegram",
// …), which is too wide for a compact multi-tag cell. Screen-local because
// only this table needs the short form; report for promotion if Publish
// status ever wants the same compact style.
const CHANNEL_ABBREV: Record<Channel, string> = {
  TELEGRAM: 'TG',
  INSTAGRAM: 'IG',
  YOUTUBE: 'YT',
  OLX: 'OLX',
};

function isChannel(value: string): value is Channel {
  return (ALL_CHANNELS as readonly string[]).includes(value);
}

function isPublishStatusKey(value: string): value is PublishStatusKey {
  return (PUBLISH_STATUS_KEYS as readonly string[]).includes(value);
}

export interface ChannelBadge {
  key: string;
  tone: Tone;
  label: string;
}

/**
 * `getStatusForAds` only returns rows that actually exist in
 * `AdPublication` (apps/api's getStatusBulk, unlike the single-ad
 * getAdStatus, does not synthesize a PENDING placeholder for every channel
 * the ad has never touched) — so an empty array here is real "nothing
 * published yet", not a loading placeholder. An unrecognized channel/status
 * string (future enum member this build doesn't know about yet) still
 * renders, verbatim, in a neutral tone rather than being silently dropped.
 */
export function deriveChannelBadges(entries: ReadonlyArray<{ channel: string; status: string }>): ChannelBadge[] {
  return entries.map((entry, index) => {
    const abbrev = isChannel(entry.channel) ? CHANNEL_ABBREV[entry.channel] : entry.channel;
    const key = `${entry.channel}-${index}`;
    if (isPublishStatusKey(entry.status)) {
      const tone = PUBLISH_STATUS_TONE[entry.status];
      const label =
        entry.status === 'PUBLISHED' ? abbrev : `${abbrev} ${PUBLISH_STATUS_LABEL[entry.status].toLowerCase()}`;
      return { key, tone, label };
    }
    return { key, tone: 'mute', label: `${abbrev} ${entry.status.toLowerCase()}` };
  });
}
