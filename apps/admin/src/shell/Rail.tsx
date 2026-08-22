/**
 * src/shell/Rail — the control room's navigation, wearing apps/web's sidebar.
 *
 * The deleted build drew a 224px dark rail. This one is the console's
 * `.sidebar`: a white panel on the `#f5f6fa` gutter, a `1px solid #dddd`
 * divider under the identity block, `.menu-list` rows at `padding: 10px 20px`
 * with a 10px icon gap, and `.active-menu` — the accent-yellow background —
 * marking where you are. apps/web's own sidebar declares `width: 300px;
 * min-width: 250px`; this takes the narrow end of that range because the users
 * table has nine columns of records and wants the pixels.
 *
 * Two things the restyle does NOT change, because they are behaviour:
 *
 *  · apps/web's nav rows are `<span onClick={() => navigate(...)}>`. These are
 *    real `<Link>`s inside a `<nav aria-label>`, carrying `aria-current="page"`
 *    — a control room whose nav cannot be reached by keyboard or announced by
 *    a screen reader is not a restyle of anything.
 *  · Active state is computed from ./nav's `isNavItemActive`, not from
 *    react-router's <NavLink> and not from the URL's last segment the way
 *    apps/web does it, so the rail and the topbar's page title come from one
 *    function and cannot disagree.
 *
 * THE BADGES READ THE CACHE, THEY DO NOT FETCH.
 * The two counts the rail shows are exactly two of the numbers
 * `GET /api/admin/overview` already returns, and /overview is this app's
 * landing route — so the rail subscribes to that query's cache entry
 * (`enabled: false`: subscribe to updates, never trigger a request) instead of
 * issuing a second call of its own on every route change. Three consequences,
 * all deliberate:
 *   · zero extra requests, and no chance of the rail's "Pending 3" disagreeing
 *     with the overview's "Pending 3" because they were fetched a second apart;
 *   · the badges are empty until something has loaded the overview, which
 *     nav.ts's railBadgeCount already treats as the honest state — an unknown
 *     count renders as no badge, never as 0;
 *   · the rail does not depend on the overview screen's data hook, only on the
 *     shared query key, which is the contract between them.
 */
import { useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useQuery } from "@tanstack/react-query";
import { useAuth } from "@/lib/auth";
import { formatCount, initials } from "@/lib/format";
import { queryKeys } from "@/lib/queryKeys";
import { ChevronDown, Lock, LogOut } from "@/ui/icons";
import { EnvStrip } from "./EnvStrip";
import { NAV_GROUPS, isNavItemActive, railBadgeCount, type NavBadge } from "./nav";
import "./rail.scss";

type BadgeCounts = Record<NavBadge, number | undefined>;

/**
 * The two fields of the overview payload the rail cares about, described
 * STRUCTURALLY rather than imported: `AdminOverview` lives in
 * @lacasa/api-client and the rail should not break if a sibling field of it
 * changes shape. Everything is optional and re-checked at runtime because this
 * is cache data that may have been written by an older build.
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
    // Never runs. `enabled: false` stops react-query fetching while still
    // subscribing this component to the cache entry, so the badges update the
    // moment the overview screen's own query fills it in.
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
  const { t } = useTranslation();
  const badgeCounts = useBadgeCounts();

  return (
    <aside className="sidebar admin-rail">
      <EnvStrip />

      <div className="admin-rail__brand">
        {/* A padlock, not the marketplace's house glyph: a wordmark that reads
            as the buyer-facing app, on a surface that can lock accounts, would
            be the single most confusable thing on the screen. */}
        <span className="admin-rail__mark" aria-hidden="true">
          <Lock size={14} />
        </span>
        <span className="admin-rail__wordmark">
          <b>{t("appName")}</b>
          <small>{t("controlRoom")}</small>
        </span>
      </div>

      <nav className="menu-list admin-rail__nav" aria-label={t("controlRoom")}>
        {NAV_GROUPS.map((group) => (
          <div className="admin-rail__group" key={group.labelKey}>
            <div className="admin-rail__group-label">{t(group.labelKey)}</div>
            {group.items.map((item) => {
              const active = isNavItemActive(pathname, item);
              const Icon = item.icon;
              const count = item.badge ? badgeCounts[item.badge] : undefined;
              // Hot only on the queue that is waiting for a decision —
              // "1,284 users" is scale, not a to-do (see nav.ts's NavBadge).
              const hot = item.badge === "applications" && count !== undefined && count > 0;
              return (
                <Link
                  key={item.to}
                  to={item.to}
                  aria-current={active ? "page" : undefined}
                  className={active ? "admin-rail__item active-menu" : "admin-rail__item"}
                >
                  <Icon size={15} aria-hidden="true" />
                  <span className="admin-rail__item-label">{t(item.labelKey)}</span>
                  {count !== undefined ? (
                    <em
                      className={
                        hot ? "admin-rail__badge admin-rail__badge--hot" : "admin-rail__badge"
                      }
                    >
                      {formatCount(count)}
                    </em>
                  ) : null}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      <AccountFooter />
    </aside>
  );
}

/**
 * The signed-in admin, and THE ONLY REACHABLE logout() IN THE SIGNED-IN APP.
 * A surface that can lock other people's accounts cannot ship without a way to
 * end its own session.
 *
 * Split out of Rail's render so its open/close state and its document-level
 * listeners do not re-run every time a badge count changes or the route moves.
 *
 * It states the full name and the email, and nothing else. apps/web's sidebar
 * puts a phone number here; the fact worth stating on this surface is WHICH
 * admin account is about to act.
 */
function AccountFooter() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  // Document-level listeners exist only while the menu is open.
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
    // logout() flips AuthProvider's status to "anonymous" synchronously and
    // RequireAdmin already redirects on that — this navigate is belt-and-
    // braces for the instant between the state flip and the next render, not a
    // second source of truth for where /login lives.
    navigate("/login", { replace: true });
  }

  const name = user?.fullName ?? "";

  return (
    <div className="admin-rail__account" ref={rootRef}>
      <button
        type="button"
        className="admin-rail__account-button"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={() => setOpen((current) => !current)}
      >
        {/* aria-hidden: the button's accessible name is the name and email
            beside it, and an initials chip announced as well would just read
            the same person twice. */}
        <span className="admin-rail__avatar" aria-hidden="true">
          {initials(name)}
        </span>
        <span className="admin-rail__identity">
          <b>{name}</b>
          <small>{user?.email ?? ""}</small>
        </span>
        <ChevronDown size={12} aria-hidden="true" />
      </button>

      {open ? (
        <div className="admin-rail__menu" role="menu" aria-label={t("account")}>
          <button
            type="button"
            role="menuitem"
            className="admin-rail__menu-item"
            onClick={handleSignOut}
          >
            <LogOut size={14} aria-hidden="true" />
            {t("signOut")}
          </button>
        </div>
      ) : null}
    </div>
  );
}
