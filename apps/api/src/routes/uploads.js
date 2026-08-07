import { randomUUID } from "node:crypto";
import { Router } from "express";
import { z } from "zod";
import { BUCKET, PUBLIC_URL } from "../lib/minio.js";
import { requireAuth } from "../middleware/auth.js";

const router = Router();

const presignSchema = z.object({
  fileName: z.string().min(1).max(200),
  contentType: z.string().regex(/^(image|video)\//),
  scope: z.enum(["ads", "avatars"]),
});

// BEHAVIOR CHANGE: this previously had no auth check at all (a standing
// "TODO(Phase B): require auth once /api/auth lands" — /api/auth has long
// since landed). Any anonymous caller could mint a presigned MinIO upload
// URL for the "ads" or "avatars" scope. requireAuth closes that: a valid
// bearer token is now required to call POST /api/uploads/presign.
router.post("/presign", requireAuth, async (req, res, next) => {
  try {
    const parsed = presignSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const { fileName, scope } = parsed.data;
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
    const objectKey = `${scope}/${randomUUID()}-${safeName}`;
    const uploadUrl = await req.ctx.minio.presignedPutObject(BUCKET, objectKey, 10 * 60);
    res.json({ uploadUrl, objectKey, publicUrl: `${PUBLIC_URL}/${objectKey}` });
  } catch (e) {
    next(e);
  }
});

export default router;
