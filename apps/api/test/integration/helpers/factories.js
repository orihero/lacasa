import { randomUUID } from "node:crypto";
import bcrypt from "bcryptjs";
import { signToken } from "../../../src/lib/jwt.js";

// Creates a real row in the test database (bypassing the HTTP API, which
// has no endpoint to promote a user to AGENT — that's an admin/seed-only
// action in this app, same as prisma/seed.js's agent@lacasa.dev). Email
// defaults to something unique per call so tests never collide on the
// `users.email` unique constraint within a file (tables are only truncated
// *between* files — see test/integration/helpers/db.js).
export async function createUser(prisma, overrides = {}) {
  const { role = "USER", password = "password123", agentId = null, ...rest } = overrides;
  const passwordHash = await bcrypt.hash(password, 10);
  return prisma.user.create({
    data: {
      fullName: rest.fullName ?? "Test User",
      email: rest.email ?? `user-${randomUUID()}@example.test`,
      passwordHash,
      role,
      agentId,
      phoneNumber: rest.phoneNumber,
    },
  });
}

// Mints a real, correctly-signed JWT for a user row already in the test
// database — exactly the token shape src/lib/jwt.js#signToken produces for
// a real login, so routes exercise the same requireAuth/loadCurrentUser
// path a real client would.
export function tokenFor(user) {
  return signToken({ sub: user.id, role: user.role });
}

export function authHeader(user) {
  return `Bearer ${tokenFor(user)}`;
}
