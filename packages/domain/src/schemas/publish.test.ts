import { describe, expect, it } from 'vitest';
import { igPublishSchema, mapFieldsSchema, confirmSchema, reassignSchema, tgPublishSchema, ytReportSchema } from './publish';

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

describe('tgPublishSchema', () => {
  it('accepts a well-formed publish request', () => {
    expect(
      tgPublishSchema.parse({
        adId: 'ad-1',
        caption: 'Nice flat',
        imageUrls: ['https://example.com/a.jpg'],
        chatIds: ['-1002366623212'],
      }),
    ).toMatchObject({ adId: 'ad-1', chatIds: ['-1002366623212'] });
  });

  it('rejects an empty chatIds array', () => {
    expect(() =>
      tgPublishSchema.parse({ adId: 'ad-1', caption: '', imageUrls: ['https://example.com/a.jpg'], chatIds: [] }),
    ).toThrow();
  });

  it('rejects a caption over Telegram\'s 1024-char media caption limit', () => {
    expect(() =>
      tgPublishSchema.parse({
        adId: 'ad-1',
        caption: 'x'.repeat(1025),
        imageUrls: ['https://example.com/a.jpg'],
        chatIds: ['1'],
      }),
    ).toThrow();
  });
});

describe('ytReportSchema', () => {
  it('accepts a PUBLISHED report with a valid video id', () => {
    expect(
      ytReportSchema.parse({ adId: 'ad-1', status: 'PUBLISHED', externalId: 'dQw4w9WgXcQ' }),
    ).toMatchObject({ status: 'PUBLISHED', externalId: 'dQw4w9WgXcQ' });
  });

  it('accepts a FAILED report with no externalId', () => {
    expect(
      ytReportSchema.parse({ adId: 'ad-1', status: 'FAILED', errorMessage: 'upload quota exceeded' }),
    ).toMatchObject({ status: 'FAILED' });
  });

  it('rejects a PUBLISHED report with no externalId', () => {
    expect(() => ytReportSchema.parse({ adId: 'ad-1', status: 'PUBLISHED' })).toThrow();
  });

  it('rejects an externalId that is not 11 characters', () => {
    expect(() =>
      ytReportSchema.parse({ adId: 'ad-1', status: 'PUBLISHED', externalId: 'tooshort' }),
    ).toThrow();
  });

  it('rejects an externalUrl that does not point at youtube.com/youtu.be', () => {
    expect(() =>
      ytReportSchema.parse({
        adId: 'ad-1',
        status: 'PUBLISHED',
        externalId: 'dQw4w9WgXcQ',
        externalUrl: 'https://evil.example.com/dQw4w9WgXcQ',
      }),
    ).toThrow();
  });

  it('accepts a valid youtu.be externalUrl', () => {
    expect(
      ytReportSchema.parse({
        adId: 'ad-1',
        status: 'PUBLISHED',
        externalId: 'dQw4w9WgXcQ',
        externalUrl: 'https://youtu.be/dQw4w9WgXcQ',
      }).externalUrl,
    ).toBe('https://youtu.be/dQw4w9WgXcQ');
  });
});
