/**
 * CoworkersScreen.test — exercises the four states (loading/error/empty/
 * populated), the two derived columns (Listings, Last active) against
 * hand-built Ad[]/CoworkerStatisticEvent[] fixtures, the honesty treatment
 * of the un-derivable Closed column, and the create/edit/delete flows.
 *
 * Every hook the screen reads from `@/data/*` and `@/lib/auth` is mocked —
 * this is a unit test of the screen's own rendering/derivation logic, not an
 * integration test of react-query or fetch. `@/data/useCoworkers` is only
 * *partially* mocked (`importOriginal` + spread) so `deriveCoworkerMetrics`
 * itself stays real: the Listings/Last-active assertions below are proving
 * the real derivation runs correctly against these fixtures, not a second
 * mock repeating what the screen is supposed to compute.
 *
 * `@/ui/icons` is also mocked, for an unrelated reason: this workspace has a
 * pre-existing react/react-dom version-hoisting conflict (see testUtils.tsx)
 * that makes every *real* `@phosphor-icons/react` component throw "A React
 * Element from an older version of React was rendered" the instant it
 * mounts, regardless of which root does the mounting — confirmed here empi-
 * rically the same way the design-system agent confirmed it for their own
 * suite. Design-system components like `Flag` import their icon (`EyeIcon`)
 * directly rather than taking it as a prop, so swapping in a `FakeIcon`
 * per-call-site (that suite's own workaround) isn't available to a screen
 * that renders `Flag` unmodified. Mocking the shared `@/ui/icons` barrel
 * intercepts every consumer's import of it — including `Flag.tsx`'s own
 * relative `from "./icons"`, since Vitest mocks by resolved module, not by
 * import specifier — without touching a single file outside this folder.
 */
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Ad, Coworker, CoworkerStatisticEvent } from "@lacasa/api-client";
import type { AuthContextValue } from "@/lib/auth";
import { useAuth } from "@/lib/auth";
import { useMyAds } from "@/data/useAds";
import { useCoworkerStatistics } from "@/data/useStatistics";
import { useCoworkers, useCreateCoworker, useDeleteCoworker, useUpdateCoworker } from "@/data/useCoworkers";
import { CoworkersScreen } from "../CoworkersScreen";
import { render } from "./testUtils";

vi.mock("@/lib/auth", () => ({ useAuth: vi.fn() }));
vi.mock("@/data/useAds", () => ({ useMyAds: vi.fn() }));
vi.mock("@/data/useStatistics", () => ({ useCoworkerStatistics: vi.fn() }));
vi.mock("@/data/useCoworkers", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/data/useCoworkers")>();
  return {
    ...actual, // keeps the real, pure deriveCoworkerMetrics
    useCoworkers: vi.fn(),
    useCreateCoworker: vi.fn(),
    useDeleteCoworker: vi.fn(),
    useUpdateCoworker: vi.fn(),
  };
});

