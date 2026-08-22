/**
 * src/shell/Topbar — brand, the 3-pill zone indicator, the (inert) search
 * pill, the global "Add new post" CTA, and the bell/gear/avatar cluster.
 *
 * The 3 zone pills are a demoted echo of the rail, not a second nav: they
 * read the SAME `zoneForPath(useLocation().pathname)` the rail uses (see
 * shell/nav.ts's file comment) and, on click, jump to their group's first
 * screen — mockups/f/PLAN.md §2.
 */
import { Link, useLocation, useNavigate } from "react-router-dom";
import clsx from "clsx";
import { Avatar } from "@/ui/Avatar";
import { Button } from "@/ui/Button";
import { IconButton } from "@/ui/IconButton";
import { BellIcon, GearIcon, HouseIcon, MagnifyingGlassIcon, PlusIcon } from "@/ui/icons";
import { useAuth } from "@/lib/auth";
import { NAV_GROUPS, ZONE_ICON, zoneForPath, type Zone } from "./nav";

const ZONE_LABEL: Record<Zone, string> = {
  ws: "Workspace",
  pl: "Pipeline",
  tm: "Team",
};

export function Topbar() {
  const { pathname } = useLocation();
  const navigate = useNavigate();
  const { user } = useAuth();
  const activeZone = zoneForPath(pathname);

  return (
    <header className="mb-6 flex items-center gap-2.5">
      <Link to="/statistics" className="mr-2 flex items-center gap-2.5">
        <span className="flex h-10 w-10 flex-none items-center justify-center rounded-full bg-dark text-dark-text">
          <HouseIcon size={18} weight="fill" />
        </span>
        <span className="whitespace-nowrap text-brand font-semibold tracking-snug">La Casa</span>
      </Link>

      <nav className="flex gap-2" aria-label="Zone">
        {NAV_GROUPS.map((group) => {
          const Icon = ZONE_ICON[group.zone];
          const isOn = group.zone === activeZone;
          const firstItem = group.items[0];
          return (
            <button
              key={group.zone}
              type="button"
              aria-pressed={isOn}
              onClick={() => {
                if (firstItem) navigate(firstItem.to);
              }}
              className={clsx(
                "inline-flex items-center gap-[7px] whitespace-nowrap rounded-full border px-[17px] py-2.5 text-nav font-medium",
                isOn ? "border-dark bg-dark text-dark-text" : "border-hairline bg-pill text-ink",
              )}
            >
              <Icon size={15} weight="fill" className={isOn ? "text-dark-text" : "text-ink-2"} />
              {ZONE_LABEL[group.zone]}
            </button>
          );
        })}
      </nav>

      {/* Not wired to anything yet — an inert control that visually matches
          the prototype's search pill rather than a text box that swallows
          keystrokes nobody reads. `disabled` (not just styled to look
          disabled) so it genuinely cannot receive focus or input. */}
      <div className="ml-2 flex h-11 min-w-[270px] items-center gap-2.5 rounded-full bg-surface py-1 pl-[18px] pr-1">
        <input
          type="search"
          disabled
          placeholder="Search ads, leads…"
          aria-label="Search (not available yet)"
          className="flex-1 bg-transparent text-body text-ink-2 placeholder:text-ink-2 outline-none disabled:cursor-not-allowed"
        />
        <span
          aria-hidden="true"
          className="flex h-9 w-9 flex-none items-center justify-center rounded-full bg-dark text-dark-text"
        >
          <MagnifyingGlassIcon size={15} />
        </span>
      </div>

      <div className="flex-1" />

      <Button variant="primary" icon={PlusIcon} onClick={() => navigate("/ads/new")}>
        Add new post
      </Button>
      {/*
        DATA HONESTY (mockups/f/PLAN.md §4): the prototype's bell carries an
        unread dot, but that's only an "activity since last visit" heuristic
        against ActivityEvent timestamps — the model has no read/unread
        field and there is no activity-feed endpoint at all yet. Render the
        bell plain rather than fabricate a signal this app cannot back up.
      */}
      <IconButton icon={BellIcon} label="Notifications" />
      <IconButton icon={GearIcon} label="Settings" />
      <Avatar src={user?.avatar} name={user?.fullName ?? ""} size="lg" />
    </header>
  );
}
