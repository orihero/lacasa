/**
 * auth.test.tsx — exercises AuthProvider/RequireAuth against a mocked
 * `apiClient.auth.me`, real `localStorage` (via the real
 * `localStorageTokenStorage`, left un-mocked — see the apiClient mock below)
 * and a mocked `react-router-dom` (`Navigate`/`useLocation`): this
 * workspace's own react-router-dom copy is hoisted to the repo root and
 * pinned to a different React major there (see @/test/render's file header),
 * so a *real* `<Navigate>`/`useLocation()` crashes the instant it mounts
 * inside this app's nested React 19 tree — the same class of conflict
 * LeadsScreen.test.tsx and PublishStatusScreen.test.tsx already work around
 * the identical way.
 *
 * Focus: finding 7's fix — a 401 discovered by react-query anywhere in the
 * session (not just AuthProvider's own mount-time checkSession) has to clear
 * the token and flip `status` to 'anonymous' so RequireAuth redirects. That
 * path runs through sessionExpired.ts's real (unmocked) emit/subscribe, not
 * a fake — this test is proving the wiring, not just that the module exists.
 */
import { waitFor, screen } from "@testing-library/dom";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { render } from "@/test/render";
import { emitSessionExpired } from "@/lib/sessionExpired";
import { TOKEN_KEY } from "@/lib/apiClient";

const hoisted = vi.hoisted(() => ({ meMock: vi.fn() }));

vi.mock("react-router-dom", () => ({
  useLocation: () => ({ pathname: "/statistics" }),
  Navigate: (props: { to: string }) => <div data-testid="navigate" data-to={props.to} />,
}));

vi.mock("@/lib/apiClient", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/apiClient")>();
  return {
    ...actual, // keeps the real localStorageTokenStorage/TOKEN_KEY/resolveBaseUrl
    apiClient: { auth: { me: hoisted.meMock } },
  };
});

import { AuthProvider, RequireAuth } from "../auth";

const ME_USER = {
  id: "u1",
  fullName: "Javlon Rustamov",
  email: "javlon@lacasa.uz",
  phoneNumber: null,
  role: "AGENT",
};

beforeEach(() => {
  localStorage.clear();
  hoisted.meMock.mockReset();
});

describe("AuthProvider + RequireAuth", () => {
  it("renders the protected tree once the mount-time session check succeeds", async () => {
    localStorage.setItem(TOKEN_KEY, "tok-1");
    hoisted.meMock.mockResolvedValue({ user: ME_USER });

    render(
      <AuthProvider>
        <RequireAuth>
          <div data-testid="child">Protected</div>
        </RequireAuth>
      </AuthProvider>,
    );

    await waitFor(() => expect(screen.getByTestId("child")).toBeInTheDocument());
  });

  it("a sessionExpired event later in the session clears the token and redirects to /login, not just the initial 401", async () => {
    localStorage.setItem(TOKEN_KEY, "tok-1");
    hoisted.meMock.mockResolvedValue({ user: ME_USER });

    render(
      <AuthProvider>
        <RequireAuth>
          <div data-testid="child">Protected</div>
        </RequireAuth>
      </AuthProvider>,
    );
    await waitFor(() => expect(screen.getByTestId("child")).toBeInTheDocument());

    // Simulates a query/mutation elsewhere in the app hitting a 401 well
    // after mount — queryClient.ts's notifyIfSessionExpired is what would
    // really call this; the point of this test is what happens on the
    // AuthProvider/RequireAuth side once it does.
    emitSessionExpired();

    await waitFor(() => {
      const nav = screen.getByTestId("navigate");
      expect(nav).toHaveAttribute("data-to", "/login");
    });
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull();
  });

  it("with no token at all, redirects to /login immediately without calling me()", async () => {
    render(
      <AuthProvider>
        <RequireAuth>
          <div data-testid="child">Protected</div>
        </RequireAuth>
      </AuthProvider>,
    );

    await waitFor(() => {
      const nav = screen.getByTestId("navigate");
      expect(nav).toHaveAttribute("data-to", "/login");
    });
    expect(hoisted.meMock).not.toHaveBeenCalled();
  });
});
