import rawData from './regions.json';

/**
 * Uzbekistan's regions and their districts — 14 and 203 of them, hand-authored
 * and static. This is the vocabulary behind every city/district picker.
 *
 * It lives here rather than under apps/web because apps/mobile needs the same
 * list, and it is served as a build-time import rather than an API route:
 * nothing about it changes at runtime, so a round trip would buy nothing
 * (docs/10 §5 Decision 2/3).
 *
 * Consumers reach it at `@lacasa/domain/data/regions`, not from the root
 * barrel — no reason to put ~19KB of static data in front of every consumer of
 * the package's enums and schemas.
 *
 * Note `Ad.city`/`Ad.district` are still free text server-side; validating
 * writes against this vocabulary is a separate, deliberately deferred change.
 */

export interface Region {
  id: number;
  name: string;
}

export interface District {
  id: number;
  region_id: number;
  name: string;
}

export interface RegionsData {
  regions: Region[];
  districts: District[];
}

export const regions: Region[] = rawData.regions;
export const districts: District[] = rawData.districts;

// Default export kept as the whole `{ regions, districts }` object because
// that is the shape the existing web consumers already destructure.
export default rawData as RegionsData;
