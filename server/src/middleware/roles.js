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
