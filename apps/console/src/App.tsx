/**
 * src/App — QueryClientProvider > AuthProvider > RouterProvider, in that
 * order: AuthProvider's mount-time `apiClient.auth.me()` check is a
 * react-query-free plain fetch today, but AuthProvider still needs to sit
 * inside QueryClientProvider so anything under RouterProvider that calls
 * useAuth() also has query context available.
 */
import { QueryClientProvider } from "@tanstack/react-query";
import { RouterProvider } from "react-router-dom";
import { AuthProvider } from "@/lib/auth";
import { queryClient } from "@/lib/queryClient";
import { router } from "./routes";

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </QueryClientProvider>
  );
}
