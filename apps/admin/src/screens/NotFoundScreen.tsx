/**
 * src/screens/NotFoundScreen — the catch-all INSIDE AppShell (routes.tsx's
 * trailing "*" route). It renders in the normal rail/topbar frame because an
 * admin on a stale link is still mid-session, and the environment strip they
 * need to keep seeing lives in that frame.
 *
 * The topbar heading above it reads "Control room" — nav.ts's unmatched-path
 * fallback — never the previous screen's title.
 *
 * It echoes the path back verbatim in monospace. On a surface whose links are
 * pasted between operators and support tickets, "no screen at
 * /users/9c6e41af" is the difference between a typo and a screen someone
 * expected to exist.
 *
 * There is no route for listing moderation, 3D tours or plans, so this is
 * where an admin who types /x-mod lands: the honest 404, not a placeholder
 * screen implying moderation exists and is empty.
 */
import { useLocation, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Button } from "@/ui/Button";
import { EmptyState } from "@/ui/States";
import { TriangleAlert } from "@/ui/icons";
import "./notFoundScreen.scss";

export function NotFoundScreen() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const { t } = useTranslation();

  return (
    <EmptyState
      icon={TriangleAlert}
      title={t("notFoundTitle")}
      sub={<span className="not-found__path">{pathname}</span>}
      action={
        <Button variant="accent" onClick={() => navigate("/overview")}>
          {t("backToOverview")}
        </Button>
      }
    />
  );
}
