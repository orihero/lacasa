/**
 * usePhotoUpload — the Media panel's upload mechanics: `apiClient.uploads
 * .presign` (real, `@lacasa/api-client`'s uploads resource — POST /uploads/
 * presign) followed by a raw binary `PUT` straight to the returned
 * `uploadUrl`. That PUT deliberately does NOT go through `apiClient`: per
 * `packages/api-client/src/resources/uploads.ts`'s own file header, it's an
 * unauthenticated request straight to MinIO, not this API's baseUrl. This
 * app has no axios dependency (unlike apps/web/src/lib/assetUpload.js, the
 * reference implementation this ports), so it's a plain `fetch` PUT.
 *
 * Scoped entirely to this screen folder — no other screen uploads a file.
 */
import { useState } from 'react';
import { apiClient } from '@/lib/apiClient';

export interface UsePhotoUploadResult {
  uploading: boolean;
  error: string | null;
  /** Uploads every file, in order, returning the public URLs that
   * succeeded. A failure mid-batch stops there and surfaces `error`, but
   * still returns whatever succeeded before it — a caller can append the
   * partial result rather than lose already-uploaded photos. */
  uploadFiles: (files: FileList | File[]) => Promise<string[]>;
}

export function usePhotoUpload(): UsePhotoUploadResult {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function uploadFiles(files: FileList | File[]): Promise<string[]> {
    const list = Array.from(files);
    if (list.length === 0) return [];

    setUploading(true);
    setError(null);
    const uploaded: string[] = [];
    try {
      for (const file of list) {
        const { uploadUrl, publicUrl } = await apiClient.uploads.presign({
          fileName: file.name,
          contentType: file.type,
          scope: 'ads',
        });
        const response = await fetch(uploadUrl, {
          method: 'PUT',
          headers: { 'Content-Type': file.type },
          body: file,
        });
        if (!response.ok) {
          throw new Error(`"${file.name}" failed to upload (${response.status}).`);
        }
        uploaded.push(publicUrl);
      }
      return uploaded;
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Photo upload failed.');
      return uploaded;
    } finally {
      setUploading(false);
    }
  }

  return { uploading, error, uploadFiles };
}
