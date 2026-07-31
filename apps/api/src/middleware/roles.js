export function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.auth?.role)) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    next();
  };
}

// Resolves the "agent scope" a request acts within: an AGENT acts on their
// own id, a COWORKER acts on their agent's id. Anything else is 403.
export function effectiveAgentId(user) {
  if (user.role === "AGENT") return user.id;
  if (user.role === "COWORKER") return user.agentId;
  return null;
}

// Resolves who a publish/cross-post action is recorded as: an AGENT
// publishes under their own id; a COWORKER publishes under their agent's,
// and is additionally recorded as the acting coworker. Returns null when
// the caller's role can't publish at all (same "not allowed for this role"
// case effectiveAgentId signals with null).
export function actorFields(user) {
  const agentId = effectiveAgentId(user);
  if (!agentId) return null;
  return { user, agentId, coworkerId: user.role === "COWORKER" ? user.id : null };
}
