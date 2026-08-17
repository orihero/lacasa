/**
 * src/test/setup — appended to @lacasa/config-vitest/react's own setup file
 * (see vitest.config.ts), not a replacement for it.
 *
 * @testing-library/react normally sets this flag inside its own `render()`,
 * but this app can't use that render — src/test/render.tsx explains the React
 * 18/19 hoisting conflict that forces a hand-rolled `createRoot` + `act`
 * wrapper instead — so nothing else sets it.
 *
 * With the flag unset, React 19's `act()` doesn't take its synchronous
 * test-flush path; work goes through the real scheduler and React warns "code
 * that causes React state updates should be wrapped into act(...)" on every
 * render despite each one already being wrapped — that warning fires
 * precisely when IS_REACT_ACT_ENVIRONMENT is falsy. Setting it makes `act()`
 * flush renders and effects synchronously, which every test here assumes.
 */
declare global {
  // `var` (not let/const) is what puts the declaration on globalThis.
  var IS_REACT_ACT_ENVIRONMENT: boolean;
}

globalThis.IS_REACT_ACT_ENVIRONMENT = true;

export {};
