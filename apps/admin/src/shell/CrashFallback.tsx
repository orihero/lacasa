/**
 * src/shell/CrashFallback — what ./ErrorBoundary renders once a screen has
 * thrown.
 *
 * It is a separate module from the boundary for one reason: the boundary has
 * to be a class (`getDerivedStateFromError` / `componentDidCatch` have no hook
 * equivalent) and a class cannot call `useTranslation()`. react-i18next
 * resolves against the module-level i18next instance (src/i18n.ts) rather than
 * a React provider, so this still draws with no query client, no session and
 * no router above it — which is the whole reason the boundary sits outside all
 * three.
 *
 * Two things this screen must keep:
 *
 *  · THE ENVIRONMENT STRIP, because an operator reading a crash needs to know
 *    which database the tab was pointed at before they act on it. It is also
 *    the ONLY role="status" here — the boundary's test selects it with
 *    getByRole("status"), which throws on multiple matches — so nothing else
 *    on this screen may claim that role.
 *  · THE ERROR MESSAGE, verbatim and in monospace. It is what identifies the
 *    bug, and swallowing it on the screen that approves accounts costs someone
 *    their afternoon.
 *
 * The button reloads rather than clearing the boundary's state back to null:
 * whatever data produced the bad render is still in the react-query cache, so
 * re-rendering the same tree would just throw again.
 */
import { useTranslation } from "react-i18next";
import { EnvStrip } from "./EnvStrip";
import "./errorBoundary.scss";

export function CrashFallback({
  message,
  onReload,
}: {
  message: string;
  onReload: () => void;
}) {
  const { t } = useTranslation();

  return (
    <div className="crash">
      <EnvStrip />

      <div className="crash__body">
        <p className="crash__eyebrow">{t("crashEyebrow")}</p>
        <h1 className="crash__title">{t("crashTitle")}</h1>
        <p className="crash__text">{t("crashBody")}</p>
        <pre className="crash__message">{message}</pre>
        <div>
          <button type="button" className="crash__reload" onClick={onReload}>
            {t("reloadControlRoom")}
          </button>
        </div>
      </div>
    </div>
  );
}
