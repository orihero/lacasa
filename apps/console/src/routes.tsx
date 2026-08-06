/**
 * src/routes — the console's whole route table. /login is the only public
 * route; everything else sits inside RequireAuth + AppShell (App.tsx wires
 * RouterProvider under QueryClientProvider + AuthProvider).
 *
 * /ads/new and /ads/:id/edit both render ListingEditorScreen — create and
 * edit are the same screen, prefilled or not (mockups/f/PLAN.md §3.3). See
 * shell/nav.ts's isNavItemActive for how the rail keeps its "Listing
 * editor" row active across both.
 */
import { createBrowserRouter, Navigate } from "react-router-dom";
import { AppShell } from "@/shell/AppShell";
import { RequireAuth } from "@/lib/auth";
import { LoginScreen } from "@/screens/login/LoginScreen";
import { NotFoundScreen } from "@/screens/NotFoundScreen";
import { StatisticsScreen } from "@/screens/statistics/StatisticsScreen";
import { MyAdsScreen } from "@/screens/myAds/MyAdsScreen";
import { ListingEditorScreen } from "@/screens/listingEditor/ListingEditorScreen";
import { PublishStatusScreen } from "@/screens/publishStatus/PublishStatusScreen";
import { LeadsScreen } from "@/screens/leads/LeadsScreen";
import { KanbanScreen } from "@/screens/kanban/KanbanScreen";
import { CoworkersScreen } from "@/screens/coworkers/CoworkersScreen";
import { ConnectedAccountsScreen } from "@/screens/connectedAccounts/ConnectedAccountsScreen";

export const router = createBrowserRouter([
  { path: "/login", element: <LoginScreen /> },
  {
    path: "/",
    element: (
      <RequireAuth>
        <AppShell />
      </RequireAuth>
    ),
    children: [
      { index: true, element: <Navigate to="/statistics" replace /> },
      { path: "statistics", element: <StatisticsScreen /> },
      { path: "ads", element: <MyAdsScreen /> },
      { path: "ads/new", element: <ListingEditorScreen /> },
      { path: "ads/:id/edit", element: <ListingEditorScreen /> },
      { path: "publish", element: <PublishStatusScreen /> },
      { path: "leads", element: <LeadsScreen /> },
      { path: "leads/kanban", element: <KanbanScreen /> },
      { path: "coworkers", element: <CoworkersScreen /> },
      { path: "accounts", element: <ConnectedAccountsScreen /> },
      { path: "*", element: <NotFoundScreen /> },
    ],
  },
]);
