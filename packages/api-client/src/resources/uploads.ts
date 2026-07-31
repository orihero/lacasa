/**
 * @lacasa/api-client/resources/uploads — ports the presign call out of
 * apps/web/src/lib/assetUpload.js.
 *
 * Only the presign step goes through this client: the actual file PUT that
 * follows is a raw binary upload straight to the presigned MinIO URL, not
 * to this API's baseUrl, and not authenticated with our bearer token. That
 * step is platform-specific (apps/web does an axios.put of a File; a future
 * apps/mobile would use expo-file-system's uploadAsync or similar) and
 * stays in the caller.
 */
import type { ApiClient } from '../core/client';

export interface PresignInput {
  fileName: string;
  contentType: string;
  scope: 'ads' | 'avatars';
}

export interface PresignResponse {
  uploadUrl: string;
  objectKey: string;
  publicUrl: string;
}

export function createUploadsResource(client: ApiClient) {
  return {
    presign(input: PresignInput) {
      return client.request<PresignResponse>({ method: 'POST', path: '/uploads/presign', body: input });
    },
  };
}

export type UploadsResource = ReturnType<typeof createUploadsResource>;
