import { describe, expect, it } from 'vitest';
import regionData, { districts, regions } from './regions';

describe('regions data', () => {
  it('carries all 14 regions and 203 districts', () => {
    expect(regions).toHaveLength(14);
    expect(districts).toHaveLength(203);
  });

  // The pickers chain region -> district, so an orphaned district would render
  // as an unreachable option.
  it('has every district pointing at a region that exists', () => {
    const regionIds = new Set(regions.map((r) => r.id));
    const orphans = districts.filter((d) => !regionIds.has(d.region_id));

    expect(orphans).toEqual([]);
  });

  it('has no region without districts', () => {
    const withDistricts = new Set(districts.map((d) => d.region_id));

    expect(regions.filter((r) => !withDistricts.has(r.id))).toEqual([]);
  });

  it('exposes the same data through the default export the web forms destructure', () => {
    expect(regionData.regions).toBe(regions);
    expect(regionData.districts).toBe(districts);
  });
});
