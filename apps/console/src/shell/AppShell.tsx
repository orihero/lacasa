/**
 * src/shell/AppShell — the one page frame every authenticated route renders
 * inside (routes.tsx): the 1480px shell, the topbar, and the rail + main
 * `.body-row` with the prototype's exact 26px gap
 * (mockups/f/f-console.src.html / f-components.css `.body-row`).
 */
import { Outlet } from "react-router-dom";
import { Rail } from "./Rail";
import { Topbar } from "./Topbar";

export function AppShell() {
  return (
    <div className="mx-auto max-w-shell px-[28px] pb-12 pt-[22px]">
      <Topbar />
      <div className="flex items-start gap-[26px]">
        <Rail />
        <main className="min-w-0 flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
