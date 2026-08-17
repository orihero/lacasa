/**
 * src/screens/ForbiddenScreen — what a signed-in NON-admin sees.
 *
 * Rendered by RequireAdmin (lib/auth.tsx) INSTEAD OF the app shell, not
 * inside it: no rail, no nav, no topbar. An agent who followed a link here
 * must not be shown a control room with the doors merely locked — a nav
 * listing "Users" and "Audit log" tells them those surfaces exist and are one
 * permission away, and every row they click would 403 anyway.
 *
 * It is also not a redirect to /login. They are already signed in, so /login
 * would authenticate them again, RequireAdmin would refuse again, and the two
 * would trade the browser back and forth forever.
 *
 * The one action offered is signing out, because that is the only thing that
 * can actually change the outcome — signing in as a different account. The
 * screen states which account is currently signed in for exactly that reason:
 * "you are not an admin" is unhelpful when the real situation is "you are
 * signed in as the wrong one of your two accounts".
 */
import { useAuth } from "@/lib/auth";
import { Button } from "@/ui/Button";
import { ProhibitIcon, SignOutIcon } from "@/ui/icons";
import { EnvStrip } from "@/shell/EnvStrip";

export function ForbiddenScreen() {
  const { user, logout } = useAuth();

  return (
    <div className="flex min-h-screen items-center justify-center bg-app p-6">
      <div className="w-full max-w-[440px] overflow-hidden rounded-panel border border-line bg-card text-center shadow-panel">
        {/* The strip belongs here for the same reason LoginScreen carries it:
            this screen renders INSTEAD of the shell, so it is the one signed-in
            state with no rail to hold it, and "signed in as the wrong account"
            and "signed in against the wrong database" are the same confusion
            read two different ways. The card below states which account; the
            strip states which environment. */}
        <EnvStrip />

        <div className="p-6">
          <span className="mx-auto mb-4 grid h-12 w-12 place-items-center rounded-panel bg-danger-soft text-danger">
            <ProhibitIcon size={24} />
          </span>
          <h1 className="text-lg font-semibold text-ink">This is the control room</h1>
          <p className="mx-auto mt-2 max-w-[340px] text-small leading-relaxed text-ink-2">
            Your account is signed in, but it does not hold the admin role — so none of the
            screens here would load any data for you.
          </p>

          {user ? (
            <dl className="mt-4 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1.5 rounded-control border border-line bg-sunk px-3 py-2.5 text-left">
              <dt className="text-tiny text-muted">Signed in as</dt>
              <dd className="truncate text-right font-mono text-record text-ink">{user.email}</dd>
              <dt className="text-tiny text-muted">Role</dt>
              <dd className="text-right font-mono text-record text-ink">{user.role}</dd>
            </dl>
          ) : null}

          <div className="mt-5 flex justify-center">
            <Button icon={SignOutIcon} onClick={logout}>
              Sign out
            </Button>
          </div>

          {/* Deliberately says who to ask rather than how to self-serve: there
              is no UI anywhere that grants this role, by design. The first
              admin is minted out of band with
              `npm run promote:admin -w @lacasa/api`. */}
          <p className="mt-4 text-tiny text-faint">
            Admin access is granted by a platform operator, never through sign-up.
          </p>
        </div>
      </div>
    </div>
  );
}