vi.mock("@/ui/icons", () => {
  function icon(name: string) {
    return function MockIcon(props: Record<string, unknown>) {
      return <svg data-testid={`icon-${name}`} {...props} />;
    };
  }
  return {
    ArrowLeftIcon: icon("ArrowLeftIcon"),
    ArrowRightIcon: icon("ArrowRightIcon"),
    ArrowUpRightIcon: icon("ArrowUpRightIcon"),
    BellIcon: icon("BellIcon"),
    BroadcastIcon: icon("BroadcastIcon"),
    BuildingsIcon: icon("BuildingsIcon"),
    CameraIcon: icon("CameraIcon"),
    CaretDownIcon: icon("CaretDownIcon"),
    CaretUpDownIcon: icon("CaretUpDownIcon"),
    CheckCircleIcon: icon("CheckCircleIcon"),
    CheckIcon: icon("CheckIcon"),
    ClockIcon: icon("ClockIcon"),
    EyeIcon: icon("EyeIcon"),
    FunnelIcon: icon("FunnelIcon"),
    GearIcon: icon("GearIcon"),
    HouseIcon: icon("HouseIcon"),
    InstagramLogoIcon: icon("InstagramLogoIcon"),
    KanbanIcon: icon("KanbanIcon"),
    LinkSimpleIcon: icon("LinkSimpleIcon"),
    MagnifyingGlassIcon: icon("MagnifyingGlassIcon"),
    NotePencilIcon: icon("NotePencilIcon"),
    PaperPlaneTiltIcon: icon("PaperPlaneTiltIcon"),
    PhoneIcon: icon("PhoneIcon"),
    PlusIcon: icon("PlusIcon"),
    SquaresFourIcon: icon("SquaresFourIcon"),
    StorefrontIcon: icon("StorefrontIcon"),
    TagIcon: icon("TagIcon"),
    TelegramLogoIcon: icon("TelegramLogoIcon"),
    TrashIcon: icon("TrashIcon"),
    UploadSimpleIcon: icon("UploadSimpleIcon"),
    UserIcon: icon("UserIcon"),
    UsersThreeIcon: icon("UsersThreeIcon"),
    WarningIcon: icon("WarningIcon"),
    XIcon: icon("XIcon"),
    YoutubeLogoIcon: icon("YoutubeLogoIcon"),
  };
});

const AGENT = {
  id: "agent1",
  fullName: "Javlon Rustamov",
  email: "javlon@lacasa.uz",
  phoneNumber: null,
  role: "AGENT",
};

const COWORKER_A: Coworker = {
  id: "cw1",
  fullName: "Sardor Abdullayev",
  email: "sardor@lacasa.uz",
  phoneNumber: "+998901112233",
  avatar: null,
  agentId: "agent1",
};

const COWORKER_B: Coworker = {
  id: "cw2",
  fullName: "Kamola Rashidova",
  email: "kamola@lacasa.uz",
  phoneNumber: "+998904445566",
  avatar: null,
  agentId: "agent1",
};

function makeAd(id: string, coworkerId: string | null): Ad {
  return {
    id,
    agentId: "agent1",
    coworkerId,
    photos: [],
    media: [],
    lat: null,
    lng: null,
    tour3dLink: null,
  };
}

function makeEvent(id: string, coworkerId: string, isoDate: string): CoworkerStatisticEvent {
  return {
    id,
    agentId: "agent1",
    coworkerId,
    adId: "",
    leadId: "",
    stage: "NEW",
    createdAt: { seconds: Math.floor(new Date(isoDate).getTime() / 1000) },
  };
}

function authResult(overrides: Partial<AuthContextValue> = {}): AuthContextValue {
  return {
    user: AGENT,
    status: "authenticated",
    login: vi.fn(),
    logout: vi.fn(),
    ...overrides,
  } as unknown as AuthContextValue;
}

function coworkersResult(
  overrides: Partial<ReturnType<typeof useCoworkers>> = {},
): ReturnType<typeof useCoworkers> {
  return {
    data: [COWORKER_A, COWORKER_B],
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
    ...overrides,
  } as unknown as ReturnType<typeof useCoworkers>;
}

function adsResult(overrides: Partial<ReturnType<typeof useMyAds>> = {}): ReturnType<typeof useMyAds> {
  return {
    data: [],
    isLoading: false,
    isError: false,
    ...overrides,
  } as unknown as ReturnType<typeof useMyAds>;
}

function statsResult(
  overrides: Partial<ReturnType<typeof useCoworkerStatistics>> = {},
): ReturnType<typeof useCoworkerStatistics> {
  return {
    data: [],
    isLoading: false,
    isError: false,
    ...overrides,
  } as unknown as ReturnType<typeof useCoworkerStatistics>;
}

function mutationResult<T>(overrides: Record<string, unknown> = {}): T {
  return {
    mutate: vi.fn(),
    isPending: false,
    error: undefined,
    ...overrides,
  } as unknown as T;
}

