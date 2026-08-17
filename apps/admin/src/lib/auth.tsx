/**
 * src/lib/auth — session state for the whole app: who is signed in, and the
 * gate every control-room route sits behind.
 *
 * Ported from apps/console/src/lib/auth.tsx, plus the admin gate. The token
 * itself lives in localStorageTokenStorage (localStorage), not in this
 * context — AuthProvider only ever asks it "is there a token?" via
 * `localStorageTokenStorage.getToken()` rather than reading localStorage
 * directly a second time, so exactly one module knows how the token is
 * persisted (lib/apiClient.ts, which also explains why this app's key differs
 * from the console's). Note this is NOT reached through
 * `apiClient.tokenStorage` — createLaCasaApiClient() returns only the
 * resource groups (ads, auth, …), not the underlying ApiClient's
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
  // good (the account could have been demoted out of ADMIN, deleted, or the
  // token could have expired) — it has to be checked against GET /auth/me
  // before the app trusts it. Demotion is the case that matters most here:
  // the role this app gates on is re-read from the server on every load, not
  // remembered from the login response.
  useEffect(() => {
    let cancelled = false;

    async function checkSession() {
      const token = await localStorageTokenStorage.getToken();
      if (!token) {
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
        // Only a 401 means the token itself is bad — anything else (a network
        // blip, a 500) shouldn't throw away a token that might still be good
        // on the next request, so it's left in storage and only the in-memory
        // session drops to anonymous.
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

  // A 401 discovered later in the session (queryClient.ts's global
  // QueryCache/MutationCache onError, not just this component's own
  // mount-time checkSession above) reaches here through sessionExpired.ts —
  // same recovery as the 401 branch above, just reachable from any request.
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
        const { token, user: loggedInUser } = await apiClient.auth.login({ email, password });
        await localStorageTokenStorage.setToken(token);
        setUser(loggedInUser);
        setStatus("authenticated");
      },
      logout() {
        // Fire-and-forget: the in-memory session drops immediately (the UI
        // shouldn't wait on a localStorage write to redirect), and the token
        // clear just needs to land before the next request goes out, which
        // the Authorization header on that request already guarantees by
        // re-reading tokenStorage each time (see core/client.ts).
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
 * this compares against the wire key — lowercased first, because
 * serializeUser.js emits `"admin"` but nothing stops a future serializer, or
 * a hand-issued token in a test fixture, from sending `"ADMIN"`. Being strict
 * about case here would fail CLOSED in a confusing way (a real admin locked
 * out with no explanation); being lenient about case cannot let a non-admin
 * in, because no other role string lowercases to "admin".
 */
// eslint-disable-next-line react-refresh/only-export-components
export function isAdmin(user: AuthUser | null): boolean {
  return typeof user?.role === "string" && user.role.toLowerCase() === ADMIN_ROLE_KEY;
}

/**
 * Route guard for every route except /login. Three distinct outcomes, and the
 * middle one is the reason this exists as its own component rather than
 * apps/console's RequireAuth:
 *
 *   loading       — a full-page loading state. Never flash the login screen
 *                   while the token is still being checked.
 *   anonymous     — redirect to /login, remembering where they were headed.
 *   signed in,    — ForbiddenScreen. NOT a redirect to /login (they are
 *   not admin       already signed in, so /login would bounce them back here
 *                   and spin), and NOT the app shell with empty screens
 *                   inside it (a rail full of nav items that all 403 reads as
 *                   a broken control room rather than a closed door).
 *
 * THIS GATE IS CLIENT-SIDE CONVENIENCE ONLY. It decides what to paint, not
 * what is permitted: anyone can edit `role` in their own browser's memory, so
 * the only thing standing between a non-admin and someone else's account is
 * the server — every /api/admin route is gated by
 * `requireAuth + requireRole("ADMIN")`, and this component would be a
 * decoration if it were the only check. Its real job is to make an
 * accidentally-signed-in agent see an honest refusal instead of a screenful
 * of failed requests.
 */
export function RequireAdmin({ children }: { children: ReactNode }): ReactElement {
  const { status, user } = useAuth();
  const location = useLocation();

  if (status === "loading") {
    return <LoadingState label="Checking your session…" />;
  }

  if (status === "anonymous") {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  if (!isAdmin(user)) {
    return <ForbiddenScreen />;
  }

  return <>{children}</>;
}
