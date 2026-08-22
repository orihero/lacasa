/**
 * ListingEditorScreen.test.tsx — renders the real `ListingEditorView` (see
 * that file's header for why `ListingEditorScreen` itself, the router-wired
 * wrapper, isn't rendered here — same split/reasoning as
 * `publishStatus/PublishStatusScreen.tsx`) against a mocked data layer.
 *
 * `@tanstack/react-query` is mocked wholesale (not just spied on) because
 * this screen's own Save mutation is a local `useMutation` call (mirroring
 * `leads/CreateLeadModal.tsx`'s own pattern — `src/data/useAds.ts`
 * deliberately has no `useCreateAd`/`useUpdateAd` hook) — same approach
 * `leads/__tests__/LeadsScreen.test.tsx` takes for `CreateLeadModal`'s own
 * mutation.
 */
import { act } from "react";
import { screen, within } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { UseQueryResult } from "@tanstack/react-query";
import type { Ad, Coworker, InstagramAccount } from "@lacasa/api-client";
import { render } from "./testUtils";
import { makeAd, makeCoworker } from "./fixtures";

vi.mock("@/ui/icons", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/ui/icons")>();
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="fake-icon" {...props} />;
  return { ...actual, ...Object.fromEntries(Object.keys(actual).map((key) => [key, FakeIcon])) };
});

vi.mock("@/data/useAds", () => ({ useAd: vi.fn(), useDeleteAd: vi.fn() }));
vi.mock("@/data/useCoworkers", () => ({ useCoworkers: vi.fn() }));
vi.mock("@/data/useConnectedAccounts", () => ({ useInstagramAccounts: vi.fn() }));
vi.mock("@/lib/auth", () => ({ useAuth: vi.fn() }));

const mockMutate = vi.fn();
const mockInvalidateQueries = vi.fn();
let mutationState = { isPending: false, isError: false, error: null as { message: string } | null };

vi.mock("@tanstack/react-query", () => ({
  useMutation: () => ({
    mutate: mockMutate,
    isPending: mutationState.isPending,
    isError: mutationState.isError,
    error: mutationState.error,
  }),
  useQueryClient: () => ({ invalidateQueries: mockInvalidateQueries }),
}));

import { useAd, useDeleteAd } from "@/data/useAds";
import { useCoworkers } from "@/data/useCoworkers";
import { useInstagramAccounts } from "@/data/useConnectedAccounts";
import { useAuth } from "@/lib/auth";
import { ListingEditorView } from "../ListingEditorScreen";

const useAdMock = vi.mocked(useAd);
const useDeleteAdMock = vi.mocked(useDeleteAd);
const useCoworkersMock = vi.mocked(useCoworkers);
const useInstagramAccountsMock = vi.mocked(useInstagramAccounts);
const useAuthMock = vi.mocked(useAuth);

function fakeQuery<T>(fields: Partial<UseQueryResult<T>> & { data?: T } = {}): UseQueryResult<T> {
  return {
    isLoading: false,
    isError: false,
    data: undefined,
    error: null,
    refetch: vi.fn(),
    ...fields,
  } as unknown as UseQueryResult<T>;
}

function renderView({
  adId,
  navigate = vi.fn(),
}: {
  adId?: string;
  navigate?: ReturnType<typeof vi.fn>;
} = {}) {
  const utils = render(<ListingEditorView navigate={navigate} adId={adId} />);
  return { ...utils, navigate };
}

async function act1(fn: () => void | Promise<void>) {
  await act(async () => {
    await fn();
  });
}

beforeEach(() => {
  mockMutate.mockReset();
  mockInvalidateQueries.mockReset();
  mutationState = { isPending: false, isError: false, error: null };

  useAdMock.mockReset();
  useDeleteAdMock.mockReset();
  useCoworkersMock.mockReset();
  useInstagramAccountsMock.mockReset();
  useAuthMock.mockReset();

  useAdMock.mockReturnValue(fakeQuery<Ad>());
  useDeleteAdMock.mockReturnValue({ mutate: vi.fn(), isPending: false, isError: false, error: null } as never);
  useCoworkersMock.mockReturnValue(fakeQuery<Coworker[]>({ data: [] }));
  useInstagramAccountsMock.mockReturnValue(fakeQuery<InstagramAccount[]>({ data: [] }));
  useAuthMock.mockReturnValue({
    user: { id: "agent-1", fullName: "Javlon Rustamov", tgChatIds: [] },
    status: "authenticated",
    login: vi.fn(),
    logout: vi.fn(),
  } as never);
});

