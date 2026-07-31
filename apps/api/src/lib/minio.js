import { Client } from "minio";
import { config } from "./config.js";

export const BUCKET = config.MINIO_BUCKET;
export const PUBLIC_URL = config.MINIO_PUBLIC_URL;

// Factory instead of a module singleton: app.js constructs one instance at
// boot and threads it through req.ctx.minio, so tests can substitute a fake
// client without a real MinIO connection.
export function createMinioClient() {
  return new Client({
    endPoint: config.MINIO_ENDPOINT,
    port: config.MINIO_PORT,
    useSSL: config.MINIO_USE_SSL,
    accessKey: config.MINIO_ACCESS_KEY,
    secretKey: config.MINIO_SECRET_KEY,
  });
}

// Best-effort reverse of `${PUBLIC_URL}/${objectKey}` — used to know what to
// delete from the bucket when an ad is removed. Falls back to the full URL
// for photos that didn't come from our presign flow (nothing to delete for
// those, but we still want a stable identifier to store).
export function objectKeyFromUrl(url) {
  const prefix = `${PUBLIC_URL}/`;
  return typeof url === "string" && url.startsWith(prefix) ? url.slice(prefix.length) : url;
}
