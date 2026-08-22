/**
 * ConnectedAccountsScreen.test.tsx — mocks the data layer
 * (`@/data/useConnectedAccounts`, `@/lib/auth`) and `@/ui/icons` (the
 * workspace-wide react-dom hoisting conflict — see @/test/render's file
 * header — makes a real `@phosphor-icons/react` component throw the instant
 * it mounts, independent of anything this screen does).
 */
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { InstagramAccount } from "@lacasa/api-client";
import type { AuthContextValue } from "@/lib/auth";
import { useAuth } from "@/lib/auth";
import { useConnectInstagram, useDisconnectInstagram, useInstagramAccounts } from "@/data/useConnectedAccounts";
import { render } from "@/test/render";
import { ConnectedAccountsScreen } from "../ConnectedAccountsScreen";

vi.mock("@/lib/auth", () => ({ useAuth: vi.fn() }));
vi.mock("@/data/useConnectedAccounts", () => ({
  useInstagramAccounts: vi.fn(),
  useConnectInstagram: vi.fn(),
  useDisconnectInstagram: vi.fn(),
}));
// A plain object built from the real export names — NOT a catch-all Proxy.
// vitest `await`s this factory's return value, and `await` probes `.then`;
// a Proxy that answers every key with a function is a thenable whose `then`
// never calls resolve, so the worker deadlocks silently while collecting
// this file (that was the workspace's "vitest run never terminates" hang).
vi.mock("@/ui/icons", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/ui/icons")>();
  function icon(name: string) {
    return function MockIcon(props: Record<string, unknown>) {
      return <svg data-testid={`icon-${name}`} {...props} />;
    };
  }
  return Object.fromEntries(Object.keys(actual).map((key) => [key, icon(key)]));
});

function authResult(overrides: Partial<AuthContextValue> = {}): AuthContextValue {
  return {
    user: { id: "u1", fullName: "Javlon Rustamov", email: "javlon@lacasa.uz", phoneNumber: null, role: "AGENT" },
    status: "authenticated",
    login: vi.fn(),
    logout: vi.fn(),
    ...overrides,
  } as unknown as AuthContextValue;
}

function igAccountsResult(
  overrides: Partial<ReturnType<typeof useInstagramAccounts>> = {},
): ReturnType<typeof useInstagramAccounts> {
  return {
    data: [] as InstagramAccount[],
    isLoading: false,
    isError: false,
    ...overrides,
  } as unknown as ReturnType<typeof useInstagramAccounts>;
}

function mutationResult<T>(overrides: Record<string, unknown> = {}): T {
  return {
    mutate: vi.fn(),
    isPending: false,
    isError: false,
    error: undefined,
    ...overrides,
  } as unknown as T;
}

beforeEach(() => {
  vi.mocked(useAuth).mockReturnValue(authResult());
  vi.mocked(useInstagramAccounts).mockReturnValue(igAccountsResult());
  vi.mocked(useConnectInstagram).mockReturnValue(mutationResult<ReturnType<typeof useConnectInstagram>>());
  vi.mocked(useDisconnectInstagram).mockReturnValue(mutationResult<ReturnType<typeof useDisconnectInstagram>>());
  vi.spyOn(window, "open").mockImplementation(() => null);
});

