/**
 * src/main — the mount point.
 *
 * Three things happen here that cannot happen inside App:
 *
 *  1. `./index.scss` is imported for its side effect. It carries the same
 *     universal reset apps/web uses (`* { font-family: "Plus Jakarta Sans" }`),
 *     which is what stops MUI rendering the whole control room in Roboto.
 *  2. `./i18n` is imported for its side effect, exactly as apps/web's main.jsx
 *     does — i18next has to be initialised before the first component calls
 *     useTranslation(), and an import is the only ordering guarantee there is.
 *  3. The MUI theme and PrimeReact providers wrap App rather than sitting
 *     inside it. App owns the provider stack whose order shell.md §0 makes
 *     load-bearing (ErrorBoundary outermost, then QueryClientProvider, then
 *     AuthProvider, then RouterProvider) — and the error boundary is the
 *     outermost of THOSE precisely so its fallback can be drawn with no query
 *     client, no session and no router. The theme is the one thing the
 *     fallback still needs, so it belongs above the boundary, not below it.
 *
 * A missing #root throws rather than silently doing nothing: a blank control
 * room is indistinguishable from an empty queue, which is the failure mode
 * this whole app is built to avoid.
 */
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { ThemeProvider } from "@mui/material/styles";
import { PrimeReactProvider } from "primereact/api";
import { App } from "./App";
import { theme } from "./theme";
import "./i18n";
import "./index.scss";

const rootElement = document.getElementById("root");
if (!rootElement) {
  throw new Error("#root element not found — check index.html");
}

createRoot(rootElement).render(
  <StrictMode>
    <ThemeProvider theme={theme}>
      <PrimeReactProvider>
        <App />
      </PrimeReactProvider>
    </ThemeProvider>
  </StrictMode>,
);
