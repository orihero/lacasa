/**
 * src/shell/EnvStrip — the permanent environment strip: the first thing in
 * the rail, above the wordmark, on every single screen including /login, the
 * forbidden screen and the crash screen. Not dismissible, not collapsible,
 * never scrolls away.
 *
 * It answers one question — WHICH DATABASE DOES THIS TAB WRITE TO? — and the
 * failure it exists to prevent is an admin with a local tab and a production
 * tab open side by side approving an application in the wrong one. By the time
 * that mistake is visible in the data it has already promoted the wrong
 * account.
 *
 * The strip reads `import.meta.env` and nothing else. It deliberately does NOT
 * ask the API which environment it is: that answer would arrive after first
 * paint, and a strip that says the wrong thing for 200ms is worse than one
 * derived synchronously from the same variable the requests themselves are
 * built from (`VITE_API_URL`, see lib/apiClient.ts).
 *
 * TONE IS DERIVED, NOT CONFIGURED. Anything that is not localhost renders in
 * apps/web's destructive red, because a deployment can be misconfigured but a
 * hostname cannot lie about where the bytes are going. An operator can *label*
 * the environment (`VITE_ENV_NAME`, `VITE_DB_LABEL`) but cannot label a remote
 * database as safe.
 *
 * The local treatment is apps/web's `.user-role` chip verbatim — a small caps
 * badge in accent yellow with black text, the same idiom the console already
 * uses to state a standing fact about who you are looking at.
 */
import { useTranslation } from "react-i18next";
import { API_BASE_URL } from "@/lib/apiClient";
import type { Translate } from "@/lib/labels";
import { CircleAlert, Database } from "@/ui/icons";
import "./envStrip.scss";

export interface EnvDescription {
  /** "Production", "Staging", "Local" — the loud half. */
  name: string;
  /** The database or host this session writes to — the specific half. */
  target: string;
  /** Local development, i.e. mistakes here are cheap. */
  isLocal: boolean;
}

const LOCAL_HOSTS = new Set(["localhost", "127.0.0.1", "[::1]", "0.0.0.0"]);

/**
 * Pure, so it can be tested against every combination of "an operator labelled
 * it" and "we had to derive it" without rendering anything. `t` comes first,
 * matching every resolver in @/lib/labels.
 *
 * An unparseable base URL is treated as REMOTE, not local: the whole point of
 * the strip is that it fails loud. A relative `/api` base (a same-origin
 * deployment) is the one case that legitimately has no host of its own, and it
 * resolves against the page's own origin, which the caller passes as `origin`.
 */
// Co-located with the only component that calls it, and with the comment block
// that explains its policy, rather than split into its own module purely to
// satisfy fast refresh.
// eslint-disable-next-line react-refresh/only-export-components
export function describeEnvironment(
  t: Translate,
  {
    apiBaseUrl,
    origin,
    envName,
    dbLabel,
  }: {
    apiBaseUrl: string;
    origin?: string;
    envName?: string;
    dbLabel?: string;
  },
): EnvDescription {
  let host: string | null = null;
  try {
    host = new URL(apiBaseUrl, origin).hostname;
  } catch {
    host = null;
  }

  const isLocal = host !== null && LOCAL_HOSTS.has(host);

  return {
    name: envName?.trim() || t(isLocal ? "environmentLocal" : "environmentRemote"),
    // The HOST, not the full URL: "lacasa-prod.example.com" is what an
    // operator recognises, and the "/api" suffix every base URL shares is
    // noise in a strip this small.
    target: dbLabel?.trim() || host || apiBaseUrl,
    isLocal,
  };
}

export function EnvStrip() {
  const { t } = useTranslation();

  const env = describeEnvironment(t, {
    apiBaseUrl: API_BASE_URL,
    origin: typeof window === "undefined" ? undefined : window.location.origin,
    envName: import.meta.env.VITE_ENV_NAME,
    dbLabel: import.meta.env.VITE_DB_LABEL,
  });

  const Icon = env.isLocal ? Database : CircleAlert;

  return (
    <div
      // role="status" rather than a plain div: the strip is a standing
      // statement about the session, so a screen-reader user gets it announced
      // with the page rather than having to go hunting for it.
      //
      // It is also the ONE role="status" on the crash screen — the error
      // boundary's test selects it with getByRole("status"), which throws on
      // multiple matches. Nothing in that fallback may claim the role too.
      role="status"
      aria-label={t("environmentAriaLabel", { name: env.name, target: env.target })}
      className={env.isLocal ? "env-strip" : "env-strip env-strip--remote"}
    >
      <Icon size={12} aria-hidden="true" />
      <span className="env-strip__name">{env.name}</span>
      <span aria-hidden="true" className="env-strip__sep">
        ·
      </span>
      <span className="env-strip__target">{env.target}</span>
    </div>
  );
}
