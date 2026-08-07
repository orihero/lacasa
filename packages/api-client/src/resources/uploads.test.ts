import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createUploadsResource } from './uploads';

describe('uploads resource', () => {
  it('presign POSTs /uploads/presign with the presign input as body', async () => {
    const { transport, calls } = createFakeTransport({
      uploadUrl: 'https://minio/x',
      objectKey: 'ads/1-photo.jpg',
      publicUrl: 'https://cdn/ads/1-photo.jpg',
    });
    const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
    const uploads = createUploadsResource(client);

    const result = await uploads.presign({ fileName: 'photo.jpg', contentType: 'image/jpeg', scope: 'ads' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/uploads/presign',
      body: { fileName: 'photo.jpg', contentType: 'image/jpeg', scope: 'ads' },
    });
    expect(result.publicUrl).toBe('https://cdn/ads/1-photo.jpg');
  });
});
