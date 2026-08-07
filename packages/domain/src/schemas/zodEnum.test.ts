import { describe, expect, it } from 'vitest';
import { zodEnumFromKeys } from './zodEnum';

describe('zodEnumFromKeys', () => {
  const schema = zodEnumFromKeys({ residential: 'RESIDENTIAL', nonresidential: 'NONRESIDENTIAL' });

  it('accepts each key of the source map', () => {
    expect(schema.parse('residential')).toBe('residential');
    expect(schema.parse('nonresidential')).toBe('nonresidential');
  });

  it('rejects a value not present as a key', () => {
    expect(() => schema.parse('RESIDENTIAL')).toThrow();
    expect(() => schema.parse('bogus')).toThrow();
  });
});
