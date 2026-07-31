import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { signToken } from "../lib/jwt.js";
import { requireAuth } from "../middleware/auth.js";
import { serializeUser } from "../lib/serializeUser.js";

const router = Router();

const registerSchema = z.object({
  fullName: z.string().min(1).max(200),
  email: z.string().email(),
  password: z.string().min(6).max(200),
  phoneNumber: z.string().max(30).optional(),
});

router.post("/register", async (req, res, next) => {
  try {
    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const { fullName, email, password, phoneNumber } = parsed.data;

    const existing = await req.ctx.prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: { code: "email_taken", message: "Email is already registered" } });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await req.ctx.prisma.user.create({
      data: { fullName, email, passwordHash, phoneNumber, role: "USER" },
    });

    const token = signToken({ sub: user.id, role: user.role });
    res.status(201).json({ token, user: serializeUser(user) });
  } catch (e) {
    next(e);
  }
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

router.post("/login", async (req, res, next) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const { email, password } = parsed.data;

    const user = await req.ctx.prisma.user.findUnique({ where: { email } });
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      return res.status(401).json({ error: { code: "invalid_credentials", message: "Invalid email or password" } });
    }

    const context = await resolveAgentContext(req.ctx.prisma, user);
    const token = signToken({ sub: user.id, role: user.role });
    res.json({ token, user: serializeUser(user, context) });
  } catch (e) {
    next(e);
  }
});

router.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await req.ctx.prisma.user.findUnique({ where: { id: req.auth.sub } });
    if (!user) {
      return res.status(401).json({ error: { code: "unauthorized", message: "User no longer exists" } });
    }
    const context = await resolveAgentContext(req.ctx.prisma, user);
    res.json({ user: serializeUser(user, context) });
  } catch (e) {
    next(e);
  }
});

// A coworker's connected IG/TG accounts belong to their agent; an agent's
// belong to themself. Mirrors the lookup src/lib/userStore.js used to do
// against the Firestore "users" collection.
async function resolveAgentContext(prisma, user) {
  if (user.role !== "AGENT" && user.role !== "COWORKER") return {};
  const agentId = user.role === "AGENT" ? user.id : user.agentId;
  if (!agentId) return {};

  const agent = await prisma.user.findUnique({
    where: { id: agentId },
    include: { igTokens: true },
  });
  if (!agent) return {};

  return {
    tgChatIds: agent.tgChatIds,
    // Metadata only — access tokens stay server-side (publishing goes
    // through POST /api/publish/instagram, migration plan E.2).
    igAccounts: agent.igTokens.map((t) => ({
      igUserId: t.igUserId,
      username: t.igUsername,
      expiresAt: t.expiresAt,
    })),
  };
}

export default router;
