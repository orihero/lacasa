/**
 * src/screens/login/LoginScreen — the console's one public route. A real
 * email/password form against useAuth().login; on success it returns to
 * whatever route RequireAuth bounced the agent off of (falling back to
 * Statistics when there wasn't one), and on failure it surfaces the API's
 * own error message rather than a generic "something went wrong" — this is
 * an internal tool, and a silent failure costs an agent their afternoon.
 *
 * No register link: realtor sign-up is apps/web's flow, not the console's —
 * this app is for agents who already have an account.
 */
import { useState, type FormEvent } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Button } from "@/ui/Button";
import { Field, PillInput } from "@/ui/Field";
import { HouseIcon } from "@/ui/icons";
import { Panel } from "@/ui/Panel";
import { useAuth } from "@/lib/auth";

interface RedirectState {
  from?: { pathname?: string };
}

const DEFAULT_REDIRECT = "/statistics";

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
    <div className="flex min-h-screen items-center justify-center bg-canvas px-[28px]">
      <Panel className="w-full max-w-[380px]">
        <div className="mb-6 flex items-center gap-2.5">
          <span className="flex h-10 w-10 items-center justify-center rounded-full bg-dark text-dark-text">
            <HouseIcon size={18} weight="fill" />
          </span>
          <span className="text-brand font-semibold tracking-snug">La Casa</span>
        </div>
        <h1 className="mb-1 text-title font-semibold tracking-snug">Agent console</h1>
        <p className="mb-6 text-small text-ink-2">Sign in with your La Casa agent account.</p>

        <form onSubmit={handleSubmit} noValidate className="flex flex-col gap-4">
          <Field label="Email" full>
            <PillInput
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
            />
          </Field>
          <Field label="Password" full>
            <PillInput
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
            />
          </Field>

          {error ? (
            <p role="alert" className="text-caption text-err">
              {error}
            </p>
          ) : null}

          <Button type="submit" variant="primary" disabled={submitting} className="justify-center">
            {submitting ? "Signing in…" : "Sign in"}
          </Button>
        </form>
      </Panel>
    </div>
  );
}
