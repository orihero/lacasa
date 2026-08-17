/**
 * src/shell/EnvStrip — the permanent environment strip: the first thing in
 * the rail, above the wordmark, on every single screen including /login.
 *
 * It answers one question — WHICH DATABASE DOES THIS TAB WRITE TO? — and it
 * is not dismissible, not collapsible and never scrolls away. The failure it
 * exists to prevent is an admin with a local tab and a production tab open
 * side by side approving an application in the wrong one; by the time that
 * mistake is visible in the data it has already promoted the wrong account.
 *
 * The strip reads `import.meta.env` and nothing else. It does NOT ask the API
 * which environment it is, deliberately: that answer would arrive after first
 * paint, and a strip that says the wrong thing for 200ms is worse than one
 * that is derived, synchronously, from the same variable the requests
 * themselves are built from (`VITE_API_URL`, see lib/apiClient.ts).
 *
 * TONE IS DERIVED, NOT CONFIGURED. Anything that isn't localhost renders
 * magenta — the one colour this app reserves for irreversible consequences —
 * because a deployment can be misconfigured but a hostname cannot lie about
 * where the bytes are going. An operator can label the environment
 * (`VITE_ENV_NAME`, `VITE_DB_LABEL`) but cannot label a remote database as
 * safe.
 */
import clsx from "clsx";
import { API_BASE_URL } from "@/lib/apiClient";
import { DatabaseIcon, WarningCircleIcon } from "@/ui/icons";

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
 * Pure so it can be tested against every combination of "operator labelled
 * it" and "we had to derive it" without rendering anything.
 *
 * An unparseable base URL is treated as REMOTE, not local: the whole point of
 * the strip is that it fails loud. A relative `/api` base (same-origin
 * deployment) is the one case that legitimately has no host of its own, and
 * it resolves against the page's own origin, which is what the caller passes
 * as `origin`.
 */
// Co-located with the only component that calls it (and the comment block
// that explains its policy) rather than split into its own module purely to
// satisfy fast refresh.
// eslint-disable-next-line react-refresh/only-export-components
export function describeEnvironment({
  apiBaseUrl,
  origin,
  envName,
  dbLabel,
}: {
  apiBaseUrl: string;
  origin?: string;
  envName?: string;
  dbLabel?: string;
}): EnvDescription {
  let host: string | null = null;
  try {
    host = new URL(apiBaseUrl, origin).hostname;
  } catch {
    host = null;
  }

  const isLocal = host !== null && LOCAL_HOSTS.has(host);
  return {
    name: envName?.trim() || (isLocal ? "Local" : "Remote"),
    // The host, not the full URL: "lacasa-prod.example.com" is what an
    // operator recognises, and the "/api" suffix every base URL shares is
    // noise in a strip this small.
    target: dbLabel?.trim() || host || apiBaseUrl,
    isLocal,
  };
}

export function EnvStrip() {
  const env = describeEnvironment({
    apiBaseUrl: API_BASE_URL,
    origin: typeof window === "undefined" ? undefined : window.location.origin,
    envName: import.meta.env.VITE_ENV_NAME,
    dbLabel: import.meta.env.VITE_DB_LABEL,
  });

  const Icon = env.isLocal ? DatabaseIcon : WarningCircleIcon;

  return (
    <div
      // role=status rather than a plain div: the strip is a standing
      // statement about the session, and a screen-reader user gets it
      // announced with the page rather than having to go hunting for it.
      role="status"
      aria-label={`Environment: ${env.name}, writing to ${env.target}`}
      className={clsx(
        "flex items-center gap-1.5 px-3.5 py-1 text-micro font-bold uppercase tracking-caps-widest",
        env.isLocal ? "bg-acc text-on-acc" : "bg-danger text-on-acc",
      )}
    >
      <Icon size={12} weight="fill" className="flex-none" />
      <span>{env.name}</span>
      <span aria-hidden="true" className="opacity-60">
        ·
      </span>
      {/* Not `font-mono`: at 9px the mono family loses more legibility than
          the "this is a record" signal is worth, and this string is the one
          thing on the strip that must survive a glance. */}
      <span className="truncate normal-case tracking-normal">{env.target}</span>
    </div>
  );
}
