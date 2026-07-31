import { PrismaClient } from "@prisma/client";

// Factory instead of a module singleton: app.js constructs one instance at
// boot and threads it through req.ctx.prisma, so tests can substitute a
// fake client without a real database connection.
export function createPrismaClient() {
  return new PrismaClient();
}
