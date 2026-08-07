import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";

const router = Router();

function serializeCoworker(u) {
  return {
    id: u.id,
    fullName: u.fullName,
    email: u.email,
    phoneNumber: u.phoneNumber,
    avatar: u.avatarUrl,
    agentId: u.agentId,
  };
}

router.use(requireAuth, loadCurrentUser);

// Agents see their own coworkers; a coworker can list their siblings (same
// agentId) — mirrors the old unrestricted Firestore `where agentId==X` reads
// that both LeadKanbanList and Chart relied on.
router.get("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const coworkers = await req.ctx.prisma.user.findMany({ where: { agentId, role: "COWORKER" } });
    res.json(coworkers.map(serializeCoworker));
  } catch (e) {
    next(e);
  }
});

const createSchema = z.object({
  fullName: z.string().min(1).max(200),
  email: z.string().email(),
  password: z.string().min(6).max(200),
  phoneNumber: z.string().max(30).optional(),
  avatar: z.string().max(2000).optional(),
});

router.post("/", async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents can create coworkers" } });
    }
    // A team is the thing an agency has and a solo agent doesn't — the same
    // rule that hides the Coworkers screen for them (SCREENS.md §13, §35).
    // Agents from before the solo/agency split were backfilled to AGENCY, so
    // this can only ever refuse an account that chose "Solo agent".
    if (req.currentUser.realtorKind === "SOLO") {
      return res.status(403).json({
        error: { code: "solo_realtor", message: "Solo agents don't have a team. Switch to an agency account to add coworkers." },
      });
    }
    const parsed = createSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const { fullName, email, password, phoneNumber, avatar } = parsed.data;

    const existing = await req.ctx.prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: { code: "email_taken", message: "Email is already registered" } });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const coworker = await req.ctx.prisma.user.create({
      data: {
        fullName,
        email,
        passwordHash,
        phoneNumber,
        avatarUrl: avatar,
        role: "COWORKER",
        agentId: req.currentUser.id,
      },
    });
    res.status(201).json(serializeCoworker(coworker));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const coworker = await req.ctx.prisma.user.findFirst({
      where: { id: req.params.id, role: "COWORKER", agentId },
    });
    if (!coworker) {
      return res.status(404).json({ error: { code: "not_found", message: "Coworker not found" } });
    }
    res.json(serializeCoworker(coworker));
  } catch (e) {
    next(e);
  }
});

const updateSchema = z.object({
  fullName: z.string().min(1).max(200).optional(),
  email: z.string().email().optional(),
  phoneNumber: z.string().max(30).optional(),
  avatar: z.string().max(2000).optional(),
  password: z.string().min(6).max(200).optional(),
});

router.patch("/:id", async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only the owning agent can edit a coworker" } });
    }
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const existing = await req.ctx.prisma.user.findFirst({
      where: { id: req.params.id, role: "COWORKER", agentId: req.currentUser.id },
    });
    if (!existing) {
      return res.status(404).json({ error: { code: "not_found", message: "Coworker not found" } });
    }

    const { fullName, email, phoneNumber, avatar, password } = parsed.data;
    const data = {};
    if (fullName !== undefined) data.fullName = fullName;
    if (email !== undefined) data.email = email;
    if (phoneNumber !== undefined) data.phoneNumber = phoneNumber;
    if (avatar !== undefined) data.avatarUrl = avatar;
    if (password) data.passwordHash = await bcrypt.hash(password, 10);

    const coworker = await req.ctx.prisma.user.update({ where: { id: req.params.id }, data });
    res.json(serializeCoworker(coworker));
  } catch (e) {
    if (e.code === "P2002") {
      return res.status(409).json({ error: { code: "email_taken", message: "Email is already registered" } });
    }
    next(e);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only the owning agent can delete a coworker" } });
    }
    const existing = await req.ctx.prisma.user.findFirst({
      where: { id: req.params.id, role: "COWORKER", agentId: req.currentUser.id },
    });
    if (!existing) {
      return res.status(404).json({ error: { code: "not_found", message: "Coworker not found" } });
    }
    await req.ctx.prisma.user.delete({ where: { id: req.params.id } });
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default router;
