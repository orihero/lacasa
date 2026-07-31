import { describe, expect, it } from 'vitest';
import { invert } from './invert';

describe('invert', () => {
  it('builds the value -> key reverse of a string-valued map', () => {
    const forward = { residential: 'RESIDENTIAL', nonresidential: 'NONRESIDENTIAL' } as const;
    expect(invert(forward)).toEqual({
      RESIDENTIAL: 'residential',
      NONRESIDENTIAL: 'nonresidential',
    });
  });

  it('builds the value -> key reverse of a number-valued map', () => {
    const forward = { AD_CREATED: 1, AD_SOLD: 2 } as const;
    expect(invert(forward)).toEqual({ 1: 'AD_CREATED', 2: 'AD_SOLD' });
  });

  it('round-trips every key through invert(invert(map)) for a non-trivial map', () => {
    const forward = {
      new: 'NEW',
      could_not_connect: 'COULD_NOT_CONNECT',
      need_to_call_back: 'NEED_TO_CALL_BACK',
      rejected: 'REJECTED',
      accepted: 'ACCEPTED',
    } as const;
    const reversed = invert(forward);
    const roundTripped = invert(reversed);
    expect(roundTripped).toEqual(forward);
  });

  it('returns an empty object for an empty map', () => {
    expect(invert({})).toEqual({});
  });
});
