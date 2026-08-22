/**
 * src/test/setup — appended to @lacasa/config-vitest/react's own setup file
 * (see vitest.config.ts's `setupFiles`), not a replacement for it. The shared
 * preset already wires jest-dom's matchers, the msw server and RTL's cleanup.
 *
 * What it does NOT wire is the two browser APIs MUI reaches for the moment it
 * renders, neither of which jsdom implements:
 *
 *  · `window.matchMedia` — every MUI component that consults a breakpoint
 *    (useMediaQuery, and the responsive `sx` props the shell uses) calls it on
 *    mount and throws "matchMedia is not a function" without it. The stub
 *    always answers "does not match", i.e. the widest layout, which is the one
 *    this desktop-only surface is designed against.
 *  · `ResizeObserver` — MUI's Popper/Select and recharts' responsive container
 *    observe their own box. jsdom has no layout engine, so a no-op observer is
 *    the honest stub: it never fires, and nothing under test depends on it
 *    firing.
 *
 * The React-19-era `IS_REACT_ACT_ENVIRONMENT` flag the previous build set here
 * is gone. It existed because that app could not use @testing-library/react's
 * own `render()` (a React 18/19 hoisting conflict forced a hand-rolled
 * createRoot + act wrapper, and nothing else set the flag). This rebuild is on
 * React 18 with the workspace's single hoisted copy, so RTL's `render()` works
 * normally and sets the flag itself.
 */
import { vi } from "vitest";

if (typeof window !== "undefined" && typeof window.matchMedia !== "function") {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    value: (query: string): MediaQueryList =>
      ({
        matches: false,
        media: query,
        onchange: null,
        addListener: vi.fn(), // deprecated, but MUI still feature-detects it
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
      }) as unknown as MediaQueryList,
  });
}

if (typeof globalThis.ResizeObserver === "undefined") {
  globalThis.ResizeObserver = class ResizeObserverStub {
    observe(): void {}
    unobserve(): void {}
    disconnect(): void {}
  } as unknown as typeof ResizeObserver;
}
