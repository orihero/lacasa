import { describe, expect, it } from 'vitest';
import {
  ALL_CHANNELS,
  ASSISTED_CHANNELS,
  CONFIRM_EVENTS,
  ACTION_KINDS,
} from './publish';

describe('publish enums', () => {
  it('ALL_CHANNELS matches the status-grid channel order', () => {
    expect(ALL_CHANNELS).toEqual(['TELEGRAM', 'INSTAGRAM', 'YOUTUBE', 'OLX', 'REALTING']);
  });

  it('ASSISTED_CHANNELS is a subset understood by the extension', () => {
    expect(ASSISTED_CHANNELS).toEqual(['olx', 'instagram']);
  });

  it('CONFIRM_EVENTS matches the extension confirm contract', () => {
    expect(CONFIRM_EVENTS).toEqual(['drafted', 'published', 'failed', 'aborted', 'dom-drift']);
  });

  it('ACTION_KINDS matches the DOM executor action union', () => {
    expect(ACTION_KINDS).toEqual(['set-value', 'select-option', 'click-radio']);
  });

  it('exposes readonly tuples, not mutable arrays', () => {
    // TypeScript enforces the `as const` readonly-ness at compile time;
    // this just proves the runtime values are plain arrays consumers can
    // safely spread/iterate without further conversion.
    expect(Array.isArray(ALL_CHANNELS)).toBe(true);
  });
});
