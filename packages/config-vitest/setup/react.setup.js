// Shared jsdom test setup: jest-dom matchers, an msw server every
// consumer's tests can add handlers to via `server.use(...)`, and RTL's
// DOM cleanup between tests. The cleanup call matters here specifically:
// @testing-library/react only auto-registers it against a *global*
// `afterEach` (the way Jest exposes one), and this workspace's vitest
// config doesn't set `test.globals: true` — without this, every rendered
// component would stay mounted into the next test's DOM.
import '@testing-library/jest-dom/vitest';
import { afterAll, afterEach, beforeAll } from 'vitest';
import { cleanup } from '@testing-library/react';
import { setupServer } from 'msw/node';

export const server = setupServer();

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }));
afterEach(() => server.resetHandlers());
afterEach(() => cleanup());
afterAll(() => server.close());
