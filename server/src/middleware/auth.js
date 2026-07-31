import { verifyToken } from "../lib/jwt.js";
import { prisma } from "../lib/prisma.js";

export function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  const token = header?.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: { code: "unauthorized", message: "Missing token" } });
  }
  try {
    req.auth = verifyToken(token); // { sub, role }
    next();
  } catch {
    return res.status(401).json({ error: { code: "unauthorized", message: "Invalid or expired token" } });
  }
}

// Loads the full current-user row (needed for req.currentUser.agentId when
// the caller is a COWORKER — the JWT only carries { sub, role }). Must run
// after requireAuth.
export async function loadCurrentUser(req, res, next) {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.auth.sub } });
    if (!user) {
      return res.status(401).json({ error: { code: "unauthorized", message: "User no longer exists" } });
    }
    req.currentUser = user;
    next();
  } catch (e) {
    next(e);
  }
}
