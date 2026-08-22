/**
 * MyAdsScreen.test.tsx — renders the *real* screen tree (not a shallow
 * stand-in) against a fully mocked data layer. Every hook the screen calls
 * (`useMyAds`, `useDeleteAd`, `usePublishStatusForAds`, `useCoworkers`,
 * `useAuth`) is replaced with a `vi.fn()` so no real `@tanstack/react-
 * query`/`react-router-dom` code ever executes — both are hoisted to the
 * workspace root and pinned to a different React major there (see
 * testUtils.tsx's header), so even their *hooks* (not just their rendered
 * components) would hit the same "Invalid hook call"-class failure if
 * actually invoked inside this nested-React-19 tree. `@phosphor-icons/react`
 * is mocked at the source for the same underlying reason, one level up from
 * "pass a FakeIcon prop" (Table.test.tsx's approach): this suite renders the
 * whole screen, including primitives like RowActions/ErrorState that import
 * real Phosphor icons themselves rather than receiving them as props.
 */
import { act } from "react";
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { UseMutationResult, UseQueryResult } from "@tanstack/react-query";
import type { Ad, Coworker } from "@lacasa/api-client";
import type { ApiError } from "@lacasa/domain";
import { render } from "./testUtils";
import { makeAd, makeCoworker, makeUser } from "./fixtures";

// `@testing-library/user-event` normally gets its act()-wrapping for free
// from @testing-library/react's auto-configured asyncWrapper — not available
// here (see testUtils.tsx's header for why). These wrap each interaction in
// *this* file's own `act`, imported straight from 'react' the same way every
// src/ file resolves it, so state updates the click/select triggers flush
// before the next assertion runs.
async function click(element: Element) {
  await act(async () => {
    await userEvent.click(element);
  });
}
async function selectOption(element: Element, value: string) {
  await act(async () => {
    await userEvent.selectOptions(element, value);
  });
}

const hoisted = vi.hoisted(() => ({
  navigate: vi.fn(),
  useMyAds: vi.fn(),
  usePublishStatusForAds: vi.fn(),
  useCoworkers: vi.fn(),
  useAuth: vi.fn(),
  useDeleteAd: vi.fn(),
}));

vi.mock("react-router-dom", () => ({
  useNavigate: () => hoisted.navigate,
}));

vi.mock("@/data/useAds", () => ({
  useMyAds: hoisted.useMyAds,
  useDeleteAd: hoisted.useDeleteAd,
}));

vi.mock("@/data/usePublish", () => ({
  usePublishStatusForAds: hoisted.usePublishStatusForAds,
}));

vi.mock("@/data/useCoworkers", () => ({
  useCoworkers: hoisted.useCoworkers,
}));

vi.mock("@/lib/auth", () => ({
  useAuth: hoisted.useAuth,
}));

// A Proxy-based blanket stub here previously caused the whole worker to hang
// (Vitest's mock-module machinery evidently doesn't like an exotic object
// with no real own keys standing in for a package) — enumerated explicitly
// instead, one FakeIcon per name icons.ts re-exports, exactly mirroring the
// design-system agent's per-prop FakeIcon technique one level up (this
// suite renders the *whole* screen, so every icon icons.ts might resolve,
// not just the ones a single test passes as a prop, needs a stand-in).
vi.mock("@phosphor-icons/react", () => {
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="icon" {...props} />;
  return {
    ArrowLeftIcon: FakeIcon,
    ArrowRightIcon: FakeIcon,
    ArrowUpRightIcon: FakeIcon,
    BellIcon: FakeIcon,
    BroadcastIcon: FakeIcon,
    BuildingsIcon: FakeIcon,
    CameraIcon: FakeIcon,
    CaretDownIcon: FakeIcon,
    CaretUpDownIcon: FakeIcon,
    CheckCircleIcon: FakeIcon,
    CheckIcon: FakeIcon,
    ClockIcon: FakeIcon,
    EyeIcon: FakeIcon,
    FunnelIcon: FakeIcon,
    GearIcon: FakeIcon,
    HouseIcon: FakeIcon,
    InstagramLogoIcon: FakeIcon,
    KanbanIcon: FakeIcon,
    LinkSimpleIcon: FakeIcon,
    MagnifyingGlassIcon: FakeIcon,
    NotePencilIcon: FakeIcon,
    PaperPlaneTiltIcon: FakeIcon,
    PhoneIcon: FakeIcon,
    PlusIcon: FakeIcon,
    SquaresFourIcon: FakeIcon,
    StorefrontIcon: FakeIcon,
    TagIcon: FakeIcon,
    TelegramLogoIcon: FakeIcon,
    TrashIcon: FakeIcon,
    UploadSimpleIcon: FakeIcon,
    UserIcon: FakeIcon,
    UsersThreeIcon: FakeIcon,
    WarningIcon: FakeIcon,
    XIcon: FakeIcon,
    YoutubeLogoIcon: FakeIcon,
  };
});

