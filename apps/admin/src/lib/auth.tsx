/**
 * src/lib/auth — session state for the whole app: who is signed in, and the
 * gate every control-room route sits behind.
 *
 * The token itself lives in `localStorageTokenStorage` (./apiClient), not in
 * this context — AuthProvider only ever asks it "is there a token?" via
 * `getToken()` rather than reading localStorage directly a second time, so
 * EXACTLY ONE MODULE knows how the token is persisted (./apiClient, which also
 * explains why this app's key differs from the console's). Note this is NOT
 * reached through `apiClient.tokenStorage`: createLaCasaApiClient() returns
 * only the resource groups (auth, admin, …), not the underlying ApiClient's
 * `.tokenStorage`/`.baseUrl`, so the same TokenStorage instance has to be
 * imported on its own.
 */
import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactElement,
  type ReactNode,
} from "react";
import { Navigate, useLocation } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ApiError } from "@lacasa/domain";
import type { AuthUser } from "@lacasa/api-client";
import { apiClient, localStorageTokenStorage } from "./apiClient";
import { onSessionExpired } from "./sessionExpired";
import { LoadingState } from "@/ui/States";
import { ForbiddenScreen } from "@/screens/ForbiddenScreen";

export type AuthStatus = "loading" | "authenticated" | "anonymous";

export interface AuthContextValue {
  user: AuthUser | null;
  status: AuthStatus;
  login(email: string, password: string): Promise<void>;
  logout(): void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }): ReactElement {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [status, setStatus] = useState<AuthStatus>("loading");

  // Runs once on mount: a token surviving a refresh doesn't mean it's still
  // good (the account could have been DEMOTED OUT OF ADMIN, deleted, or the
  // token could have expired) — it has to be checked against GET /auth/me
  // before the app trusts it. Demotion is the case that matters most here:
  // the role this app gates on is re-read from the server on every load, never
  // remembered from the login response and never persisted beside the token.
  useEffect(() => {
    let cancelled = false;

    async function checkSession() {
      const token = await localStorageTokenStorage.getToken();
      if (!token) {
        // No token: no request. There is nothing to revalidate.
        if (!cancelled) setStatus("anonymous");
        return;
      }

      try {
        const { user: me } = await apiClient.auth.me();
        if (!cancelled) {
          setUser(me);
          setStatus("authenticated");
        }
      } catch (error) {
        // ONLY A 401 means the token itself is bad. Anything else (a network
        // blip, a 500, a 502 from a proxy) must not throw away a token that
        // might still be good on the next request, so it is left in storage
        // and only the in-memory session drops to anonymous. Throwing away a
        // valid token because the API was briefly down forces a re-login for
        // no reason.
        if (ApiError.isApiError(error) && error.status === 401) {
          await localStorageTokenStorage.setToken(null);
        }
        if (!cancelled) setStatus("anonymous");
      }
    }

    void checkSession();
    return () => {
      cancelled = true;
    };
  }, []);

  // A 401 discovered LATER in the session (./queryClient's global
  // QueryCache/MutationCache onError, not just this component's own mount-time
  // checkSession above) reaches here through ./sessionExpired — the same
  // recovery as the 401 branch above, just reachable from any request at any
  // point. This provider is the only place allowed to flip `status` to
  // 'anonymous'.
  useEffect(() => {
    return onSessionExpired(() => {
      void localStorageTokenStorage.setToken(null);
      setUser(null);
      setStatus("anonymous");
    });
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      status,
      async login(email: string, password: string) {
        // The SHARED /auth/login, not an admin-specific endpoint: it succeeds
        // for any valid account, admin or not, and performs NO role check.
        // The role gate lives in exactly one place (isAdmin, backed by the
        // server's requireRole on every /api/admin request) — a login screen
        // that refused non-admins would be a second one.
        const { token, user: loggedInUser } = await apiClient.auth.login({ email, password });
        await localStorageTokenStorage.setToken(token);
        setUser(loggedInUser);
        setStatus("authenticated");
      },
      logout() {
        // Fire-and-forget: the in-memory session drops immediately (the UI
        // shouldn't wait on a localStorage write to redirect), and the token
        // clear only needs to land before the next request goes out — which
        // the Authorization header on that request already guarantees by
        // re-reading token storage each time.
        void localStorageTokenStorage.setToken(null);
        setUser(null);
        setStatus("anonymous");
      },
    }),
    [user, status],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// The contract fixes AuthProvider/useAuth/RequireAdmin to this one file;
// splitting useAuth out to satisfy fast-refresh would just move the contract
// violation instead of avoiding it.
// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within an AuthProvider");
  return ctx;
}

/** The one place the wire value for the ADMIN role is spelled out. */
export const ADMIN_ROLE_KEY = "admin";

/**
 * True only for a signed-in ADMIN. `AuthUser.role` is deliberately typed as a
 * bare `string` by @lacasa/api-client (it is whatever the server sent), so
 * this compares against the wire key — LOWERCASED FIRST, because the
 * serializer emits `"admin"` but nothing stops a future serializer, or a
 * hand-issued token in a test fixture, from sending `"ADMIN"`. Being strict
 * about case here would fail CLOSED in a confusing way (a real admin locked
 * out with no explanation); being lenient about case cannot let a non-admin
 * in, because no other role string lowercases to "admin".
 */
// eslint-disable-next-line react-refresh/only-export-components
export function isAdmin(user: AuthUser | null): boolean {
  return typeof user?.role === "string" && user.role.toLowerCase() === ADMIN_ROLE_KEY;
}

/**
 * Route guard for every route except /login. THREE DISTINCT OUTCOMES, and the
 * middle one is the reason this exists rather than a plain RequireAuth:
 *
 *   loading       — a full-page loading state. Never flash the login screen
 *                   while the token is still being checked; a refresh with a
 *                   valid token must not blink through /login.
 *   anonymous     — redirect to /login, remembering where they were headed in
 *                   `state.from` so login can send them back, and `replace` so
 *                   the guarded URL does not sit in history.
 *   signed in,    — ForbiddenScreen, rendered INSTEAD OF the shell. NOT a
 *   not admin       redirect to /login (they are already signed in, so login
 *                   would authenticate them again, the guard would refuse
 *                   again, and the two would trade the browser back and forth
 *                   forever), and NOT the shell with empty screens inside it
 *                   (a rail full of nav items that all 403 reads as a broken
 *                   control room rather than a closed door).
 *
 * THIS GATE IS CLIENT-SIDE CONVENIENCE ONLY. It decides what to PAINT, not
 * what is PERMITTED: anyone can edit `role` in their own browser's memory, so
 * the only thing standing between a non-admin and someone else's account is
 * the server — every /api/admin route is gated by
 * `requireAuth + requireRole("ADMIN")`, and this component would be a
 * decoration if it were the only check. Its real job is to make an
 * accidentally-signed-in agent see an honest refusal instead of a screenful of
 * failed requests.
 */
export function RequireAdmin({ children }: { children: ReactNode }): ReactElement {
  const { status, user } = useAuth();
  const location = useLocation();
  const { t } = useTranslation();

  if (status === "loading") {
    return <LoadingState label={t("checkingSession")} />;
  }

  if (status === "anonymous") {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (!isAdmin(user)) {
    return <ForbiddenScreen />;
  }

  return <>{children}</>;
}