describe("ConnectedAccountsScreen — Instagram (the one real, per-account channel)", () => {
  it("shows 'Not connected' and a Connect action when there are zero accounts", () => {
    render(<ConnectedAccountsScreen />);
    const instagramNameCell = screen.getByText("Instagram").closest("div") as HTMLElement;
    expect(within(instagramNameCell).getByText("Not connected")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Connect" })).toBeInTheDocument();
  });

  it("renders each real connected account with its username and real token-expiry date", () => {
    vi.mocked(useInstagramAccounts).mockReturnValue(
      igAccountsResult({
        data: [{ igUserId: "ig1", username: "javlon.realty", expiresAt: "2026-10-02T00:00:00.000Z" }],
      }),
    );
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText(/@javlon\.realty/)).toBeInTheDocument();
    expect(screen.getByText(/token refreshes/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Disconnect" })).toBeInTheDocument();
  });

  it("opens the real connect URL in a new tab when Connect is clicked", async () => {
    const mutate = vi.fn((_vars: undefined, opts?: { onSuccess?: (url: string) => void }) => {
      opts?.onSuccess?.("https://meta.example/oauth?state=abc");
    });
    vi.mocked(useConnectInstagram).mockReturnValue(
      mutationResult<ReturnType<typeof useConnectInstagram>>({ mutate }),
    );
    render(<ConnectedAccountsScreen />);

    await userEvent.click(screen.getByRole("button", { name: "Connect" }));

    expect(mutate).toHaveBeenCalledOnce();
    expect(window.open).toHaveBeenCalledWith(
      "https://meta.example/oauth?state=abc",
      "_blank",
      "noopener,noreferrer",
    );
  });

  it("says Meta App Review still gates real publishing instead of implying Connect alone is enough", () => {
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText(/instagram_business_content_publish/)).toBeInTheDocument();
    expect(screen.getByText(/Meta App Review/)).toBeInTheDocument();
  });

  it("disconnects a real account by igUserId when Disconnect is clicked", async () => {
    const mutate = vi.fn();
    vi.mocked(useInstagramAccounts).mockReturnValue(
      igAccountsResult({ data: [{ igUserId: "ig1", username: "javlon.realty", expiresAt: null }] }),
    );
    vi.mocked(useDisconnectInstagram).mockReturnValue(
      mutationResult<ReturnType<typeof useDisconnectInstagram>>({ mutate }),
    );
    render(<ConnectedAccountsScreen />);

    await userEvent.click(screen.getByRole("button", { name: "Disconnect" }));
    expect(mutate).toHaveBeenCalledWith("ig1", expect.anything());
  });

  it("shows a loading state instead of a stale or fabricated account list", () => {
    vi.mocked(useInstagramAccounts).mockReturnValue(igAccountsResult({ data: undefined, isLoading: true }));
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText("Loading…")).toBeInTheDocument();
  });

  it("shows a real error message instead of silently rendering 'Not connected' when the accounts fetch fails", () => {
    vi.mocked(useInstagramAccounts).mockReturnValue(igAccountsResult({ data: undefined, isError: true }));
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText("Couldn't load connected accounts.")).toBeInTheDocument();
  });

  it("surfaces a failed Disconnect instead of swallowing it silently", () => {
    vi.mocked(useInstagramAccounts).mockReturnValue(
      igAccountsResult({ data: [{ igUserId: "ig1", username: "javlon.realty", expiresAt: null }] }),
    );
    vi.mocked(useDisconnectInstagram).mockReturnValue(
      mutationResult<ReturnType<typeof useDisconnectInstagram>>({
        isError: true,
        error: { message: "Network error — could not disconnect" },
        variables: "ig1",
      }),
    );
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText("Network error — could not disconnect")).toBeInTheDocument();
  });

  it("disables Connect and Disconnect for a coworker account — the server 403s both for any role but AGENT", () => {
    vi.mocked(useAuth).mockReturnValue(
      authResult({
        user: {
          id: "u2",
          fullName: "Sardor Abdullayev",
          email: "sardor@lacasa.uz",
          phoneNumber: null,
          role: "COWORKER",
          agentId: "u1",
        },
      }),
    );
    vi.mocked(useInstagramAccounts).mockReturnValue(
      igAccountsResult({ data: [{ igUserId: "ig1", username: "javlon.realty", expiresAt: null }] }),
    );
    render(<ConnectedAccountsScreen />);
    expect(screen.getByRole("button", { name: "Connect another" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Disconnect" })).toBeDisabled();
  });
});

describe("ConnectedAccountsScreen — Telegram, YouTube, OLX (no real ConnectedAccount data)", () => {
  it("shows Telegram's real channel count from AuthUser.tgChatIds, count only — never a channel name", () => {
    vi.mocked(useAuth).mockReturnValue(
      authResult({
        user: {
          id: "u1",
          fullName: "Javlon Rustamov",
          email: "javlon@lacasa.uz",
          phoneNumber: null,
          role: "AGENT",
          tgChatIds: ["1", "2"],
        },
      }),
    );
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText("2 channels connected")).toBeInTheDocument();
  });

  it("shows 'Not connected' for Telegram when tgChatIds is empty or absent", () => {
    render(<ConnectedAccountsScreen />);
    const telegramNameCell = screen.getByText("Telegram").closest("div") as HTMLElement;
    expect(within(telegramNameCell).getByText("Not connected")).toBeInTheDocument();
  });

  it("disables the YouTube and OLX action buttons — there is no real endpoint behind either", () => {
    render(<ConnectedAccountsScreen />);
    expect(screen.getByRole("button", { name: "Reconnect" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Settings" })).toBeDisabled();
  });

  it("flags the missing ConnectedAccount model instead of fabricating a status", () => {
    render(<ConnectedAccountsScreen />);
    expect(screen.getByText(/ConnectedAccount/)).toBeInTheDocument();
  });

  it("renders zero bg-accent elements — no real endpoint backs PLAN.md's YouTube Reconnect CTA", () => {
    const { container } = render(<ConnectedAccountsScreen />);
    expect(container.querySelectorAll(".bg-accent").length).toBe(0);
  });
});