beforeEach(() => {
  vi.mocked(useAuth).mockReturnValue(authResult());
  vi.mocked(useCoworkers).mockReturnValue(coworkersResult());
  vi.mocked(useMyAds).mockReturnValue(adsResult());
  vi.mocked(useCoworkerStatistics).mockReturnValue(statsResult());
  vi.mocked(useCreateCoworker).mockReturnValue(mutationResult<ReturnType<typeof useCreateCoworker>>());
  vi.mocked(useDeleteCoworker).mockReturnValue(mutationResult<ReturnType<typeof useDeleteCoworker>>());
  vi.mocked(useUpdateCoworker).mockReturnValue(mutationResult<ReturnType<typeof useUpdateCoworker>>());
});

afterEach(() => {
  vi.useRealTimers();
});

describe("CoworkersScreen — loading state", () => {
  it("shows a table skeleton and withholds the ghost row / honesty flag until data is real", () => {
    vi.mocked(useCoworkers).mockReturnValue(coworkersResult({ data: undefined, isLoading: true }));
    const { container } = render(<CoworkersScreen />);

    expect(container.querySelectorAll("tbody tr td .animate-pulse").length).toBeGreaterThan(0);
    expect(screen.queryByRole("button", { name: "Create coworker" })).not.toBeInTheDocument();
    expect(screen.queryByText(/LeadStatus.SUCCESS/)).not.toBeInTheDocument();
  });
});

