import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { requireAuth } from "../middleware/auth.js";
import { serializeUser } from "../lib/serializeUser.js";

const router = Router();

const updateSchema = z.object({
  fullName: z.string().min(1).max(200).optional(),
  phoneNumber: z.string().max(30).optional(),
  email: z.string().email().optional(),
  avatar: z.string().max(2000).optional(),
  password: z.string().min(6).max(200).optional(),
});

router.patch("/me", requireAuth, async (req, res, next) => {
  try {
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const { fullName, phoneNumber, email, avatar, password } = parsed.data;

    const data = {};
    if (fullName !== undefined) data.fullName = fullName;
    if (phoneNumber !== undefined) data.phoneNumber = phoneNumber;
    if (email !== undefined) data.email = email;
    if (avatar !== undefined) data.avatarUrl = avatar;
    if (password) data.passwordHash = await bcrypt.hash(password, 10);

    const user = await req.ctx.prisma.user.update({ where: { id: req.auth.sub }, data });
    res.json({ user: serializeUser(user) });
  } catch (e) {
    if (e.code === "P2002") {
      return res.status(409).json({ error: { code: "email_taken", message: "Email is already registered" } });
    }
    next(e);
  }
});

export default router;
