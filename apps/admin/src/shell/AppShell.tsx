/**
 * src/shell/AppShell — the one page frame every admin route renders inside
 * (routes.tsx), built out of apps/web's signed-in console frame:
 *
 *     .agent-content   grey #f5f6fa gutter, 10px padding, 10px gap, flex row
 *       .sidebar       white panel, the nav
 *       .content-list  white panel, the records
 *
 * Those class names are apps/web's and are kept on purpose — "looks like
 * apps/web" means reusing its vocabulary rather than inventing
 * `admin-page-shell` next to it (web-design-contract.md §6).
 *
 * Landmarks, all load-bearing and unchanged by the restyle: the nav is an
 * `<aside>` holding `<nav aria-label>` (Rail), the title bar is a `<header>`
 * carrying the page's one `<h1>` (Topbar), and the routed `Outlet` sits inside
 * `<main>`.
 *
 * NO MAX CONTENT WIDTH — apps/web's `.layout` caps itself at 1366px, but that
 * cap is for a marketing column; the users table here has nine columns of
 * records and wants every pixel of a wide monitor. What makes that safe is the
 * records column being allowed to SHRINK (`min-width: 0` in the SCSS): without
 * it a wide table pushes the whole page sideways and takes the rail and the
 * topbar with it, instead of scrolling inside its own container.
 */
import { Outlet } from "react-router-dom";
import { Rail } from "./Rail";
import { Topbar } from "./Topbar";
import "./appShell.scss";

export function AppShell() {
  return (
    <div className="agent-content admin-shell">
      <Rail />
      <div className="content-list admin-records">
        <Topbar />
        <main className="admin-main">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