describe("CoworkersScreen — error state", () => {
  it("surfaces the real error message and retries via refetch", async () => {
    const refetch = vi.fn();
    vi.mocked(useCoworkers).mockReturnValue(
      coworkersResult({ data: undefined, isError: true, error: new Error("Network down"), refetch }),
    );
    render(<CoworkersScreen />);

    expect(screen.getByText("Network down")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Try again" }));
    expect(refetch).toHaveBeenCalledOnce();
  });
});

describe("CoworkersScreen — empty state", () => {
  it("renders zero data rows plus the create ghost row, honestly, not a fabricated example row", () => {
    vi.mocked(useCoworkers).mockReturnValue(coworkersResult({ data: [] }));
    render(<CoworkersScreen />);

    expect(screen.getByText(/No coworkers yet/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create coworker" })).toBeInTheDocument();
    expect(screen.queryByText("sardor@lacasa.uz")).not.toBeInTheDocument();
  });
});

describe("CoworkersScreen — populated state", () => {
  it("derives Listings from useMyAds by coworkerId, not from the Coworker payload", () => {
    vi.mocked(useMyAds).mockReturnValue(
      adsResult({
        data: [
          makeAd("ad1", "cw1"),
          makeAd("ad2", "cw1"),
          makeAd("ad3", "cw1"),
          makeAd("ad4", "cw2"),
          makeAd("ad5", null), // unassigned — must not count toward either coworker
        ],
      }),
    );
    render(<CoworkersScreen />);

    const rowA = screen.getByText("Sardor Abdullayev").closest("tr");
    const rowB = screen.getByText("Kamola Rashidova").closest("tr");
    expect(rowA).not.toBeNull();
    expect(rowB).not.toBeNull();
    expect(within(rowA as HTMLElement).getByText("3")).toBeInTheDocument();
    expect(within(rowB as HTMLElement).getByText("1")).toBeInTheDocument();
  });

  it("derives Last active from the newest CoworkerStatisticEvent, and em-dashes a coworker with none", () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-08-05T12:00:00.000Z"));
    vi.mocked(useCoworkerStatistics).mockReturnValue(
      statsResult({
        data: [
          makeEvent("ev1", "cw1", "2026-08-04T12:00:00.000Z"), // 1 day ago — older
          makeEvent("ev2", "cw1", "2026-08-05T10:00:00.000Z"), // 2 hours ago — newest
        ],
      }),
    );
    render(<CoworkersScreen />);

    const rowA = screen.getByText("Sardor Abdullayev").closest("tr") as HTMLElement;
    const rowB = screen.getByText("Kamola Rashidova").closest("tr") as HTMLElement;
    expect(within(rowA).getByText("2 h ago")).toBeInTheDocument();
    // cw2 has zero events — must read as "no data", never a fabricated "Today".
    const lastActiveCellB = within(rowB).getAllByRole("cell").at(-2);
    expect(lastActiveCellB?.textContent).toBe("—");
  });

  it("never renders a Closed number — it flags the missing LeadStatus.SUCCESS enum member instead", () => {
    render(<CoworkersScreen />);

    const cells = screen.getAllByRole("columnheader", { name: "Closed" });
    expect(cells).toHaveLength(1);
    const rows = screen.getAllByRole("row").slice(1, 3); // skip the header row
    for (const row of rows) {
      const closedCell = within(row).getAllByRole("cell").at(-3);
      expect(closedCell?.textContent).toBe("—");
    }
    expect(screen.getByText(/LeadStatus.SUCCESS/)).toBeInTheDocument();
  });

  it("shows '…' (not a fabricated 0) while the secondary ads/stats queries are still loading", () => {
    vi.mocked(useMyAds).mockReturnValue(adsResult({ data: undefined, isLoading: true }));
    vi.mocked(useCoworkerStatistics).mockReturnValue(statsResult({ data: undefined, isLoading: true }));
    render(<CoworkersScreen />);

    const rowA = screen.getByText("Sardor Abdullayev").closest("tr") as HTMLElement;
    expect(within(rowA).getAllByText("…")).toHaveLength(2); // listings + last active
  });

  it("shows '—' (not a fabricated 0) when the secondary ads/stats queries fail", () => {
    vi.mocked(useMyAds).mockReturnValue(adsResult({ data: undefined, isError: true }));
    vi.mocked(useCoworkerStatistics).mockReturnValue(statsResult({ data: undefined, isError: true }));
    render(<CoworkersScreen />);

    const rowA = screen.getByText("Sardor Abdullayev").closest("tr") as HTMLElement;
    const cellsA = within(rowA).getAllByRole("cell");
    // Listings (index -4) and Last active (index -2) both read "—", same as
    // the honestly-empty Closed column next to them — a reader can't tell
    // "failed to load" from "genuinely nothing" apart by symbol, only by
    // knowing the column; that's an acceptable ambiguity for a value that
    // was never going to be fabricated either way.
    expect(cellsA.at(-4)?.textContent).toBe("—");
    expect(cellsA.at(-2)?.textContent).toBe("—");
  });

  it("keeps the accent to exactly the ghost row — no other bg-accent element on screen", () => {
    const { container } = render(<CoworkersScreen />);
    const accentEls = [...container.querySelectorAll("*")].filter((el) =>
      el.className.toString().split(/\s+/).includes("bg-accent"),
    );
    expect(accentEls).toHaveLength(0); // GhostRow uses bg-accent-tint + hover:bg-accent, not a bare bg-accent
    const tintEls = [...container.querySelectorAll("button")].filter((el) =>
      el.className.includes("bg-accent-tint"),
    );
    expect(tintEls).toHaveLength(1);
    expect(tintEls[0]).toHaveTextContent("Create coworker");
  });
});

describe("CoworkersScreen — create flow", () => {
  it("opens the create modal from the ghost row and submits a real CoworkerCreateInput", async () => {
    const mutate = vi.fn();
    vi.mocked(useCreateCoworker).mockReturnValue(
      mutationResult<ReturnType<typeof useCreateCoworker>>({ mutate }),
    );
    render(<CoworkersScreen />);

    await userEvent.click(screen.getByRole("button", { name: "Create coworker" }));
    const dialog = screen.getByRole("dialog", { name: "Create coworker" });
    expect(dialog).toBeInTheDocument();

    await userEvent.type(screen.getByLabelText("Full name"), "Ravshan Ismoilov");
    await userEvent.type(screen.getByLabelText("Email"), "ravshan@lacasa.uz");
    await userEvent.type(screen.getByLabelText("Phone"), "+998901234567");
    await userEvent.type(screen.getByLabelText("Password"), "secret1");
    await userEvent.click(within(dialog).getByRole("button", { name: "Create coworker" }));

    expect(mutate).toHaveBeenCalledTimes(1);
    const [input] = mutate.mock.calls[0] as [Record<string, unknown>];
    expect(input).toMatchObject({
      fullName: "Ravshan Ismoilov",
      email: "ravshan@lacasa.uz",
      phoneNumber: "+998901234567",
      password: "secret1",
    });
  });
});

describe("CoworkersScreen — edit flow", () => {
  it("opens the edit modal pre-filled from the row and submits id + a real CoworkerUpdateInput", async () => {
    const mutate = vi.fn();
    vi.mocked(useUpdateCoworker).mockReturnValue(
      mutationResult<ReturnType<typeof useUpdateCoworker>>({ mutate }),
    );
    render(<CoworkersScreen />);

    await userEvent.click(screen.getByRole("button", { name: "Edit Sardor Abdullayev" }));
    expect(screen.getByRole("dialog", { name: "Edit coworker" })).toBeInTheDocument();
    expect(screen.getByLabelText("Full name")).toHaveValue("Sardor Abdullayev");
    expect(screen.getByLabelText("Email")).toHaveValue("sardor@lacasa.uz");

    await userEvent.click(screen.getByRole("button", { name: "Save changes" }));

    expect(mutate).toHaveBeenCalledTimes(1);
    const [variables] = mutate.mock.calls[0] as [{ id: string; input: Record<string, unknown> }];
    expect(variables.id).toBe("cw1");
    expect(variables.input).toMatchObject({ fullName: "Sardor Abdullayev", email: "sardor@lacasa.uz" });
    // blank password on edit means "keep the current one" — must not send one
    expect(variables.input).not.toHaveProperty("password");
  });

  it("sends an explicit empty phoneNumber when the agent clears it, instead of silently omitting the key", async () => {
    const mutate = vi.fn();
    vi.mocked(useUpdateCoworker).mockReturnValue(
      mutationResult<ReturnType<typeof useUpdateCoworker>>({ mutate }),
    );
    render(<CoworkersScreen />);

    await userEvent.click(screen.getByRole("button", { name: "Edit Sardor Abdullayev" }));
    const phoneField = screen.getByLabelText("Phone");
    expect(phoneField).toHaveValue("+998901112233");
    await userEvent.clear(phoneField);
    await userEvent.click(screen.getByRole("button", { name: "Save changes" }));

    expect(mutate).toHaveBeenCalledTimes(1);
    const [variables] = mutate.mock.calls[0] as [{ id: string; input: Record<string, unknown> }];
    // '' must be a present key, not dropped by `|| undefined` — an absent
    // key is a no-op on the server (apps/api/src/routes/coworkers.js only
    // writes phoneNumber `if (phoneNumber !== undefined)`), which would
    // leave the old number in place while the UI reports success.
    expect(variables.input).toHaveProperty("phoneNumber", "");
  });
});

describe("CoworkersScreen — delete flow", () => {
  it("requires confirmation before calling useDeleteCoworker", async () => {
    const mutate = vi.fn();
    vi.mocked(useDeleteCoworker).mockReturnValue(
      mutationResult<ReturnType<typeof useDeleteCoworker>>({ mutate }),
    );
    render(<CoworkersScreen />);

    await userEvent.click(screen.getByRole("button", { name: "Delete Kamola Rashidova" }));
    const dialog = screen.getByRole("dialog", { name: "Delete coworker" });
    expect(dialog).toBeInTheDocument();
    expect(mutate).not.toHaveBeenCalled(); // clicking the row action alone must not delete anything

    await userEvent.click(within(dialog).getByRole("button", { name: "Delete coworker" }));
    expect(mutate).toHaveBeenCalledWith("cw2", expect.anything());
  });
});
