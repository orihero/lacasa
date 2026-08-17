/**
 * src/shell/AppShell — the one page frame every admin route renders inside
 * (routes.tsx): the rail on the left, and a records column that owns its own
 * scrolling under a sticky topbar.
 *
 * No max-width. apps/console centres its content at 1480px because a property
 * card stops being readable past that; the users table here has nine columns
 * of records and wants every pixel of a wide monitor. The `min-w-0` on the
 * column is what makes that safe — without it a wide table would push the
 * grid instead of scrolling inside its own container (see ui/Table.tsx).
 */
import { Outlet } from "react-router-dom";
import { Rail } from "./Rail";
import { Topbar } from "./Topbar";

export function AppShell() {
  return (
    <div className="flex min-h-screen">
      <Rail />
      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar />
        <main className="flex-1 p-[18px]">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