// vi.mock calls above are hoisted above every import regardless of source
// order, so this import running "after" them is cosmetic, not load-bearing.
import { MyAdsScreen } from "../MyAdsScreen";

type PublishStatusMap = Record<string, Array<{ channel: string; status: string }>>;

function fakeQuery<T>(overrides: Partial<UseQueryResult<T>> = {}): UseQueryResult<T> {
  return {
    data: undefined,
    error: null,
    isLoading: false,
    isError: false,
    isPending: false,
    isSuccess: true,
    status: "success",
    refetch: vi.fn(),
    ...overrides,
  } as UseQueryResult<T>;
}

function fakeMutation(overrides: Partial<UseMutationResult<void, ApiError, string>> = {}): UseMutationResult<
  void,
  ApiError,
  string
> {
  return {
    mutate: vi.fn(),
    mutateAsync: vi.fn(),
    isPending: false,
    isError: false,
    isSuccess: false,
    error: null,
    reset: vi.fn(),
    ...overrides,
  } as UseMutationResult<void, ApiError, string>;
}

const javlon = makeUser({ fullName: "Javlon Rustamov", avatar: null });

beforeEach(() => {
  vi.clearAllMocks();
  hoisted.useMyAds.mockReturnValue(fakeQuery<Ad[]>({ data: [] }));
  hoisted.usePublishStatusForAds.mockReturnValue(fakeQuery<PublishStatusMap>({ data: {} }));
  hoisted.useCoworkers.mockReturnValue(fakeQuery<Coworker[]>({ data: [] }));
  hoisted.useAuth.mockReturnValue({ user: javlon, status: "authenticated", login: vi.fn(), logout: vi.fn() });
  hoisted.useDeleteAd.mockReturnValue(fakeMutation());
});

describe("MyAdsScreen — loading", () => {
  it("shows the table skeleton and no toolbar while the ads query is in flight", () => {
    hoisted.useMyAds.mockReturnValue(fakeQuery<Ad[]>({ data: undefined, isLoading: true, isSuccess: false }));
    const { container } = render(<MyAdsScreen />);
    expect(container.querySelectorAll("tbody tr")).toHaveLength(6);
    expect(screen.queryByRole("button", { name: "Add new post" })).not.toBeInTheDocument();
  });
});

describe("MyAdsScreen — error", () => {
  it("surfaces the real error message and retries via the query's own refetch", async () => {
    const refetch = vi.fn();
    hoisted.useMyAds.mockReturnValue(
      fakeQuery<Ad[]>({
        data: undefined,
        isLoading: false,
        isSuccess: false,
        isError: true,
        error: new Error("Network is down"),
        refetch,
      }),
    );
    render(<MyAdsScreen />);
    expect(screen.getByText("Network is down")).toBeInTheDocument();
    await click(screen.getByRole("button", { name: "Try again" }));
    expect(refetch).toHaveBeenCalledOnce();
  });
});

describe("MyAdsScreen — truly empty (no ads at all)", () => {
  it("shows EmptyState's own Add new post action and does not also render a Toolbar CTA", async () => {
    hoisted.useMyAds.mockReturnValue(fakeQuery<Ad[]>({ data: [] }));
    render(<MyAdsScreen />);
    expect(screen.getByText("No ads yet")).toBeInTheDocument();
    // Exactly one "Add new post" CTA on this screen's own content, and it's
    // `variant="dark"` in MyAdsScreen.tsx, not `primary` — the shell's global
    // Topbar CTA (a separate component this test doesn't render) already
    // owns the accent for this exact action on every screen, this one
    // included, so this one must not double up on lime.
    const ctas = screen.getAllByRole("button", { name: "Add new post" });
    expect(ctas).toHaveLength(1);
    await click(ctas[0] as HTMLElement);
    expect(hoisted.navigate).toHaveBeenCalledWith("/ads/new");
  });
});

