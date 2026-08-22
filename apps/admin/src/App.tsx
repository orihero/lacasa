/**
 * src/App — the provider stack, and the order is load-bearing:
 *
 *   ErrorBoundary  →  QueryClientProvider  →  AuthProvider  →  RouterProvider
 *
 *  · ERRORBOUNDARY IS OUTERMOST. A provider that throws while mounting has to
 *    be caught by something above it, and the fallback deliberately needs no
 *    query client, no session and no router to draw itself — otherwise the
 *    handler for a crash can itself crash.
 *  · AuthProvider sits INSIDE QueryClientProvider. Its mount-time
 *    `apiClient.auth.me()` check is a react-query-free plain fetch today, but
 *    everything under the router that calls `useAuth()` also needs query
 *    context: the Rail reads the overview cache, and it renders inside the
 *    tree AuthProvider gates.
 *
 * WHAT IS NOT HERE, AND WHY. main.tsx already applies `ThemeProvider` and
 * `PrimeReactProvider` above this component, deliberately: the theme is the
 * one thing the crash fallback still needs, so it has to sit ABOVE the error
 * boundary rather than below it. Re-adding either here would be a second,
 * redundant copy of a provider that is already in the tree.
 *
 * There is no `CssBaseline` either. apps/web has no MUI theme at all and beats
 * MUI into shape with a universal CSS reset (`* { font-family: "Plus Jakarta
 * Sans" }`), which src/index.scss ports verbatim; CssBaseline would be a
 * second, competing reset from a library the house style deliberately does not
 * lean on.
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
