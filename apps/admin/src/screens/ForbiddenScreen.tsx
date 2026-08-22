/**
 * src/screens/ForbiddenScreen — what a signed-in NON-admin sees.
 *
 * Rendered by RequireAdmin (lib/auth.tsx) INSTEAD OF the app shell, not inside
 * it: no rail, no nav, no topbar. An agent who followed a link here must not
 * be shown a control room with the doors merely locked — a nav listing "Users"
 * and "Audit log" tells them those surfaces exist and are one permission away,
 * and every row they clicked would 403 anyway.
 *
 * It is also not a redirect to /login. They are already signed in, so /login
 * would authenticate them again, RequireAdmin would refuse again, and the two
 * would trade the browser back and forth forever.
 *
 * The one action offered is signing out, because that is the only thing that
 * can actually change the outcome — signing in as a different account. The
 * screen states WHICH account is currently signed in for exactly that reason:
 * "you are not an admin" is unhelpful when the real situation is "you are
 * signed in as the wrong one of your two accounts". The role is printed
 * verbatim as the server sent it, not through the friendly label, because the
 * question being answered here is what the server thinks, not what this app
 * would call it.
 *
 * Because it renders instead of the shell, it carries its own <h1> — the
 * topbar's is not on screen.
 */
import { useTranslation } from "react-i18next";
import { useAuth } from "@/lib/auth";
import { Button } from "@/ui/Button";
import { Ban, LogOut } from "@/ui/icons";
import { EnvStrip } from "@/shell/EnvStrip";
import "./forbiddenScreen.scss";

export function ForbiddenScreen() {
  const { user, logout } = useAuth();
  const { t } = useTranslation();

  return (
    <div className="forbidden">
      <div className="forbidden__card">
        {/* The strip belongs here for the same reason the login screen carries
            it: this is the one signed-in state with no rail to hold it, and
            "signed in as the wrong account" and "signed in against the wrong
            database" are the same confusion read two different ways. */}
        <EnvStrip />

        <div className="forbidden__body">
          <span className="forbidden__icon" aria-hidden="true">
            <Ban size={24} />
          </span>

          <h1 className="forbidden__title">{t("forbiddenTitle")}</h1>
          <p className="forbidden__text">{t("forbiddenBody")}</p>

          {user ? (
            <dl className="forbidden__facts">
              <dt>{t("signedInAs")}</dt>
              <dd>{user.email}</dd>
              <dt>{t("columnRole")}</dt>
              <dd>{user.role}</dd>
            </dl>
          ) : null}

          <div className="forbidden__action">
            <Button icon={LogOut} onClick={logout}>
              {t("signOut")}
            </Button>
          </div>

          {/* Deliberately says who to ask rather than how to self-serve: there
              is no UI anywhere that grants this role, by design. The first
              admin is minted out of band with
              `npm run promote:admin -w @lacasa/api`. */}
          <p className="forbidden__footnote">{t("forbiddenFootnote")}</p>
        </div>
      </div>
    </div>
  );
}
