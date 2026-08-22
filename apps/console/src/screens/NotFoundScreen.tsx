/**
 * src/screens/NotFoundScreen — the catch-all inside AppShell (routes.tsx's
 * trailing "*" route). Renders inside the normal rail/topbar frame, since
 * an agent hitting a stale link is still mid-session, not logged out.
 */
import { useNavigate } from "react-router-dom";
import { Button } from "@/ui/Button";

export function NotFoundScreen() {
  const navigate = useNavigate();

  return (
    <div className="flex flex-col items-center gap-3 py-24 text-center">
      <h1 className="text-h1 font-semibold tracking-display">Page not found</h1>
      <p className="max-w-[360px] text-small text-ink-2">
        No console screen lives at this address.
      </p>
      <Button variant="primary" onClick={() => navigate("/statistics")}>
        Back to Statistics
      </Button>
    </div>
  );
}
