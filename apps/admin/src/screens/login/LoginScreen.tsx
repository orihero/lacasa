/**
 * src/screens/login/LoginScreen — the control room's one public route,
 * rendered bare: no rail, no topbar.
 *
 * It is built on apps/web's own login screen, which is the one place the
 * design contract sanctions its otherwise-anomalous auth treatment
 * (§8.3): the two-pane `.formContainer` / `.imgContainer` split, the blush
 * `#fcf5f3` column, 20px inputs at a 5px radius, and the teal submit button
 * with its `#bed9d8` disabled pair. Copying it means this screen sits beside
 * the console's login without a seam.
 *
 * Two differences, and both come from what this surface is:
 *
 *  1. THE ENVIRONMENT STRIP IS RENDERED HERE TOO, across the top. An admin
 *     types production credentials into this form; they have to see which
 *     database those credentials are about to be used against BEFORE they
 *     type, not after they land on the overview.
 *  2. It does not check the signed-in role itself. `login()` succeeds for any
 *     valid account — the endpoint is the shared POST /auth/login — and
 *     RequireAdmin then renders ForbiddenScreen for a non-admin. Refusing here
 *     instead would mean this screen deciding who is an admin, a rule that
 *     already lives in exactly one place (lib/auth.tsx's `isAdmin`, backed by
 *     the server's own requireRole on every request). SO: A NON-ADMIN SEES NO
 *     ERROR HERE AT ALL.
 *
 * On failure it surfaces the API's own message verbatim rather than a generic
 * "something went wrong" — an operator debugging their own access needs to
 * know whether that was a wrong password or a 500. `noValidate` because the
 * app owns validation and messaging; the `required` attributes stay for
 * assistive tech, and the API is the validator.
 */
import { useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useAuth } from "@/lib/auth";
import { Field, Input } from "@/ui/Field";
import { Lock } from "@/ui/icons";
import { EnvStrip } from "@/shell/EnvStrip";
import "./login.scss";

interface RedirectState {
  from?: { pathname?: string };
}

const DEFAULT_REDIRECT = "/overview";

export function LoginScreen() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { t } = useTranslation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // The value RequireAdmin set on its redirect, so an admin who deep-linked to
  // /audit and got bounced lands back on /audit rather than the overview.
  const redirectState = location.state as RedirectState | null;
  const redirectTo = redirectState?.from?.pathname ?? DEFAULT_REDIRECT;

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await login(email, password);
      navigate(redirectTo, { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : t("signInFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login admin-login">
      <EnvStrip />

      <div className="admin-login__panes">
        <div className="formContainer">
          <form onSubmit={handleSubmit} noValidate>
            <div className="admin-login__brand">
              <span className="admin-login__mark" aria-hidden="true">
                <Lock size={14} />
              </span>
              <span className="admin-login__wordmark">
                <b>{t("appName")}</b>
                <small>{t("controlRoom")}</small>
              </span>
            </div>

            <p className="admin-login__intro">{t("loginIntro")}</p>

            <Field label={t("email")}>
              <Input
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </Field>

            <Field label={t("password")}>
              <Input
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
            </Field>

            {error ? <span role="alert">{error}</span> : null}

            <button type="submit" disabled={submitting}>
              {submitting ? t("signingIn") : t("signIn")}
            </button>
          </form>
        </div>

        {/* apps/web fills this column with `/bg.png`. There is no marketing
            image on this surface and none is worth shipping for it, so the
            blush pane carries the same padlock the rail does — the mark that
            says which of the three La Casa apps you are signing in to. */}
        <div className="imgContainer" aria-hidden="true">
          <Lock size={96} />
        </div>
      </div>
    </div>
  );
}
