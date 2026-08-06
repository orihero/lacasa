/**
 * src/test/render — a minimal, drop-in-ish stand-in for @testing-library/
 * react's own `render()`, needed only because of a workspace-wide npm
 * hoisting conflict, not anything about the components under test:
 *
 * apps/web pins React 18 and claims the hoisted copy at the repo root
 * (`node_modules/react-dom@18.3.1`); apps/console pins React 19.2.3, kept as
 * its own nested copy (`apps/console/node_modules/react-dom@19.2.3`) because
 * of that conflict. `@testing-library/react` itself has no such conflict, so
 * npm hoists *it* to the repo root too — which means its own internal
 * `require("react-dom/client")` resolves relative to *its* location (the
 * root) and picks up 18.3.1, while every file under `apps/console/src/`
 * (including this one) resolves the same bare specifier relative to *its*
 * location and correctly gets 19.2.3. Two different React-DOM instances then
 * try to reconcile the same JSX element and React 19's element `$$typeof`
 * tag isn't shared across them, so mounting anything through
 * `@testing-library/react`'s `render()` throws "Objects are not valid as a
 * React child" — confirmed by direct diagnostic (a bare `render(<div/>)`
 * with no app code involved fails identically).
 *
 * The real fix is a Vite `resolve.dedupe` in vite.config.ts/vitest.config.ts
 * (already present there — see those files) plus the equivalent for
 * `@testing-library/react`'s own resolution, which dedupe doesn't reach
 * since it isn't part of this app's own module graph the way react/react-dom
 * imports are. Until @testing-library/react is nested locally too, every
 * screen/component test mounts through `react-dom/client` resolved the same
 * (correct) way every component file already resolves it, and queries
 * through `@testing-library/dom`'s `screen` — which only touches real DOM
 * nodes and has no react-dom dependency to get duplicated in the first
 * place.
 *
 * Originally written five times over (once per screen folder plus
 * src/ui/__tests__) because no screen agent could import across another
 * screen's folder boundary under the FOUNDATION CONTRACT's per-folder
 * ownership. Promoted here now that one agent owns the whole app — every
 * folder's own `__tests__/testUtils.tsx` is a one-line re-export of this.
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
