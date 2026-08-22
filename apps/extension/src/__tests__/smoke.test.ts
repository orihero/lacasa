import { describe, expect, it } from 'vitest';

// Placeholder — proves the vitest + jsdom wiring works end to end for
// this workspace. Replace/extend with real content-script/background
// tests as they land.
describe('apps/extension test wiring', () => {
  it('runs under jsdom', () => {
    expect(typeof document).toBe('object');
  });
});
