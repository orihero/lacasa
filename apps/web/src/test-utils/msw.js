// Shared RTL/component-test wiring for stubbing @lacasa/api-client's
// transport (the real axiosTransport, from src/lib/httpTransport.js) at the
// network boundary via msw, instead of mocking apiClient/api module by
// module. `server` is the single msw instance @lacasa/config-vitest/react's
// setup file already calls .listen()/.resetHandlers()/.close() on for every
// test in this workspace (wired via apps/web/vitest.config.js's
// reactPreset()) — importing it here (rather than creating a second
// instance) means `server.use(...)` in a test augments that same running
// server.
export { server } from "@lacasa/config-vitest/react/server";

import { resolveBaseUrl } from "../lib/httpTransport";

// The absolute origin every request @lacasa/api-client's axiosTransport (or
// the legacy `api` axios instance) actually sends to — same
// resolveBaseUrl(import.meta.env.VITE_API_URL) call both of them make, so
// msw handlers built from this always match regardless of whether a local
// apps/web/.env overrides VITE_API_URL.
export const API_BASE = resolveBaseUrl(import.meta.env.VITE_API_URL);
