/**
 * src/screens/login/LoginScreen — the control room's one public route.
 *
 * Same email/password form as the console's, with two differences that both
 * come from what this surface is:
 *
 *  1. The environment strip is rendered here too, above the card. An admin
 *     types production credentials into this form; they have to see which
 *     database those credentials are about to be used against BEFORE they
 *     type, not after they land on the overview.
 *  2. It does not check the signed-in role itself. `login()` succeeds for any
 *     valid account — the endpoint is the shared `POST /auth/login` — and
 *     RequireAdmin then renders ForbiddenScreen for a non-admin. Refusing
 *     here instead would mean this screen deciding who is an admin, which is
 *     a rule that already lives in exactly one place (lib/auth.tsx's
 *     `isAdmin`, backed by the server's own requireRole on every request).
 *
 * On failure it surfaces the API's own message rather than a generic
 * "something went wrong" — an operator debugging their own access needs to
 * know whether that was a wrong password or a 500.
 */
import { useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Button } from "@/ui/Button";
import { Field, Input } from "@/ui/Field";
import { LockSimpleIcon } from "@/ui/icons";
import { useAuth } from "@/lib/auth";
import { EnvStrip } from "@/shell/EnvStrip";

interface RedirectState {
  from?: { pathname?: string };
}

const DEFAULT_REDIRECT = "/overview";

export function LoginScreen() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

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
      setError(err instanceof Error ? err.message : "Sign in failed.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-app p-6">
      <div className="w-full max-w-[380px] overflow-hidden rounded-panel border border-line bg-card shadow-panel">
        <EnvStrip />

        <div className="p-6">
          <div className="mb-5 flex items-center gap-2.5">
            <span className="grid h-[27px] w-[27px] flex-none place-items-center rounded-nav bg-gradient-to-br from-[#ffc86b] via-acc to-[#d98a15] text-on-acc">
              <LockSimpleIcon size={14} weight="fill" />
            </span>
            <div>
              <b className="block text-xl font-bold leading-tight tracking-snug">La Casa</b>
              <span className="block text-micro font-bold uppercase tracking-caps-widest text-acc">
                Control room
              </span>
            </div>
          </div>

          <p className="mb-5 text-small leading-relaxed text-muted">
            Platform operations. Sign in with an account that holds the admin role.
          </p>

          <form onSubmit={handleSubmit} noValidate className="flex flex-col gap-3.5">
            <Field label="Email">
              <Input
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </Field>
            <Field label="Password">
              <Input
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
            </Field>

            {error ? (
              <p role="alert" className="text-small text-err">
                {error}
              </p>
            ) : null}

            <Button type="submit" variant="accent" disabled={submitting} className="mt-1 py-2">
              {submitting ? "Signing in…" : "Sign in"}
            </Button>
          </form>
        </div>
      </div>
    </div>
  );
}
