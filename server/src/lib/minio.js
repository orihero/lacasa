import { Client } from "minio";

export const BUCKET = process.env.MINIO_BUCKET ?? "lacasa";
export const PUBLIC_URL = process.env.MINIO_PUBLIC_URL ?? `http://localhost:9000/${BUCKET}`;

export const minio = new Client({
  endPoint: process.env.MINIO_ENDPOINT ?? "localhost",
  port: Number(process.env.MINIO_PORT ?? 9000),
  useSSL: process.env.MINIO_USE_SSL === "true",
  accessKey: process.env.MINIO_ACCESS_KEY,
  secretKey: process.env.MINIO_SECRET_KEY,
});

// Best-effort reverse of `${PUBLIC_URL}/${objectKey}` — used to know what to
// delete from the bucket when an ad is removed. Falls back to the full URL
// for photos that didn't come from our presign flow (nothing to delete for
// those, but we still want a stable identifier to store).
export function objectKeyFromUrl(url) {
  const prefix = `${PUBLIC_URL}/`;
  return typeof url === "string" && url.startsWith(prefix) ? url.slice(prefix.length) : url;
}
