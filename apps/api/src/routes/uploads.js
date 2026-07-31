import { randomUUID } from "node:crypto";
import { Router } from "express";
import { z } from "zod";
import { minio, BUCKET, PUBLIC_URL } from "../lib/minio.js";

const router = Router();

const presignSchema = z.object({
  fileName: z.string().min(1).max(200),
  contentType: z.string().regex(/^(image|video)\//),
  scope: z.enum(["ads", "avatars"]),
});

// TODO(Phase B): require auth once /api/auth lands.
router.post("/presign", async (req, res, next) => {
  try {
    const parsed = presignSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const { fileName, scope } = parsed.data;
    const safeName = fileName.replace(/[^a-zA-Z0-9._-]/g, "_");
    const objectKey = `${scope}/${randomUUID()}-${safeName}`;
    const uploadUrl = await minio.presignedPutObject(BUCKET, objectKey, 10 * 60);
    res.json({ uploadUrl, objectKey, publicUrl: `${PUBLIC_URL}/${objectKey}` });
  } catch (e) {
    next(e);
  }
});

export default router;
