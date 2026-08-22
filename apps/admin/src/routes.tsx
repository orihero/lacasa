/**
 * src/routes — the control room's whole route table.
 *
 * /login is the only public route; everything else sits inside RequireAdmin +
 * AppShell. (App.tsx wires RouterProvider under QueryClientProvider and
 * AuthProvider; the MUI theme and PrimeReact providers are applied above App
 * in main.tsx.)
 *
 * REQUIREADMIN WRAPS THE SHELL, NOT EACH CHILD, so a non-admin gets
 * ForbiddenScreen INSTEAD OF the frame, never inside it — see lib/auth.tsx.
 *
 * EXACTLY FOUR SCREENS. The original mockup had seven: listing moderation, 3D
 * tour review and plans/premium are out of scope because no report/flag model,
 * no Tour model and no plan/billing model exists. They get NO PLACEHOLDER
 * ROUTE and no nav entry — an admin who types "/x-mod" must land on the honest
 * 404 below, not on a screen that implies moderation exists and is empty.
 *
 * The 404 lives INSIDE the authenticated shell, so a stale link keeps the
 * rail, the topbar and (critically) the environment strip visible.
 *
 * A browser router, not a hash router: these URLs get pasted into support
 * tickets.
 */
import { createBrowserRouter, Navigate } from "react-router-dom";
import { RequireAdmin } from "@/lib/auth";
import { AppShell } from "@/shell/AppShell";
import { LoginScreen } from "@/screens/login/LoginScreen";
import { NotFoundScreen } from "@/screens/NotFoundScreen";
import { OverviewScreen } from "@/screens/overview/OverviewScreen";
import { ApplicationsScreen } from "@/screens/applications/ApplicationsScreen";
import { UsersScreen } from "@/screens/users/UsersScreen";
import { AuditScreen } from "@/screens/audit/AuditScreen";

export const router = createBrowserRouter([
  { path: "/login", element: <LoginScreen /> },
  {
    path: "/",
    element: (
      <RequireAdmin>
        <AppShell />
      </RequireAdmin>
    ),
    children: [
      // `replace` so "/" never sits in history between the admin and the back
      // button.
      { index: true, element: <Navigate to="/overview" replace /> },
      { path: "overview", element: <OverviewScreen /> },
      { path: "applications", element: <ApplicationsScreen /> },
      { path: "users", element: <UsersScreen /> },
      { path: "audit", element: <AuditScreen /> },
      { path: "*", element: <NotFoundScreen /> },
    ],
  },
]);
