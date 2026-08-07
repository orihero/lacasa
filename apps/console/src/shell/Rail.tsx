/**
 * src/shell/Rail — the 236px labeled left rail (mockups/f/PLAN.md §2): three
 * groups of real routes plus the account-switcher footer chip.
 *
 * Active state is NOT react-router's built-in <NavLink> matching: the
 * Listing editor row has to light up for both /ads/new and /ads/:id/edit
 * (see shell/nav.ts's isNavItemActive doc comment for why a plain prefix
 * match can't express that without also over-matching My ads' /ads row), so
 * every row's active state is computed by hand from the same
 * `isNavItemActive` function shell/nav.ts and Topbar both read.
 *
 * Badge counts come from the same live queries the destination screens
 * render from (useMyAds/useLeads/useCoworkers) — never a placeholder while
 * loading (railBadgeCount, shell/nav.ts).
 *
 * The account-footer chip is the app's only reachable `useAuth().logout()`
 * call site: the prototype draws it as an inert caret-down div (no dropdown
 * wired, "matches prototype convention" per PLAN.md §2) and the topbar's
 * gear icon is similarly unwired there, but a real tool cannot ship with no
 * way to end a session at all — a caret that visually promises a menu and
 * opens nothing is exactly the fake-affordance FilterChip's own convention
 * warns against elsewhere in this app. Kept to one small popover here
 * (Escape/outside-click to close, real `<button>`s) rather than growing a
 * dedicated menu primitive for what is still, today, a single action.
 */
import { useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import clsx from "clsx";
import { Avatar } from "@/ui/Avatar";
import { CaretDownIcon, SignOutIcon } from "@/ui/icons";
import { useAuth } from "@/lib/auth";
import { useMyAds } from "@/data/useAds";
import { useLeads } from "@/data/useLeads";
import { useCoworkers } from "@/data/useCoworkers";
import { NAV_GROUPS, isNavItemActive, railBadgeCount, type NavItem } from "./nav";

type BadgeCounts = Record<NonNullable<NavItem["badge"]>, number | undefined>;

function useBadgeCounts(): BadgeCounts {
  const ads = useMyAds();
  const leads = useLeads();
  const coworkers = useCoworkers();
  return {
    ads: railBadgeCount(ads.data?.length, ads.isLoading),
    leads: railBadgeCount(leads.data?.length, leads.isLoading),
    coworkers: railBadgeCount(coworkers.data?.length, coworkers.isLoading),
  };
}

function formatRole(role: string): string {
  return role.charAt(0).toUpperCase() + role.slice(1);
}

export function Rail() {
  const { pathname } = useLocation();
  const badgeCounts = useBadgeCounts();

  return (
    <aside className="sticky top-[22px] flex w-rail flex-none flex-col gap-[3px]">
      {NAV_GROUPS.map((group, groupIndex) => (
        <div key={group.zone}>
          <div
            className={clsx(
              "mx-[14px] mb-[7px] text-mini font-semibold uppercase tracking-caps-wide text-ink-2",
              groupIndex === 0 ? "mt-0.5" : "mt-4",
            )}
          >
            {group.label}
          </div>
          {group.items.map((item) => {
            const active = isNavItemActive(pathname, item);
            const Icon = item.icon;
            const count = item.badge ? badgeCounts[item.badge] : undefined;
            return (
              <Link
                key={item.to}
                to={item.to}
                aria-current={active ? "page" : undefined}
                className={clsx(
                  "flex items-center gap-[11px] rounded-full border px-[14px] py-2.5 text-nav font-medium",
                  active
                    ? "border-dark bg-dark text-dark-text"
                    : "border-transparent text-ink hover:border-hairline hover:bg-pill",
                )}
              >
                <Icon size={16} weight="fill" className={active ? "text-dark-text" : "text-ink-2"} />
                {item.label}
                {count !== undefined ? (
                  <em
                    className={clsx(
                      "ml-auto rounded-full px-2 py-px text-tiny font-semibold not-italic",
                      active ? "bg-white/[.16] text-dark-text" : "bg-surface-inner text-ink",
                    )}
                  >
                    {count}
                  </em>
                ) : null}
              </Link>
            );
          })}
        </div>
      ))}

      <AccountFooter />
    </aside>
  );
}

/**
 * Split out of Rail's render so its own open/close state and outside-click
 * listener don't re-run on every rail badge re-render — Rail itself
 * re-renders on every `useLocation()` route change.
 */
function AccountFooter() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onPointerDown(event: PointerEvent) {
      if (rootRef.current && !rootRef.current.contains(event.target as Node)) setOpen(false);
    }
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") setOpen(false);
    }
    document.addEventListener("pointerdown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("pointerdown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [open]);

  function handleSignOut() {
    setOpen(false);
    logout();
    // logout() flips AuthProvider's status to 'anonymous' synchronously, and
    // RequireAuth already redirects on that — this navigate is a belt-and-
    // braces fallback for the instant between the state flip and the next
    // render, not a second source of truth for where /login lives.
    navigate("/login", { replace: true });
  }

  return (
    <div ref={rootRef} className="relative mt-5">
      <button
        type="button"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
        className="flex w-full items-center gap-2.5 rounded-full border border-hairline bg-pill py-[9px] pl-[9px] pr-3 text-left transition-colors hover:bg-surface-inner"
      >
        <Avatar src={user?.avatar} name={user?.fullName ?? ""} size="md" />
        <div className="min-w-0">
          <b className="block truncate text-body font-semibold leading-tight">{user?.fullName ?? ""}</b>
          <span className="block truncate text-tiny text-ink-2">{user ? formatRole(user.role) : ""}</span>
        </div>
        <CaretDownIcon size={13} className="ml-auto flex-none text-ink-2" />
      </button>

      {open ? (
        <div
          role="menu"
          aria-label="Account"
          className="absolute bottom-[calc(100%+6px)] left-0 right-0 rounded-input border border-hairline bg-surface p-1.5"
        >
          <button
            type="button"
            role="menuitem"
            onClick={handleSignOut}
            className="flex w-full items-center gap-2 rounded-chip px-2.5 py-2 text-left text-body text-ink transition-colors hover:bg-pill"
          >
            <SignOutIcon size={15} />
            Sign out
          </button>
        </div>
      ) : null}
    </div>
  );
}
