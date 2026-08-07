// Drives LeadKanbanList's REAL onCardDragEnd wiring (handleCardMove, as
// actually passed to ControlledBoard) rather than re-testing
// resolveCardMoveAction's branching in isolation — that pure predicate
// already has its own coverage in packages/domain/src/leads/transitions.test.ts.
// What this test proves is that the component wires that decision into the
// right side effects: an immediate PATCH for a plain move, and a modal
// (no PATCH yet) for the two columns that require confirmation first.
//
// Actually dragging a card through @hello-pangea/dnd's pointer/keyboard
// sensors isn't reliably simulatable under jsdom, so ControlledBoard is
// replaced with a minimal stand-in that captures the exact `onCardDragEnd`
// function LeadKanbanList passed it — the test then calls that captured
// function directly, exercising handleCardMove's real closure (real
// `updateLeadById`, real `setKanbanBoard`/`setOpen`/`setOpenModalType`)
// exactly as ControlledBoard would.
import { render, screen, waitFor } from "@testing-library/react";
import { HttpResponse, http } from "msw";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Lead } from "@lacasa/api-client";
import "../../i18n";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
import { useLeadStore } from "../../lib/useLeadStore";
import { useUserStore } from "../../lib/userStore";
import { API_BASE, server } from "../../test-utils/msw";

let capturedOnCardDragEnd: any;

vi.mock("@caldwell619/react-kanban", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@caldwell619/react-kanban")>();
  return {
    ...actual,
    ControlledBoard: (props: any) => {
      capturedOnCardDragEnd = props.onCardDragEnd;
      return (
        <div data-testid="kanban-board">
          {props.children.columns.map((column: any) => (
            <div key={column.id} data-testid={`column-${column.id}`}>
              {column.cards.map((card: any) => (
                <div key={card.id} data-testid={`card-${card.id}`}>
                  {card.title}
                </div>
              ))}
            </div>
          ))}
        </div>
      );
    },
  };
});

const LEAD: Lead = {
  id: "lead-1",
  fullName: "Bob Builder",
  phone: "+998901234567",
  email: null,
  budget: null,
  comment: null,
  conversationComment: null,
  status: "new",
  source: null,
  callbackDate: null,
  active: true,
  agentId: "agent-1",
  coworkerId: "cw-1",
  createdAt: { seconds: 0 },
  updatedAt: { seconds: 0 },
};

async function renderBoard() {
  const { default: LeadKanbanList } = await import("./LeadKanbanList");
  render(
    <MemoryRouter>
      <LeadKanbanList />
    </MemoryRouter>,
  );
  await screen.findByTestId(`card-${LEAD.id}`);
}

describe("LeadKanbanList — real onCardDragEnd wiring (resolveCardMoveAction)", () => {
  let patchCalls: Array<{ id: string; body: any }>;

  beforeEach(() => {
    patchCalls = [];
    capturedOnCardDragEnd = undefined;
    useUserStore.setState({ currentUser: { id: "agent-1", role: "agent" }, isLoading: false });
    useLeadStore.setState({ list: [], isLoading: true, lead: {}, isUpdated: false });
    useCoworkerStore.setState({ list: [], isLoading: true, coworker: {} });

    server.use(
      http.get(`${API_BASE}/leads`, () => HttpResponse.json([LEAD])),
      http.get(`${API_BASE}/coworkers`, () =>
        HttpResponse.json([{ id: "cw-1", fullName: "Coworker One", email: "cw@x.com", phoneNumber: null, avatar: null, agentId: "agent-1" }]),
      ),
      http.patch(`${API_BASE}/leads/:id`, async ({ request, params }) => {
        const body = (await request.json()) as Record<string, unknown>;
        patchCalls.push({ id: String(params.id), body });
        return HttpResponse.json({ ...LEAD, ...body });
      }),
    );
  });

  afterEach(() => {
    useUserStore.setState({ currentUser: null, isLoading: true });
  });

  it("moves the card immediately (PATCHes the new status, no modal) for a column that needs no confirmation", async () => {
    await renderBoard();

    await capturedOnCardDragEnd(
      { ...LEAD, title: LEAD.fullName },
      { fromColumnId: "new", fromPosition: 0 },
      { toColumnId: "could_not_connect", toPosition: 0 },
    );

    await waitFor(() => expect(patchCalls).toHaveLength(1));
    expect(patchCalls[0]).toMatchObject({ id: "lead-1", body: { status: "could_not_connect" } });
    expect(screen.queryByText("Call time:")).not.toBeInTheDocument();
  });

  it("opens the callback-time modal instead of moving the card when dropped on need_to_call_back", async () => {
    await renderBoard();

    await capturedOnCardDragEnd(
      { ...LEAD, title: LEAD.fullName },
      { fromColumnId: "new", fromPosition: 0 },
      { toColumnId: "need_to_call_back", toPosition: 0 },
    );

    expect(await screen.findByText("Call time:")).toBeInTheDocument();
    expect(patchCalls).toHaveLength(0);
  });

  it("opens the comment modal instead of moving the card when dropped on accepted or rejected", async () => {
    await renderBoard();

    await capturedOnCardDragEnd(
      { ...LEAD, title: LEAD.fullName },
      { fromColumnId: "new", fromPosition: 0 },
      { toColumnId: "accepted", toPosition: 0 },
    );

    expect(await screen.findByText("Commit:")).toBeInTheDocument();
    expect(patchCalls).toHaveLength(0);
  });
});
