/**
 * src/shell/Topbar — the sticky bar over the records column: the current
 * page's title on the left, then the trailing control cluster. It is
 * apps/web's `<nav>` bar at console scale (`display: flex; justify-content:
 * space-between; align-items: center`), on the white panel rather than the
 * blush one.
 *
 * THIS IS THE PAGE'S ONE <h1>. Screens render no heading of their own — the
 * title lives here so it stays visible when a 200-row table scrolls, and a
 * screen that also rendered an `<h1>` would repeat the heading two lines below
 * itself (see PageHead, which deliberately has no `title` prop).
 *
 * The title comes from `titleForPath(t, useLocation().pathname)` — the same
 * function the rail's active row is derived from (./nav) — rather than from a
 * prop each screen passes, so a screen cannot render under the wrong heading.
 *
 * Two things deliberately absent:
 *
 *  · NO GLOBAL SEARCH BOX. There is no cross-entity search endpoint
 *    (`GET /api/admin/users?q=` searches users by name and email, and that is
 *    all), so a box offering "users, ads, UUIDs" would either 404 on a UUID or
 *    silently search only one of the three things it names. The Users screen
 *    owns its own `q` field against the endpoint that really exists.
 *  · NO LANGUAGE SWITCHER, unlike apps/web's navbar. The shell spec fixes this
 *    cluster to exactly two disabled placeholders, and this is the highest-
 *    stakes surface in the monorepo to be adding controls to. Language still
 *    follows the operator: src/i18n.ts keeps apps/web's detection order and
 *    cookie cache, so switching language in the console carries over here.
 */
import { useLocation } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { IconButton } from "@/ui/IconButton";
import { Bell, Settings } from "@/ui/icons";
import { titleForPath } from "./nav";
import "./topbar.scss";

export function Topbar() {
  const { pathname } = useLocation();
  const { t } = useTranslation();

  return (
    <header className="admin-topbar">
      <h1 className="admin-topbar__title">{titleForPath(t, pathname)}</h1>

      <div className="admin-topbar__tools">
        {/*
          Both controls are inert today and neither carries a signal it cannot
          back up — in particular THE BELL HAS NO UNREAD DOT. There is no
          notifications model behind this surface, so a pip would be a
          fabricated "something needs you" on the one screen whose entire job
          is telling an admin what needs them. They stay as disabled
          placeholders rather than being deleted so the bar keeps its geometry
          when either is wired up.
        */}
        <IconButton icon={Bell} label={t("notificationsUnavailable")} disabled />
        <IconButton icon={Settings} label={t("settingsUnavailable")} disabled />
      </div>
    </header>
  );
}