describe("create mode (/ads/new)", () => {
  it("renders a blank form with no Delete button and no status tag", () => {
    const { container } = renderView({ adId: undefined });
    expect(screen.getByLabelText("Title")).toHaveValue("");
    expect(screen.queryByRole("button", { name: "Delete" })).not.toBeInTheDocument();
    // The toolbar's stage Tag only exists once a real Ad has loaded — the
    // VisibilityPanel's own "Active" switch label still renders (it's a
    // real, independent field a new ad can set before its first save), so
    // this scopes to the Tag's own tone class rather than the ambiguous
    // "Active" text.
    expect(container.querySelector(".bg-ok-soft")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Save" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Save draft" })).toBeInTheDocument();
  });

  it("navigates to /ads via the My ads button without saving anything", async () => {
    const navigate = vi.fn();
    renderView({ navigate });
    await act1(() => userEvent.click(screen.getByRole("button", { name: "My ads" })));
    expect(navigate).toHaveBeenCalledWith("/ads");
    expect(mockMutate).not.toHaveBeenCalled();
  });

  it("shows inline required-field errors and does not call the mutation on an incomplete Save", async () => {
    renderView();
    await act1(() => userEvent.click(screen.getByRole("button", { name: "Save" })));
    expect(screen.getByText("Title is required.")).toBeInTheDocument();
    expect(screen.getByText("City is required.")).toBeInTheDocument();
    expect(mockMutate).not.toHaveBeenCalled();
  });

  it("shows Type/Category errors and does not call the mutation when only those two are missing", async () => {
    // Regression: Save used to silently no-op here — no error, no mutate —
    // because form.type/category were gated by a second check outside
    // validateForm's error set (see adFormFields.ts's validateForm comment).
    renderView();
    await act1(() => userEvent.type(screen.getByLabelText("Title"), "Bright 3-room apartment"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("City"), "Toshkent shahri"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("District"), "Chilonzor tumani"));
    await act1(() => userEvent.type(screen.getByLabelText("Price"), "78000"));

    await act1(() => userEvent.click(screen.getByRole("button", { name: "Save" })));

    expect(screen.getByText("Type is required.")).toBeInTheDocument();
    expect(screen.getByText("Category is required.")).toBeInTheDocument();
    expect(mockMutate).not.toHaveBeenCalled();
  });

  it("submits a real AdInput (stage '1') once every required field is filled", async () => {
    renderView();

    await act1(() => userEvent.type(screen.getByLabelText("Title"), "Bright 3-room apartment"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("City"), "Toshkent shahri"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("District"), "Chilonzor tumani"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("Type"), "residential"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("Category"), "sale"));
    await act1(() => userEvent.type(screen.getByLabelText("Price"), "78000"));

    await act1(() => userEvent.click(screen.getByRole("button", { name: "Save" })));

    expect(mockMutate).toHaveBeenCalledTimes(1);
    const input = mockMutate.mock.calls[0]![0];
    expect(input).toMatchObject({
      title: "Bright 3-room apartment",
      city: "Toshkent shahri",
      district: "Chilonzor tumani",
      type: "residential",
      category: "sale",
      price: 78000,
      stage: "1",
    });
  });

  it("Save draft skips the required-field errors and forces stage '3'", async () => {
    renderView();
    await act1(() => userEvent.click(screen.getByRole("button", { name: "Save draft" })));

    expect(screen.queryByText("Title is required.")).not.toBeInTheDocument();
    expect(mockMutate).toHaveBeenCalledTimes(1);
    expect(mockMutate.mock.calls[0]![0]).toMatchObject({ stage: "3" });
  });

  it("the Mark as sold switch flips the saved stage to '2'", async () => {
    renderView();
    await act1(() => userEvent.type(screen.getByLabelText("Title"), "T"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("City"), "Toshkent shahri"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("District"), "Chilonzor tumani"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("Type"), "residential"));
    await act1(() => userEvent.selectOptions(screen.getByLabelText("Category"), "sale"));
    await act1(() => userEvent.type(screen.getByLabelText("Price"), "1"));
    await act1(() => userEvent.click(screen.getByRole("switch", { name: "Mark as sold" })));

    await act1(() => userEvent.click(screen.getByRole("button", { name: "Save" })));
    expect(mockMutate.mock.calls[0]![0]).toMatchObject({ stage: "2" });
  });

  it("surfaces a real save-mutation error inline, not a toast", () => {
    mutationState = { isPending: false, isError: true, error: { message: "Network down" } };
    renderView();
    expect(screen.getByRole("alert")).toHaveTextContent("Network down");
  });
});

