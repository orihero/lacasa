// Daily refresh of long-lived Instagram tokens (60-day expiry, docs/09 §1.2
// step 5). Refreshes anything expiring within 7 days; tokens must be >=24h
// old and not yet expired, which a daily cadence comfortably satisfies.
import { prisma } from "./prisma.js";
import { refreshLongLived } from "./instagram.js";

const WINDOW_DAYS = 7;
const DAY_MS = 24 * 3600 * 1000;

export async function refreshExpiringIgTokens() {
  const cutoff = new Date(Date.now() + WINDOW_DAYS * DAY_MS);
  const expiring = await prisma.agentIgToken.findMany({
    where: { expiresAt: { not: null, lte: cutoff, gt: new Date() } },
  });
  for (const row of expiring) {
    try {
      const refreshed = await refreshLongLived(row.accessToken);
      await prisma.agentIgToken.update({
        where: { id: row.id },
        data: {
          accessToken: refreshed.access_token,
          expiresAt: new Date(Date.now() + (refreshed.expires_in ?? 60 * 24 * 3600) * 1000),
          refreshedAt: new Date(),
        },
      });
      console.log(`Refreshed IG token for @${row.igUsername ?? row.igUserId}`);
    } catch (e) {
      console.error(`Failed to refresh IG token for @${row.igUsername ?? row.igUserId}:`, e.message);
    }
  }
  return expiring.length;
}

export function scheduleIgTokenRefresh() {
  // Run shortly after boot, then daily.
  setTimeout(() => refreshExpiringIgTokens().catch(console.error), 30_000);
  setInterval(() => refreshExpiringIgTokens().catch(console.error), DAY_MS).unref?.();
}
