/**
 * src/routes — the control room's whole route table. /login is the only
 * public route; everything else sits inside RequireAdmin + AppShell (App.tsx
 * wires RouterProvider under QueryClientProvider + AuthProvider).
 *
 * RequireAdmin wraps the shell rather than each child, so a non-admin gets
 * ForbiddenScreen INSTEAD OF the frame, never inside it — see lib/auth.tsx.
 *
 * Four screens. The mockup's listing moderation, 3D tour review and plans
 * surfaces are out of scope (no report, tour or billing model exists), and
 * they get no placeholder route: an admin who reaches "/x-mod" should land on
 * the honest 404 below, not on a screen that implies moderation is coming.
 */
import { createBrowserRouter, Navigate } from "react-router-dom";
import { AppShell } from "@/shell/AppShell";
import { RequireAdmin } from "@/lib/auth";
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
      { index: true, element: <Navigate to="/overview" replace /> },
      { path: "overview", element: <OverviewScreen /> },
      { path: "applications", element: <ApplicationsScreen /> },
      { path: "users", element: <UsersScreen /> },
      { path: "audit", element: <AuditScreen /> },
      { path: "*", element: <NotFoundScreen /> },
    ],
  },
]);
