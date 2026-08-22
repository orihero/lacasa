/**
 * PublishStatusScreen — renders the real `PublishStatusView` (see that
 * file's header for why `PublishStatusScreen` itself, the router-wired
 * wrapper, isn't rendered here) against a mocked data layer, asserting the
 * states, the derived counts (hasFailedChannel / hasAnyAttempt), and the
 * data-honesty behaviour: never a fabricated value, and the retry gap named
 * rather than hidden.
 */
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { Ad } from "@lacasa/api-client";
import type { UseQueryResult } from "@tanstack/react-query";
import { render } from "./testUtils";

vi.mock("@/ui/icons", async () => {
  const actual = await vi.importActual<typeof import("@/ui/icons")>("@/ui/icons");
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="fake-icon" {...props} />;
  const fakeExports: Record<string, unknown> = {};
  for (const key of Object.keys(actual)) fakeExports[key] = FakeIcon;
  return fakeExports;
});

vi.mock("@/data/useAds", () => ({ useMyAds: vi.fn() }));
vi.mock("@/data/usePublish", () => ({ usePublishStatusForAd: vi.fn() }));

import { useMyAds } from "@/data/useAds";
import { usePublishStatusForAd } from "@/data/usePublish";
import { PublishStatusView } from "../PublishStatusScreen";
import { RETRY_GAP_MESSAGE, adReference, adTitle, publishStatusView } from "../helpers";

const useMyAdsMock = vi.mocked(useMyAds);
const usePublishStatusForAdMock = vi.mocked(usePublishStatusForAd);

function makeAd(overrides: { id: string; title?: string; reference?: string }): Ad {
  return {
    agentId: "agent-1",
    coworkerId: null,
    photos: [],
    media: [],
    lat: null,
    lng: null,
    tour3dLink: null,
    ...overrides,
  };
}

// react-query's UseQueryResult is a large discriminated union (status,
// fetchStatus, isFetching, dataUpdatedAt, …) that PublishStatusView never
// reads beyond isPending/isError/data/error/refetch — this fixture only
// promises those five, then asserts the shape via `unknown` rather than
// hand-filling ~15 fields this screen doesn't look at.
function fakeQuery<T>(fields: {
  isPending: boolean;
  isError: boolean;
  data?: T;
  error?: unknown;
  refetch?: () => void;
}): UseQueryResult<T> {
  return {
    isPending: fields.isPending,
    isError: fields.isError,
    data: fields.data,
    error: fields.error ?? null,
    refetch: fields.refetch ?? vi.fn(),
  } as unknown as UseQueryResult<T>;
}

const AD_A = makeAd({ id: "ad-a", title: "Bright 3-room apartment in Chilonzor", reference: "a3f21" });
const AD_B = makeAd({ id: "ad-b", title: "Renovated studio near Yunusobod metro" });

function renderView({
  searchParams = new URLSearchParams(),
  navigate = vi.fn(),
  setSearchParams = vi.fn(),
}: {
  searchParams?: URLSearchParams;
  navigate?: ReturnType<typeof vi.fn>;
  setSearchParams?: ReturnType<typeof vi.fn>;
} = {}) {
  const utils = render(
    <PublishStatusView navigate={navigate} searchParams={searchParams} setSearchParams={setSearchParams} />,
  );
  return { ...utils, navigate, setSearchParams };
}

beforeEach(() => {
  useMyAdsMock.mockReset();
  usePublishStatusForAdMock.mockReset();
  // A sane default so tests focused on ad-selection don't also have to stub
  // the publish query — overridden explicitly wherever the table/flag/empty
  // publish-status body is the thing under test.
  usePublishStatusForAdMock.mockReturnValue(fakeQuery({ isPending: true, isError: false }));
});

describe("ads loading/error/empty states", () => {
  it("shows a loading state while the agent's ads are still loading", () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: true, isError: false }));
    renderView();
    expect(screen.getByText("Loading your ads…")).toBeInTheDocument();
    expect(screen.getByText("Publish status")).toBeInTheDocument();
  });

  it("surfaces the real error message and retries via the query's own refetch", async () => {
    const refetch = vi.fn();
    useMyAdsMock.mockReturnValue(
      fakeQuery({ isPending: false, isError: true, error: new Error("network down"), refetch }),
    );
    renderView();
    expect(screen.getByText("network down")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(refetch).toHaveBeenCalledOnce();
  });

  it("shows an honest empty state (not a fabricated table) when the agent has no ads, and lets them create one", async () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [] }));
    const navigate = vi.fn();
    renderView({ navigate });
    expect(screen.getByText("No ads to publish yet")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "New listing" }));
    expect(navigate).toHaveBeenCalledWith("/ads/new");
  });
});

