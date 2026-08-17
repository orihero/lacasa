/**
 * src/shell/Topbar — the sticky 50px bar over the records column: the current
 * page's title on the left, then the trailing control cluster.
 *
 * The title comes from `titleForPath(useLocation().pathname)` — the same
 * function the rail's active row is derived from (shell/nav.ts) — rather than
 * from a prop each screen passes, so a screen cannot render under the wrong
 * heading and the two can never disagree about where the admin is.
 *
 * The mockup's global "Search users, ads, UUIDs…" box is NOT ported. There is
 * no cross-entity search endpoint (`GET /api/admin/users?q=` searches users by
 * name and email, and that is all), so a global box would either 404 on a UUID
 * or silently search only one of the three things it names. The Users screen
 * owns its own `q` field against the endpoint that really exists.
 */
import { useLocation } from "react-router-dom";
import { IconButton } from "@/ui/IconButton";
import { BellIcon, GearIcon } from "@/ui/icons";
import { titleForPath } from "./nav";

export function Topbar() {
  const { pathname } = useLocation();

  return (
    <header className="sticky top-0 z-40 flex h-topbar flex-none items-center gap-3 border-b border-line bg-card px-[18px]">
      <h1 className="truncate text-title font-semibold text-ink">{titleForPath(pathname)}</h1>

      <div className="ml-auto flex items-center gap-2">
        {/*
          Both controls are inert today and neither carries a signal it cannot
          back up — in particular the bell has NO unread dot. The mockup draws
          one, but there is no notifications model behind this surface (the
          only notification plumbing in the schema is the mobile app's push
          devices), so a pip here would be a fabricated "something needs you"
          on the one screen whose entire job is telling an admin what needs
          them. They stay as disabled placeholders rather than being deleted
          so the bar keeps the mockup's geometry when either is wired up.
        */}
        <IconButton icon={BellIcon} label="Notifications (not available yet)" disabled />
        <IconButton icon={GearIcon} label="Settings (not available yet)" disabled />
      </div>
    </header>
  );
}
