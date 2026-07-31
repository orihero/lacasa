import { describe, expect, it } from 'vitest';
import { igPublishSchema, mapFieldsSchema, confirmSchema, reassignSchema } from './publish';

describe('igPublishSchema', () => {
  it('accepts a well-formed publish request', () => {
    expect(
      igPublishSchema.parse({
        adId: 'ad-1',
        caption: 'Nice flat',
        imageUrls: ['https://example.com/a.jpg'],
      }),
    ).toMatchObject({ adId: 'ad-1' });
  });

  it('rejects an empty imageUrls array', () => {
    expect(() =>
      igPublishSchema.parse({ adId: 'ad-1', caption: '', imageUrls: [] }),
    ).toThrow();
  });

  it('rejects a non-URL image entry', () => {
    expect(() =>
      igPublishSchema.parse({ adId: 'ad-1', caption: '', imageUrls: ['not-a-url'] }),
    ).toThrow();
  });
});

describe('mapFieldsSchema', () => {
  it('accepts a well-formed map-fields request', () => {
    expect(
      mapFieldsSchema.parse({ adId: 'draft-1', ad: { title: 'x' }, step: 'category', snapshot: [{}] }),
    ).toMatchObject({ adId: 'draft-1', step: 'category' });
  });

  it('rejects an empty snapshot array', () => {
    expect(() =>
      mapFieldsSchema.parse({ adId: 'draft-1', ad: {}, step: 'category', snapshot: [] }),
    ).toThrow();
  });
});

describe('confirmSchema', () => {
  it('accepts each valid confirm event', () => {
    for (const event of ['drafted', 'published', 'failed', 'aborted', 'dom-drift']) {
      expect(confirmSchema.parse({ adId: 'ad-1', event }).event).toBe(event);
    }
  });

  it('rejects an event outside the ConfirmEvent union', () => {
    expect(() => confirmSchema.parse({ adId: 'ad-1', event: 'bogus' })).toThrow();
  });

  it('rejects a malformed externalUrl', () => {
    expect(() =>
      confirmSchema.parse({ adId: 'ad-1', event: 'published', externalUrl: 'not-a-url' }),
    ).toThrow();
  });
});

describe('reassignSchema', () => {
  it('accepts a well-formed reassign request', () => {
    expect(reassignSchema.parse({ fromAdId: 'draft-1', toAdId: 'ad-1' })).toEqual({
      fromAdId: 'draft-1',
      toAdId: 'ad-1',
    });
  });

  it('rejects a missing toAdId', () => {
    expect(() => reassignSchema.parse({ fromAdId: 'draft-1' })).toThrow();
  });
});
