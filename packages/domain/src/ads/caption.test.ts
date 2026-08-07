import { describe, expect, it } from 'vitest';
import { buildCaption } from './caption';

const translate = (key: string) => `[${key}]`;

describe('buildCaption', () => {
  it('formats every field as "label: value unit" and appends priceType only to price', () => {
    const caption = buildCaption(
      { title: 'Nice flat', price: '1000', rooms: 3 },
      'usd',
      translate,
    );
    expect(caption).toBe('[title]: Nice flat  \n[price]: 1000 usd \n[rooms]: 3  \n');
  });

  it('formats hashtags like any other field by default', () => {
    const caption = buildCaption({ title: 'Nice flat', hashtags: '#new' }, 'uzs', translate);
    expect(caption).toBe('[title]: Nice flat  \n[hashtags]: #new  \n');
  });

  it('hoists hashtags unlabeled to the front when hoistHashtags is set', () => {
    const caption = buildCaption(
      { title: 'Nice flat', hashtags: '#new #2024' },
      'uzs',
      translate,
      { hoistHashtags: true },
    );
    expect(caption).toBe('#new #2024\n[title]: Nice flat  \n');
  });

  it('returns an empty string for an empty values object', () => {
    expect(buildCaption({}, 'uzs', translate)).toBe('');
  });

  it('stringifies non-string values', () => {
    const caption = buildCaption({ area: 54.5 }, 'uzs', translate);
    expect(caption).toBe('[area]: 54.5  \n');
  });
});
