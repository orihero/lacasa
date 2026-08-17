/**
 * src/test/render — a minimal stand-in for @testing-library/react's own
 * `render()`, needed because of a workspace-wide npm hoisting conflict, not
 * because of anything about the components under test. Ported verbatim in
 * spirit from apps/console/src/test/render.tsx, whose root-cause writeup
 * applies here unchanged:
 *
 * apps/web pins React 18 and claims the hoisted copy at the repo root
 * (`node_modules/react-dom@18.3.1`); this app pins React 19.2.3, kept as its
 * own nested copy (`apps/admin/node_modules/react-dom@19.2.3`) because of
 * that conflict. `@testing-library/react` itself has no such conflict, so npm
 * hoists *it* to the repo root too — which means its own internal
 * `require("react-dom/client")` resolves relative to *its* location (the
 * root) and picks up 18.3.1, while every file under `apps/admin/src/`
 * (including this one) resolves the same bare specifier relative to *its*
 * location and correctly gets 19.2.3. Two different React-DOM instances then
 * try to reconcile the same JSX element and React 19's element `$$typeof` tag
 * isn't shared across them, so mounting anything through
 * `@testing-library/react`'s `render()` throws "Objects are not valid as a
 * React child".
 *
 * The Vite-side half of the fix (`resolve.dedupe`) is already in
 * vite.config.ts and vitest.config.ts, but dedupe doesn't reach
 * @testing-library/react's own resolution — that package isn't part of this
 * app's module graph the way react/react-dom imports are. So every component
 * test mounts through `react-dom/client` resolved the same (correct) way
 * every component file already resolves it, and queries through
 * `@testing-library/dom`'s `screen`, which only touches real DOM nodes and
 * has no react-dom dependency to get duplicated in the first place.
 */
import type { ReactElement } from "react";
import { act } from "react";
import { createRoot, type Root } from "react-dom/client";
import { afterEach } from "vitest";

interface Mounted {
  root: Root;
  container: HTMLElement;
}

const mounted = new Set<Mounted>();

export function render(ui: ReactElement) {
  const container = document.createElement("div");
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => {
    root.render(ui);
  });
  const entry: Mounted = { root, container };
  mounted.add(entry);

  return {
    container,
    rerender(next: ReactElement) {
      act(() => {
        root.render(next);
      });
    },
    unmount() {
      act(() => {
        root.unmount();
      });
      container.remove();
      mounted.delete(entry);
    },
  };
}

// Mirrors @testing-library/react's own auto-cleanup so tests never leak a
// mounted tree into the next one, without depending on its (mis-resolved)
// internal render/cleanup pairing.
afterEach(() => {
  for (const entry of mounted) {
    act(() => {
      entry.root.unmount();
    });
    entry.container.remove();
  }
  mounted.clear();
});