describe("ad selection and URL sync", () => {
  it("defaults to the newest ad (ads[0], per useMyAds' own newest-first contract) and writes it into the URL", () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [AD_A, AD_B] }));
    const setSearchParams = vi.fn();
    renderView({ searchParams: new URLSearchParams(), setSearchParams });

    expect(setSearchParams).toHaveBeenCalledTimes(1);
    const [writtenParams, opts] = setSearchParams.mock.calls[0] as [URLSearchParams, { replace?: boolean }];
    expect(writtenParams.get("adId")).toBe("ad-a");
    expect(opts).toEqual({ replace: true });
  });

  it("honours an explicit ?adId= over the newest ad, and does not rewrite the URL when it already matches", () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [AD_A, AD_B] }));
    const setSearchParams = vi.fn();
    const { container } = renderView({ searchParams: new URLSearchParams("adId=ad-b"), setSearchParams });

    // The ad's title legitimately appears twice (the <option> AND the
    // Panel's own title) — scope to the Panel heading specifically rather
    // than asserting on text that's ambiguous by construction.
    expect(container.querySelector(".text-title")).toHaveTextContent("Renovated studio near Yunusobod metro");
    expect(setSearchParams).not.toHaveBeenCalled();
  });

  it("falls back to the newest ad when ?adId= doesn't belong to this agent, correcting the URL", () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [AD_A, AD_B] }));
    const setSearchParams = vi.fn();
    const { container } = renderView({
      searchParams: new URLSearchParams("adId=someone-elses-ad"),
      setSearchParams,
    });

    expect(container.querySelector(".text-title")).toHaveTextContent("Bright 3-room apartment in Chilonzor");
    const [writtenParams] = setSearchParams.mock.calls[0] as [URLSearchParams];
    expect(writtenParams.get("adId")).toBe("ad-a");
  });

  it("switching the selector calls setSearchParams with the newly picked ad", async () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [AD_A, AD_B] }));
    const setSearchParams = vi.fn();
    renderView({ searchParams: new URLSearchParams("adId=ad-a"), setSearchParams });
    setSearchParams.mockClear();

    await userEvent.selectOptions(screen.getByLabelText("Ad"), "ad-b");
    const [writtenParams, opts] = setSearchParams.mock.calls[0] as [URLSearchParams, { replace?: boolean }];
    expect(writtenParams.get("adId")).toBe("ad-b");
    expect(opts).toEqual({ replace: true });
  });

  it("the Editor button navigates to the selected ad's real edit route", async () => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [AD_A] }));
    const navigate = vi.fn();
    renderView({ searchParams: new URLSearchParams("adId=ad-a"), navigate });
    await userEvent.click(screen.getByRole("button", { name: "Editor" }));
    expect(navigate).toHaveBeenCalledWith("/ads/ad-a/edit");
  });
});

