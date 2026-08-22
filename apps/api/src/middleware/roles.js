export function requireRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.auth?.role)) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    next();
  };
}

// Same refusal as requireRole, but decided on req.currentUser.role — the row
// as it is in Postgres right now — instead of req.auth.role, which is a claim
// baked into the JWT when it was issued and frozen there for JWT_EXPIRES_IN
// (7 days by default).
//
// That difference is the whole point, and it is why this exists as a second
// middleware rather than a flag on the first. A JWT cannot be revoked: an
// account demoted out of ADMIN keeps a token that still *says* ADMIN until it
// expires, so a requireRole-only gate means "revoke this person's admin
// rights" does nothing for a week — and the demoted holder can walk straight
// back into PATCH /users/:id/role and re-promote themselves, which makes the
// revocation permanently undoable. Every other router in this app already
// resolves authority from the loaded row (loadCurrentUser + effectiveAgentId),
// so this is what puts /api/admin on the same footing as the surfaces that
// hold far less power.
//
// Must run after loadCurrentUser. Pair it with requireRole rather than
// replacing it: the cheap claim check first refuses an obviously-wrong token
// without a database round trip, and this one is the authority.
export function requireCurrentRole(...roles) {
  return (req, res, next) => {
    if (!roles.includes(req.currentUser?.role)) {
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
