/**
 * src/test/render — the provider wrapper every screen test mounts through.
 *
 * apps/web has no custom `render()` at all (web-design-contract.md §14.1): its
 * components read zustand singletons and need at most a `<MemoryRouter>`. This
 * app needs five things in the tree before a screen will draw — the router,
 * the query client, the MUI theme, i18next and the auth context — and
 * re-assembling that stack in every suite is how one of them quietly goes
 * missing and a test passes against MUI's factory defaults.
 *
 * The old build's render helper was a hand-rolled `createRoot` + `act()` pair,
 * needed because a React 18/19 hoisting conflict made
 * `@testing-library/react`'s own `render()` mount through the wrong react-dom.
 * That conflict is gone: this app is on React 18, pinned to the same range as
 * apps/web, and there is exactly one React in the workspace. So this is RTL's
 * real `render()` with a `wrapper`, and RTL's own auto-cleanup (wired by
 * @lacasa/config-vitest/react's setup file) applies unchanged.
 *
 * NOTES FOR SCREEN SUITES
 *
 *  · A FRESH QUERY CLIENT PER RENDER. Retries are off — a test asserting an
 *    error state should not wait out two retries — and `staleTime` stays 0,
 *    matching the app's real policy (lib/queryClient.ts). Pass your own client
 *    when a test needs to seed the cache (`client.setQueryData(...)`) before
 *    the first render; the one this returns is also handed back so you can
 *    seed or inspect it afterwards.
 *  · `withAuth` mounts the REAL AuthProvider, which performs a mount-time
 *    GET /auth/me. Give it a token and an msw handler, or mock
 *    `@/lib/apiClient`. A suite that would rather stub the session outright
 *    should `vi.mock("@/lib/auth", ...)` and pass `withAuth: false`, so the
 *    session is a fixture rather than a network dance.
 *  · i18n is imported for its side effect here, so `i18n.t("key")` in a test
 *    resolves the same string the component rendered — which is how apps/web's
 *    own tests query translated UI.
 */
import type { ReactElement, ReactNode } from "react";
import { render, type RenderOptions, type RenderResult } from "@testing-library/react";
import { ThemeProvider } from "@mui/material/styles";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { MemoryRouter } from "react-router-dom";
import { AuthProvider } from "@/lib/auth";
import { theme } from "@/theme";
import "@/i18n";

export interface RenderWithProvidersOptions extends Omit<RenderOptions, "wrapper"> {
  /** Initial URL. Shorthand for `initialEntries: [route]`. Default "/". */
  route?: string;
  /** Full history stack, when a test needs more than one entry. */
  initialEntries?: string[];
  /** Bring your own client, e.g. to seed the cache before the first render. */
  queryClient?: QueryClient;
  /** Mount the real AuthProvider. Default true. */
  withAuth?: boolean;
}

export function createTestQueryClient(): QueryClient {
  return new QueryClient({
    defaultOptions: {
      // No retries in tests: the app retries twice on a non-401/403, and a
      // suite asserting an ErrorState should not have to wait for that.
      queries: { retry: false, staleTime: 0 },
      mutations: { retry: false },
    },
  });
}

export function renderWithProviders(
  ui: ReactElement,
  {
    route = "/",
    initialEntries,
    queryClient = createTestQueryClient(),
    withAuth = true,
    ...options
  }: RenderWithProvidersOptions = {},
): RenderResult & { queryClient: QueryClient } {
  function Wrapper({ children }: { children: ReactNode }) {
    const routed = (
      <MemoryRouter initialEntries={initialEntries ?? [route]}>{children}</MemoryRouter>
    );

    return (
      <ThemeProvider theme={theme}>
        <QueryClientProvider client={queryClient}>
          {withAuth ? <AuthProvider>{routed}</AuthProvider> : routed}
        </QueryClientProvider>
      </ThemeProvider>
    );
  }

  return { ...render(ui, { wrapper: Wrapper, ...options }), queryClient };
}