describe("publish-status body", () => {
  beforeEach(() => {
    useMyAdsMock.mockReturnValue(fakeQuery({ isPending: false, isError: false, data: [AD_A] }));
  });

  it("surfaces the real publish-status error message with its own retry", async () => {
    const refetch = vi.fn();
    usePublishStatusForAdMock.mockReturnValue(
      fakeQuery({ isPending: false, isError: true, error: new Error("status fetch failed"), refetch }),
    );
    renderView({ searchParams: new URLSearchParams("adId=ad-a") });
    expect(screen.getByText("status fetch failed")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(refetch).toHaveBeenCalledOnce();
  });

  it("shows an honest empty state — not four PENDING rows — when nothing has been published yet", async () => {
    usePublishStatusForAdMock.mockReturnValue(
      fakeQuery({
        isPending: false,
        isError: false,
        data: {
          adId: "ad-a",
          channels: [
            { channel: "TELEGRAM", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "INSTAGRAM", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "OLX", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "YOUTUBE", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
          ],
        },
      }),
    );
    const navigate = vi.fn();
    renderView({ searchParams: new URLSearchParams("adId=ad-a"), navigate });

    expect(screen.getByText("Not published anywhere yet")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Open in editor" }));
    expect(navigate).toHaveBeenCalledWith("/ads/ad-a/edit");
  });

  it("renders one row per real channel with real status/automation/external/last-attempt data, and keeps the accent to exactly the Retry CTA", () => {
    usePublishStatusForAdMock.mockReturnValue(
      fakeQuery({
        isPending: false,
        isError: false,
        data: {
          adId: "ad-a",
          channels: [
            {
              channel: "TELEGRAM",
              status: "PUBLISHED",
              externalUrl: "https://t.me/lacasa_tashkent/412",
              externalId: "412",
              lastAttemptAt: "2026-08-03T11:42:00Z",
              errorMessage: null,
            },
            {
              channel: "INSTAGRAM",
              status: "FAILED",
              externalUrl: null,
              externalId: null,
              lastAttemptAt: "2026-08-03T11:39:00Z",
              errorMessage: "IG token expired",
            },
            { channel: "OLX", status: "DRAFTED_AWAITING_REVIEW", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "YOUTUBE", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
          ],
        },
      }),
    );
    const { container } = renderView({ searchParams: new URLSearchParams("adId=ad-a") });

    const table = screen.getByRole("table");
    const rows = within(table).getAllByRole("row");
    // 1 header row + exactly 4 channel rows.
    expect(rows).toHaveLength(5);

    expect(within(table).getByText("Telegram")).toBeInTheDocument();
    expect(within(table).getByText("Published")).toBeInTheDocument();
    expect(within(table).getByText("t.me/lacasa_tashkent/412")).toBeInTheDocument();
    expect(within(table).getByRole("link", { name: "Open on Telegram" })).toHaveAttribute(
      "href",
      "https://t.me/lacasa_tashkent/412",
    );

    expect(within(table).getByText("Instagram")).toBeInTheDocument();
    expect(within(table).getByText("Failed")).toBeInTheDocument();
    expect(within(table).getByText("IG token expired")).toBeInTheDocument();
    expect(within(table).queryByRole("link", { name: "Open on Instagram" })).not.toBeInTheDocument();

    expect(within(table).getByText("Awaiting review")).toBeInTheDocument();
    expect(within(table).getByText("Not published")).toBeInTheDocument();

    // Accent discipline (PLAN.md §1): exactly one lime element on screen.
    const accentEls = container.querySelectorAll(".bg-accent");
    expect(accentEls).toHaveLength(1);
    expect(accentEls[0]).toHaveTextContent("Retry failed");
  });

  it("disables Retry failed and names the real gap, with a <Flag> only when a channel has actually failed", () => {
    usePublishStatusForAdMock.mockReturnValue(
      fakeQuery({
        isPending: false,
        isError: false,
        data: {
          adId: "ad-a",
          channels: [
            { channel: "TELEGRAM", status: "PUBLISHED", externalUrl: "https://t.me/x/1", externalId: "1", lastAttemptAt: null, errorMessage: null },
            { channel: "INSTAGRAM", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "OLX", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "YOUTUBE", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
          ],
        },
      }),
    );
    renderView({ searchParams: new URLSearchParams("adId=ad-a") });

    const retryButton = screen.getByRole("button", { name: "Retry failed" });
    expect(retryButton).toBeDisabled();
    expect(retryButton).toHaveAttribute("title", "No channel has failed for this ad.");
    expect(screen.queryByText(RETRY_GAP_MESSAGE)).not.toBeInTheDocument();
  });

  it("names the missing retry endpoint once a channel is actually FAILED", () => {
    usePublishStatusForAdMock.mockReturnValue(
      fakeQuery({
        isPending: false,
        isError: false,
        data: {
          adId: "ad-a",
          channels: [
            { channel: "TELEGRAM", status: "FAILED", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: "bot token invalid" },
            { channel: "INSTAGRAM", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "OLX", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
            { channel: "YOUTUBE", status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null },
          ],
        },
      }),
    );
    renderView({ searchParams: new URLSearchParams("adId=ad-a") });

    const retryButton = screen.getByRole("button", { name: "Retry failed" });
    expect(retryButton).toBeDisabled();
    expect(retryButton).toHaveAttribute("title", RETRY_GAP_MESSAGE);
    expect(screen.getByRole("note")).toHaveTextContent(RETRY_GAP_MESSAGE);
  });
});

describe("pure helpers", () => {
  it("adTitle falls back honestly instead of rendering a blank title", () => {
    expect(adTitle(makeAd({ id: "x", title: "Real title" }))).toBe("Real title");
    expect(adTitle(makeAd({ id: "x" }))).toBe("Untitled listing");
  });

  it("adReference is null (not a fabricated ref) when the ad has none", () => {
    expect(adReference(makeAd({ id: "x", reference: "a3f21" }))).toBe("a3f21");
    expect(adReference(makeAd({ id: "x" }))).toBeNull();
  });

  it("publishStatusView maps every known wire status", () => {
    expect(publishStatusView("PUBLISHED")).toEqual({ label: "Published", tone: "ok" });
    expect(publishStatusView("FAILED")).toEqual({ label: "Failed", tone: "err" });
    expect(publishStatusView("DRAFTED_AWAITING_REVIEW")).toEqual({ label: "Awaiting review", tone: "warn" });
    expect(publishStatusView("PENDING")).toEqual({ label: "Not published", tone: "mute" });
  });

  it("publishStatusView surfaces an unrecognized status verbatim instead of mislabeling it", () => {
    expect(publishStatusView("SOMETHING_NEW")).toEqual({ label: "SOMETHING_NEW", tone: "mute" });
  });
});