describe("edit mode (/ads/:id/edit)", () => {
  it("shows a loading state while the ad is still loading", () => {
    useAdMock.mockReturnValue(fakeQuery<Ad>({ isLoading: true }));
    renderView({ adId: "ad-1001" });
    expect(screen.getByText("Loading listing…")).toBeInTheDocument();
  });

  it("surfaces the real error and wires retry to refetch()", async () => {
    const refetch = vi.fn();
    useAdMock.mockReturnValue(fakeQuery<Ad>({ isError: true, error: new Error("boom"), refetch }));
    renderView({ adId: "ad-1001" });
    expect(screen.getByText("boom")).toBeInTheDocument();
    await act1(() => userEvent.click(screen.getByRole("button", { name: "Try again" })));
    expect(refetch).toHaveBeenCalledOnce();
  });

  it("prefills every real field from the fetched Ad and shows the status tag + reference", () => {
    useAdMock.mockReturnValue(fakeQuery<Ad>({ data: makeAd() }));
    const { container } = renderView({ adId: "ad-1001" });

    expect(screen.getByLabelText("Title")).toHaveValue("Bright 3-room apartment in Chilonzor");
    expect(screen.getByLabelText("City")).toHaveValue("Toshkent shahri");
    expect(screen.getByLabelText("District")).toHaveValue("Chilonzor tumani");
    expect(screen.getByLabelText("Price")).toHaveValue(78000);
    // The stage Tag (tone "ok" for stage '1') — not the VisibilityPanel's
    // own, separately-real "Active" switch label, hence scoped by class.
    expect(container.querySelector(".bg-ok-soft")).toHaveTextContent("Active");
    expect(screen.getByText(/#a3f21/)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Delete" })).toBeInTheDocument();
  });

  it("shows Unassigned when the ad has no coworkerId, and the real name when it does", () => {
    useAdMock.mockReturnValue(fakeQuery<Ad>({ data: makeAd({ coworkerId: "" }) }));
    const { unmount } = renderView({ adId: "ad-1001" });
    expect(screen.getByText("Unassigned")).toBeInTheDocument();
    unmount();

    useAdMock.mockReturnValue(fakeQuery<Ad>({ data: makeAd({ coworkerId: "coworker-sardor" }) }));
    useCoworkersMock.mockReturnValue(fakeQuery<Coworker[]>({ data: [makeCoworker()] }));
    renderView({ adId: "ad-1001" });
    expect(screen.getByText("Sardor Abdullayev")).toBeInTheDocument();
  });

  it("opens a real confirm dialog on Delete and calls useDeleteAd().mutate with the real id", async () => {
    useAdMock.mockReturnValue(fakeQuery<Ad>({ data: makeAd({ id: "ad-1001" }) }));
    const deleteMutate = vi.fn();
    useDeleteAdMock.mockReturnValue({ mutate: deleteMutate, isPending: false, isError: false, error: null } as never);
    const navigate = vi.fn();
    renderView({ adId: "ad-1001", navigate });

    await act1(() => userEvent.click(screen.getByRole("button", { name: "Delete" })));
    const dialog = screen.getByRole("dialog", { name: "Delete this listing?" });
    await act1(() => userEvent.click(within(dialog).getByRole("button", { name: "Delete" })));

    expect(deleteMutate).toHaveBeenCalledWith("ad-1001", expect.anything());
  });
});

describe("data-honesty gaps", () => {
  it("flags the 360° panorama roadmap proposal in the media panel", () => {
    renderView();
    const notes = screen.getAllByRole("note");
    expect(notes.some((n) => n.textContent?.includes("360° panorama is a roadmap proposal"))).toBe(true);
  });

  it("disables 'Publish to N channels' and names the real multi-channel-publish gap", () => {
    renderView();
    const publishButton = screen.getByRole("button", { name: /Publish to \d channels?/ });
    expect(publishButton).toBeDisabled();
    expect(publishButton).toHaveAttribute("title", expect.stringContaining("No endpoint publishes to multiple channels"));
  });

  it("renders the OLX row as non-interactive (disabled checkbox, no onChange it could fake-fire)", () => {
    renderView();
    const olxCheckbox = screen.getByRole("checkbox", { name: "OLX (requires the browser extension)" });
    expect(olxCheckbox).toBeDisabled();
  });
});