describe("MyAdsScreen — populated", () => {
  const activeAd = makeAd({
    id: "ad-active",
    title: "Bright 3-room apartment in Chilonzor",
    district: "Chilonzor",
    rooms: 3,
    area: 65,
    stage: "1",
    price: 78000,
    priceType: "usd",
    category: "sale",
    coworkerId: null,
  });
  const soldAd = makeAd({
    id: "ad-sold",
    title: "Two-room flat in Mirobod",
    district: "Mirobod",
    rooms: 2,
    area: 54,
    stage: "2",
    price: 62500,
    priceType: "usd",
    category: "sale",
    coworkerId: "coworker-sardor",
  });
  const draftAd = makeAd({
    id: "ad-draft",
    title: "New-build 4-room in Yashnobod",
    district: "Yashnobod",
    rooms: 4,
    area: 88,
    stage: "3",
    price: 95000,
    priceType: "usd",
    category: "sale",
    coworkerId: null,
  });
  const sardor = makeCoworker({ id: "coworker-sardor", fullName: "Sardor Abdullayev", avatar: null });

  beforeEach(() => {
    hoisted.useMyAds.mockReturnValue(fakeQuery<Ad[]>({ data: [activeAd, soldAd, draftAd] }));
    hoisted.useCoworkers.mockReturnValue(fakeQuery<Coworker[]>({ data: [sardor] }));
  });

  it("derives live segmented counts from the fetched ads themselves", () => {
    render(<MyAdsScreen />);
    expect(screen.getByRole("button", { name: "All 3" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Active 1" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Sold 1" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Draft 1" })).toBeInTheDocument();
  });

  it("renders the listing subtitle, formatted price, and stage tag from real ad fields", () => {
    render(<MyAdsScreen />);
    expect(screen.getByText("Bright 3-room apartment in Chilonzor")).toBeInTheDocument();
    expect(screen.getByText("Chilonzor · 3 rooms · 65 m²")).toBeInTheDocument();
    expect(screen.getByText("$78,000")).toBeInTheDocument();
    expect(screen.getByText("Active")).toBeInTheDocument();
    expect(screen.getByText("Sold")).toBeInTheDocument();
    expect(screen.getByText("Draft")).toBeInTheDocument();
  });

  it("filters rows by stage via the segmented control, client-side, never changing the query args", async () => {
    render(<MyAdsScreen />);
    await click(screen.getByRole("button", { name: "Sold 1" }));
    expect(screen.queryByText("Bright 3-room apartment in Chilonzor")).not.toBeInTheDocument();
    expect(screen.getByText("Two-room flat in Mirobod")).toBeInTheDocument();
    // The stage filter is client-side (AdFilters has no `stage` param) — every
    // render of useMyAds, before and after the click, asks for the same
    // sort. (Call *count* isn't asserted: React re-invokes every hook,
    // mocked or not, on each state-driven re-render — that's normal, not a
    // refetch.)
    for (const call of hoisted.useMyAds.mock.calls) {
      expect(call[0]).toEqual({ sort: "newest" });
    }
  });

  it("shows a filtered-empty message (not the whole-screen EmptyState) when a stage has zero matches", async () => {
    hoisted.useMyAds.mockReturnValue(fakeQuery<Ad[]>({ data: [activeAd] }));
    render(<MyAdsScreen />);
    await click(screen.getByRole("button", { name: "Sold 0" }));
    expect(screen.getByText("No ads match this filter")).toBeInTheDocument();
    // The toolbar (and its CTA) stays — only the panel body swaps.
    expect(screen.getByRole("button", { name: "Add new post" })).toBeInTheDocument();
  });

  it("re-queries with the newly picked sort value", async () => {
    render(<MyAdsScreen />);
    const select = screen.getByLabelText("Sort ads");
    await selectOption(select, "highestPrice");
    const lastCall = hoisted.useMyAds.mock.calls.at(-1) as [{ sort: string }];
    expect(lastCall[0]).toEqual({ sort: "highestPrice" });
  });

  it("pre-selects the first (newest) row by default, mirroring the prototype's ad1001 convention", () => {
    render(<MyAdsScreen />);
    const activeRow = screen.getByText("Bright 3-room apartment in Chilonzor").closest("tr");
    const soldRow = screen.getByText("Two-room flat in Mirobod").closest("tr");
    expect(activeRow).toHaveAttribute("data-selected", "");
    expect(soldRow).not.toHaveAttribute("data-selected");
  });

  it("moves the accent-tinted selection to whichever row is clicked", async () => {
    render(<MyAdsScreen />);
    const activeRow = screen.getByText("Bright 3-room apartment in Chilonzor").closest("tr") as HTMLElement;
    const soldRow = screen.getByText("Two-room flat in Mirobod").closest("tr") as HTMLElement;
    await click(soldRow);
    expect(soldRow).toHaveAttribute("data-selected", "");
    expect(activeRow).not.toHaveAttribute("data-selected");
  });

  it("navigates to the editor and to publish status via row actions, without selecting the row", async () => {
    render(<MyAdsScreen />);
    // Uses the sold row, not the default-selected active row, so the
    // "row actions don't also select" assertion below is actually exercised
    // rather than trivially true because the row started selected anyway.
    const row = screen.getByText("Two-room flat in Mirobod").closest("tr") as HTMLElement;
    expect(row).not.toHaveAttribute("data-selected");

    await click(within(row).getByRole("button", { name: /^Edit /i }));
    expect(hoisted.navigate).toHaveBeenCalledWith("/ads/ad-sold/edit");
    expect(row).not.toHaveAttribute("data-selected");

    await click(within(row).getByRole("button", { name: /^View publish status for /i }));
    expect(hoisted.navigate).toHaveBeenCalledWith("/publish?adId=ad-sold");
  });

  it("resolves the Author cell to the assigned coworker, or the current agent when unassigned", () => {
    render(<MyAdsScreen />);
    // activeAd/draftAd have no coworkerId -> fall back to the signed-in agent.
    expect(screen.getAllByText("JR")).toHaveLength(2);
    // soldAd is assigned to Sardor.
    expect(screen.getByText("SA")).toBeInTheDocument();
  });

  it("shows nothing in the Channels cell while the batched publish-status query is still loading", () => {
    hoisted.usePublishStatusForAds.mockReturnValue(
      fakeQuery<PublishStatusMap>({ data: undefined, isLoading: true, isSuccess: false }),
    );
    render(<MyAdsScreen />);
    expect(screen.queryByText("—")).not.toBeInTheDocument();
    expect(screen.queryByText("IG")).not.toBeInTheDocument();
  });

  it("shows an em dash for an ad with no publish records once the query has loaded", () => {
    hoisted.usePublishStatusForAds.mockReturnValue(fakeQuery<PublishStatusMap>({ data: {} }));
    render(<MyAdsScreen />);
    expect(screen.getAllByText("—").length).toBeGreaterThan(0);
  });

  it("renders real channel badges from the batched publish-status response", () => {
    hoisted.usePublishStatusForAds.mockReturnValue(
      fakeQuery<PublishStatusMap>({
        data: {
          "ad-active": [
            { channel: "INSTAGRAM", status: "PUBLISHED" },
            { channel: "TELEGRAM", status: "PUBLISHED" },
          ],
        },
      }),
    );
    render(<MyAdsScreen />);
    expect(screen.getByText("IG")).toBeInTheDocument();
    expect(screen.getByText("TG")).toBeInTheDocument();
  });

  it("opens a confirm dialog on delete, cancels without mutating, then confirms and mutates", async () => {
    // Cast rather than fabricate react-query's full 4-arg onSuccess(data,
    // variables, onMutateResult, context) signature — MyAdsScreen only ever
    // calls onSuccess with no arguments, so the simplified shape below is
    // all this test needs to drive it.
    const mutate = vi.fn((id: string, opts?: { onSuccess?: () => void }) => {
      opts?.onSuccess?.();
    }) as unknown as UseMutationResult<void, ApiError, string>["mutate"];
    hoisted.useDeleteAd.mockReturnValue(fakeMutation({ mutate }));
    render(<MyAdsScreen />);
    const row = screen.getByText("Bright 3-room apartment in Chilonzor").closest("tr") as HTMLElement;

    await click(within(row).getByRole("button", { name: /^Delete /i }));
    expect(screen.getByRole("dialog")).toBeInTheDocument();

    await click(screen.getByRole("button", { name: "Cancel" }));
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    expect(mutate).not.toHaveBeenCalled();

    await click(within(row).getByRole("button", { name: /^Delete /i }));
    await click(screen.getByRole("button", { name: "Delete" }));
    expect(mutate).toHaveBeenCalledWith("ad-active", expect.anything());
    expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
  });
});
