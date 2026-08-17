/**
 * src/App — QueryClientProvider > AuthProvider > RouterProvider, in that
 * order: AuthProvider's mount-time `apiClient.auth.me()` check is a
 * react-query-free plain fetch today, but AuthProvider still has to sit
 * inside QueryClientProvider so everything under RouterProvider that calls
 * useAuth() also has query context available — the Rail reads the overview
 * cache, and it renders inside the tree AuthProvider gates.
 *
 * ErrorBoundary sits OUTSIDE all three. A provider that throws while mounting
 * has to be caught by something above it, and the fallback deliberately needs
 * no query client, no session and no router to draw itself — otherwise the
 * handler for a crash can crash.
 */
import { QueryClientProvider } from "@tanstack/react-query";
import { RouterProvider } from "react-router-dom";
import { AuthProvider } from "@/lib/auth";
import { queryClient } from "@/lib/queryClient";
import { ErrorBoundary } from "@/shell/ErrorBoundary";
import { router } from "./routes";

export function App() {
  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <RouterProvider router={router} />
        </AuthProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  );
}
