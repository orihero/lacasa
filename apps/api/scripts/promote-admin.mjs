// Grants an existing account the ADMIN role — how the FIRST admin is created.
// There is deliberately no self-signup path to ADMIN (registerSchema in
// @lacasa/domain cannot express it, and routes/auth.js hardcodes role USER),
// so the first control-room account has to be minted out of band, by someone
// with shell access to the server.
//
// After that first one exists, this script is no longer the only path: an
// admin can promote another from the control room itself, via
// PATCH /api/admin/users/:id/role with role="admin". That is intended — an
// offboarded admin should not require a shell to replace — but it is worth
// stating plainly here, because a threat model that assumes "shell access
// required to mint an admin" is wrong, and note that no admin action is
// recorded anywhere today (ActivityEvent is agent-scoped, so it cannot
// attribute one). Run from apps/api:
//
//   node scripts/promote-admin.mjs someone@example.com
//   npm run promote:admin -w @lacasa/api -- someone@example.com
//
// `dotenv/config` rather than src/lib/config.js: that module fails fast when
// ANY required var is missing, including the MinIO credentials this script has
// no use for. All it needs is DATABASE_URL, which PrismaClient reads itself.
import "dotenv/config";
import { createPrismaClient } from "../src/lib/prisma.js";

const email = process.argv[2]?.trim();

if (!email) {
  console.error("Usage: node scripts/promote-admin.mjs <email>");
  process.exit(1);
}

const prisma = createPrismaClient();

try {
  const user = await prisma.user.findUnique({
    where: { email },
    select: { id: true, fullName: true, email: true, role: true },
  });

  // Refuse rather than create: promoting is a privilege change on a real
  // person's account, and a typo'd address that silently conjured a
  // passwordless admin would be the worst possible failure mode here.
  if (!user) {
    console.error(`No user with email ${email}. Have them register first, then re-run this.`);
    process.exit(1);
  }

  if (user.role === "ADMIN") {
    console.log(`${user.fullName} <${user.email}> is already an admin. Nothing to do.`);
  } else {
    // ADMIN is not agent-scoped (see effectiveAgentId in src/middleware/roles.js),
    // so promoting an AGENT or COWORKER takes away their Work-tab access even
    // though their ads and coworkers stay untouched in the database. Say so
    // out loud — it is the one surprising consequence of this command.
    if (user.role === "AGENT" || user.role === "COWORKER") {
      console.warn(
        `Warning: ${user.email} is currently ${user.role}. ADMIN carries no agent scope, ` +
          "so they will lose access to their agent surfaces. Their ads, coworkers and leads " +
          "are left in place and come back if the role is set back.",
      );
    }

    const promoted = await prisma.user.update({
      where: { id: user.id },
      data: { role: "ADMIN" },
      select: { fullName: true, email: true },
    });

    console.log(
      `Promoted ${promoted.fullName} <${promoted.email}> from ${user.role} to ADMIN.`,
    );
  }
} finally {
  await prisma.$disconnect();
}
