/**
 * src/screens/NotFoundScreen — the catch-all inside AppShell (routes.tsx's
 * trailing "*" route). Renders inside the normal rail/topbar frame: an admin
 * on a stale link is still mid-session, and the environment strip they need
 * to keep seeing lives in that frame.
 *
 * It echoes the path back verbatim in monospace. On a surface whose links are
 * pasted between operators and support tickets, "no screen at
 * /users/9c6e41af" is the difference between a typo and a screen someone
 * expected to exist.
 */
import { useLocation, useNavigate } from "react-router-dom";
import { Button } from "@/ui/Button";
import { EmptyState } from "@/ui/States";
import { WarningIcon } from "@/ui/icons";

export function NotFoundScreen() {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <EmptyState
      icon={WarningIcon}
      title="No screen at this address"
      sub={<span className="font-mono text-record text-muted">{pathname}</span>}
      action={
        <Button variant="accent" onClick={() => navigate("/overview")}>
          Back to overview
        </Button>
      }
    />
  );
}
