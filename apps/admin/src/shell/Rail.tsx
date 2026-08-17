/**
 * src/shell/Rail — the 224px dark rail: the environment strip, the wordmark,
 * two labelled groups of real routes, and the signed-in admin's footer chip.
 *
 * Active state is computed by hand from shell/nav.ts's `isNavItemActive`
 * rather than react-router's <NavLink>, so the rail and the topbar's page
 * title are driven by one function and cannot disagree (see nav.ts).
 *
 * THE BADGES READ THE CACHE, THEY DO NOT FETCH.
 * The counts the mockup puts on Applications and Users are exactly two of the
 * numbers `GET /api/admin/overview` already returns, and /overview is this
 * app's landing route — so the rail subscribes to that query's cache entry
 * (`enabled: false`: subscribe to updates, never trigger a request) instead of
 * issuing a second call of its own on every route change. Three consequences,
 * all of them deliberate:
 *   · zero extra requests, and no chance of the rail's "Pending 3" disagreeing
 *     with the overview's "Pending 3" because they were fetched a second apart;
 *   · the badges are empty until something has loaded the overview, which
 *     nav.ts's railBadgeCount already treats as the honest state — an unknown
 *     count renders as no badge, never as 0;
 *   · the rail does not depend on src/data/useOverview.ts, which is another
 *     agent's file — it depends only on the shared key, which is the contract
 *     between them.
 */
import { useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import clsx from "clsx";
import { useAuth } from "@/lib/auth";
import { formatCount, initials } from "@/lib/format";
import { queryKeys } from "@/data/queryKeys";
import { CaretDownIcon, LockSimpleIcon, SignOutIcon } from "@/ui/icons";
import { NAV_GROUPS, isNavItemActive, railBadgeCount, type NavBadge } from "./nav";
import { EnvStrip } from "./EnvStrip";

type BadgeCounts = Record<NavBadge, number | undefined>;

/**
 * The two fields of the overview payload the rail cares about, described
 * structurally rather than imported: `AdminOverview` lives in
 * @lacasa/api-client and the rail should not break if a sibling field of it
 * changes shape. Everything is optional and re-checked at runtime because
 * this is cache data that may have been written by an older build.
 */
interface CachedOverviewCounts {
  users?: { total?: number };
  applications?: { pending?: number };
}

function numberOrUndefined(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function useBadgeCounts(): BadgeCounts {
  const { data, isLoading } = useQuery<CachedOverviewCounts>({
    queryKey: queryKeys.overview.summary(),
    // Never runs: `enabled: false` stops react-query fetching, while still
    // subscribing this component to the cache entry so the badges update the
    // moment the Overview screen's own useOverview() fills it in.
    queryFn: () => {
      throw new Error("Rail never fetches the overview — see this file's header");
    },
    enabled: false,
  });

  return {
    applications: railBadgeCount(numberOrUndefined(data?.applications?.pending), isLoading),
    users: railBadgeCount(numberOrUndefined(data?.users?.total), isLoading),
  };
}

export function Rail() {
  const { pathname } = useLocation();
  const badgeCounts = useBadgeCounts();

  return (
    <aside className="sticky top-0 flex h-screen w-rail flex-none flex-col border-r border-line bg-rail">
      <EnvStrip />

      <div className="flex items-center gap-2.5 border-b border-line px-[15px] pb-3 pt-[15px]">
        {/* A padlock, not a house: the marketplace's wordmark on a surface
            that can lock accounts would be the single most confusable thing
            on the screen. */}
        <span className="grid h-[27px] w-[27px] flex-none place-items-center rounded-nav bg-gradient-to-br from-[#ffc86b] via-acc to-[#d98a15] text-on-acc">
          <LockSimpleIcon size={14} weight="fill" />
        </span>
        <div className="min-w-0">
          <b className="block text-xl font-bold leading-tight tracking-snug">La Casa</b>
          <span className="block text-micro font-bold uppercase tracking-caps-widest text-acc">
            Control room
          </span>
        </div>
      </div>

      <nav className="flex-1 overflow-y-auto pb-3" aria-label="Control room">
        {NAV_GROUPS.map((group) => (
          <div key={group.label}>
            <div className="px-[15px] pb-1.5 pt-[15px] text-micro font-bold uppercase tracking-caps-widest text-faint">
              {group.label}
            </div>
            <div className="flex flex-col gap-px px-[9px]">
              {group.items.map((item) => {
                const active = isNavItemActive(pathname, item);
                const Icon = item.icon;
                const count = item.badge ? badgeCounts[item.badge] : undefined;
                // Amber only on the queue that is waiting for a decision —
                // "1,284 users" is scale, not a to-do (see nav.ts's NavBadge).
                const hot = item.badge === "applications" && count !== undefined && count > 0;
                return (
                  <Link
                    key={item.to}
                    to={item.to}
                    aria-current={active ? "page" : undefined}
                    className={clsx(
                      "flex items-center gap-2.5 rounded-nav px-2.5 py-[7px] text-body font-medium transition-colors",
                      active
                        ? "bg-acc-soft font-semibold text-acc"
                        : "text-ink-2 hover:bg-white/5 hover:text-ink",
                    )}
                  >
                    <Icon
                      size={15}
                      weight="fill"
                      className={clsx("flex-none", active ? "opacity-100" : "opacity-75")}
                    />
                    {item.label}
                    {count !== undefined ? (
                      <em
                        className={clsx(
                          "ml-auto rounded-full px-1.5 py-px text-mini font-bold not-italic",
                          hot ? "bg-acc text-on-acc" : "bg-white/10 text-ink-2",
                        )}
                      >
                        {formatCount(count)}
                      </em>
                    ) : null}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      <AccountFooter />
    </aside>
  );
}

/**
 * The signed-in admin, and the only reachable `logout()` in the app.
 *
 * Split out of Rail's render so its open/close state and its document-level
 * listeners don't re-run every time a badge count changes or the route moves.
 * The mockup draws this as an inert row with a sign-out glyph wired to
 * nothing; a surface that can lock other people's accounts cannot ship
 * without a way to end its own session.
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
    // logout() flips AuthProvider's status to 'anonymous' synchronously and
    // RequireAdmin already redirects on that — this navigate is a belt-and-
    // braces fallback for the instant between the state flip and the next
    // render, not a second source of truth for where /login lives.
    navigate("/login", { replace: true });
  }

  const name = user?.fullName ?? "";

  return (
    <div ref={rootRef} className="relative border-t border-line p-[11px]">
      <button
        type="button"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
        className="flex w-full items-center gap-2.5 rounded-control p-[7px] text-left transition-colors hover:bg-white/5 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc"
      >
        <span
          aria-hidden="true"
          className="grid h-7 w-7 flex-none place-items-center rounded-nav bg-gradient-to-br from-[#ffc86b] to-acc text-record font-bold text-on-acc"
        >
          {initials(name)}
        </span>
        <span className="min-w-0">
          <b className="block truncate text-small font-semibold leading-tight text-ink">{name}</b>
          {/* The signed-in email, not a "Full access · 2FA on" flourish: the
              mockup's second line claims a 2FA capability that does not
              exist, and the one fact worth stating here is WHICH admin
              account is about to act. */}
          <span className="block truncate text-mini text-muted">{user?.email ?? ""}</span>
        </span>
        <CaretDownIcon size={12} className="ml-auto flex-none text-muted" />
      </button>

      {open ? (
        <div
          role="menu"
          aria-label="Account"
          className="absolute bottom-[calc(100%-4px)] left-[11px] right-[11px] rounded-control border border-line bg-card p-1 shadow-panel"
        >
          <button
            type="button"
            role="menuitem"
            onClick={handleSignOut}
            className="flex w-full items-center gap-2 rounded-act px-2.5 py-2 text-left text-body text-ink transition-colors hover:bg-sunk focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc"
          >
            <SignOutIcon size={14} />
            Sign out
          </button>
        </div>
      ) : null}
    </div>
  );
}
