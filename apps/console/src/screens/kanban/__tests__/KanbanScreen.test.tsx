/**
 * KanbanScreen.test.tsx — same mocking shape as leads/__tests__/LeadsScreen.
 * test.tsx (see that file's own header for why `@/data/useLeads`,
 * `@/ui/icons`, `react-router-dom` and `@tanstack/react-query` are all
 * mocked at the module level rather than letting a real router/query
 * client mount). KanbanScreen reuses `CreateLeadModal` from `../leads/`
 * unchanged, so the same `@tanstack/react-query` mock that file relies on
 * is needed here too.
 */
import { act } from 'react';
import { fireEvent, screen, within } from '@testing-library/dom';
import userEvent from '@testing-library/user-event';
import type { UseMutationResult, UseQueryResult } from '@tanstack/react-query';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Lead } from '@lacasa/api-client';
import type { ApiError } from '@lacasa/domain';
import { formatDateTime } from '@/lib/format';
import { useLeads, useUpdateLead, type UpdateLeadVariables } from '@/data/useLeads';
import { KanbanScreen } from '../KanbanScreen';
import { render } from './testUtils';

vi.mock('@/data/useLeads', () => ({
  useLeads: vi.fn(),
  useUpdateLead: vi.fn(),
}));

vi.mock('@/ui/icons', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/ui/icons')>();
  const FakeIcon = (props: Record<string, unknown>) => <svg data-testid="fake-icon" {...props} />;
  const faked = Object.fromEntries(Object.keys(actual).map((key) => [key, FakeIcon]));
  return { ...actual, ...faked };
});

const mockNavigate = vi.fn();
vi.mock('react-router-dom', () => ({
  useNavigate: () => mockNavigate,
}));

// CreateLeadModal's own mutation (see that file's header) — distinct from
// the DATA-owned useUpdateLead mocked above.
const mockCreateLeadMutate = vi.fn();
vi.mock('@tanstack/react-query', () => ({
  useMutation: () => ({ mutate: mockCreateLeadMutate, isPending: false, isError: false, error: null }),
  useQueryClient: () => ({ invalidateQueries: vi.fn() }),
}));

type LeadsQuery = UseQueryResult<Lead[]>;
type UpdateLeadMutation = UseMutationResult<Lead, ApiError, UpdateLeadVariables>;

function mockLeadsQuery(overrides: Partial<LeadsQuery>) {
  vi.mocked(useLeads).mockReturnValue({
    data: undefined,
    isLoading: false,
    isError: false,
    error: null,
    refetch: vi.fn(),
    ...overrides,
  } as unknown as LeadsQuery);
}

function mockUpdateLeadMutation(overrides: Partial<UpdateLeadMutation> = {}) {
  const mutate = vi.fn();
  const mutation = {
    mutate,
    isPending: false,
    isError: false,
    variables: undefined,
    error: null,
    ...overrides,
  } as unknown as UpdateLeadMutation;
  vi.mocked(useUpdateLead).mockReturnValue(mutation);
  return mutation;
}

function makeLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'lead-1',
    fullName: 'Dilnoza Yusupova',
    phone: '+998901234501',
    email: null,
    budget: 50000,
    comment: '2–3 room apartment, Chilonzor or Yunusobod',
    conversationComment: null,
    status: 'new',
    source: null,
    callbackDate: null,
    active: true,
    agentId: 'agent-1',
    coworkerId: '',
    createdAt: { seconds: 1_722_600_000 },
    updatedAt: { seconds: 1_722_600_000 },
    ...overrides,
  };
}

function renderScreen() {
  return render(<KanbanScreen />);
}

// Reads the {onError, onSuccess} options object passed to the most recent
// updateLead.mutate(variables, options) call — how this screen's optimistic
// update/rollback wires into a fully-mocked mutation hook.
function lastMutateOptions(mutate: ReturnType<typeof vi.fn>) {
  const call = mutate.mock.calls.at(-1);
  return call?.[1] as { onError?: () => void; onSuccess?: () => void } | undefined;
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe('KanbanScreen — loading / error / empty states', () => {
  it('shows a loading state while the query is loading, no columns yet', () => {
    mockLeadsQuery({ isLoading: true });
    mockUpdateLeadMutation();
    renderScreen();

    expect(screen.getByText('Loading leads…')).toBeInTheDocument();
    expect(screen.queryByTestId('kanban-column-new')).not.toBeInTheDocument();
  });

  it('surfaces the real query error message and wires "Try again" to refetch()', async () => {
    const refetch = vi.fn();
    mockLeadsQuery({ isError: true, error: new Error('Network down'), refetch });
    mockUpdateLeadMutation();
    renderScreen();

    expect(screen.getByText('Network down')).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Try again' }));
    expect(refetch).toHaveBeenCalledOnce();
  });

  it('shows a real empty state, not an empty board, when there are no leads', () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    renderScreen();

    expect(screen.getByText('No leads yet')).toBeInTheDocument();
    expect(screen.queryByTestId('kanban-column-new')).not.toBeInTheDocument();
  });
});

describe('KanbanScreen — board grouping', () => {
  it('groups leads into their real column and flags the not-yet-real Success stage', () => {
    const dueDate = new Date();
    const leads = [
      makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' }),
      makeLead({ id: 'l2', fullName: 'Aziz Karimov', status: 'need_to_call_back', callbackDate: dueDate.toISOString() }),
      makeLead({ id: 'l3', fullName: 'Ravshan Ismoilov', status: 'rejected', conversationComment: 'Budget mismatch, will not proceed' }),
    ];
    mockLeadsQuery({ data: leads });
    mockUpdateLeadMutation();
    renderScreen();

    expect(within(screen.getByTestId('kanban-column-new')).getByText('Dilnoza Yusupova')).toBeInTheDocument();
    expect(within(screen.getByTestId('kanban-column-new')).getByText('1')).toBeInTheDocument();

    const callbackCol = screen.getByTestId('kanban-column-need_to_call_back');
    expect(within(callbackCol).getByText('Aziz Karimov')).toBeInTheDocument();
    const dueTag = within(callbackCol).getByText(formatDateTime(dueDate.toISOString()).replace(/\s+/g, ' '));
    expect(dueTag.className).toContain('bg-warn-soft');

    const rejectedCol = screen.getByTestId('kanban-column-rejected');
    expect(within(rejectedCol).getByText('Ravshan Ismoilov')).toBeInTheDocument();
    expect(within(rejectedCol).getByText('Budget mismatch, will not proceed')).toBeInTheDocument();

    expect(within(screen.getByTestId('kanban-column-could_not_connect')).getByText('No leads in could not connect')).toBeInTheDocument();

    const flag = screen.getByRole('note');
    expect(flag.textContent).toContain('LeadStatus.SUCCESS');
    expect(flag.textContent).toContain('New, Could not connect, Need to call back, Rejected, Accepted');
  });

  it('routes back to /leads on the Table seg option', async () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    renderScreen();

    await userEvent.click(screen.getByRole('button', { name: 'Table' }));
    expect(mockNavigate).toHaveBeenCalledWith('/leads');
  });
});

describe('KanbanScreen — moving a card', () => {
  it('advances an ungated move immediately via the notch button, optimistically updating the board', async () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' })];
    mockLeadsQuery({ data: leads });
    const mutation = mockUpdateLeadMutation();
    renderScreen();

    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: 'Advance Dilnoza Yusupova to the next stage' }));
    });

    // No `onSuccess` in the per-call options: a successful PATCH lets the
    // useEffect below (keyed off the query's own `data`) clear the override
    // once a refetch actually lands, rather than clearing it synchronously
    // and flashing the card back to its old column for a beat — see
    // KanbanScreen's file header.
    expect(mutation.mutate).toHaveBeenCalledWith(
      { id: 'l1', input: { status: 'could_not_connect' } },
      expect.objectContaining({ onError: expect.any(Function) }),
    );
    expect(within(screen.getByTestId('kanban-column-could_not_connect')).getByText('Dilnoza Yusupova')).toBeInTheDocument();
    expect(within(screen.getByTestId('kanban-column-new')).queryByText('Dilnoza Yusupova')).not.toBeInTheDocument();
  });

  it('clears the optimistic override once the refetched query data itself reflects the move (no premature flicker back)', () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' })];
    mockLeadsQuery({ data: leads });
    mockUpdateLeadMutation();
    const { rerender } = renderScreen();

    act(() => {
      fireEvent.dragStart(screen.getByTestId('kanban-card-l1'), {
        dataTransfer: { setData: vi.fn(), effectAllowed: '' },
      });
    });
    act(() => {
      fireEvent.drop(screen.getByTestId('kanban-column-could_not_connect'));
    });
    expect(within(screen.getByTestId('kanban-column-could_not_connect')).getByText('Dilnoza Yusupova')).toBeInTheDocument();

    // Simulate the background refetch (kicked off by useUpdateLead's own
    // onSuccess) landing with data that still shows the *old* status for a
    // beat: the merged view must keep trusting the override, not snap back.
    mockLeadsQuery({ data: leads });
    rerender(<KanbanScreen />);
    expect(within(screen.getByTestId('kanban-column-could_not_connect')).getByText('Dilnoza Yusupova')).toBeInTheDocument();
    expect(within(screen.getByTestId('kanban-column-new')).queryByText('Dilnoza Yusupova')).not.toBeInTheDocument();

    // Now the refetch actually lands with the new status — the override
    // should quietly stand down instead of double-applying.
    const moved = [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'could_not_connect' })];
    mockLeadsQuery({ data: moved });
    rerender(<KanbanScreen />);
    expect(within(screen.getByTestId('kanban-column-could_not_connect')).getByText('Dilnoza Yusupova')).toBeInTheDocument();
    expect(within(screen.getByTestId('kanban-column-new')).queryByText('Dilnoza Yusupova')).not.toBeInTheDocument();
  });

  it('rolls an optimistic move back and shows a retry note when the mutation fails', async () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' })];
    mockLeadsQuery({ data: leads });
    const mutation = mockUpdateLeadMutation();
    renderScreen();

    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: 'Advance Dilnoza Yusupova to the next stage' }));
    });
    expect(within(screen.getByTestId('kanban-column-could_not_connect')).getByText('Dilnoza Yusupova')).toBeInTheDocument();

    const options = lastMutateOptions(mutation.mutate as ReturnType<typeof vi.fn>);
    await act(async () => {
      options?.onError?.();
    });

    expect(within(screen.getByTestId('kanban-column-new')).getByText('Dilnoza Yusupova')).toBeInTheDocument();
    expect(within(screen.getByTestId('kanban-column-could_not_connect')).queryByText('Dilnoza Yusupova')).not.toBeInTheDocument();
    expect(screen.getByText("Couldn't move — try again.")).toBeInTheDocument();
  });

  it('gates a move into Need to call back behind a required callback time, via the notch button', async () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Malika Tosheva', status: 'could_not_connect' })];
    mockLeadsQuery({ data: leads });
    const mutation = mockUpdateLeadMutation();
    renderScreen();

    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: 'Advance Malika Tosheva to the next stage' }));
    });
    expect(mutation.mutate).not.toHaveBeenCalled();

    const dialog = screen.getByRole('dialog', { name: 'Move Malika Tosheva to Need to call back' });
    const confirmButton = within(dialog).getByRole('button', { name: 'Confirm move' });
    expect(confirmButton).toBeDisabled();

    const input = within(dialog).getByLabelText('Callback date & time');
    await act(async () => {
      fireEvent.change(input, { target: { value: '2026-08-10T15:00' } });
    });
    expect(confirmButton).toBeEnabled();

    await act(async () => {
      await userEvent.click(confirmButton);
    });

    expect(mutation.mutate).toHaveBeenCalledWith(
      { id: 'l1', input: { status: 'need_to_call_back', callbackDate: new Date('2026-08-10T15:00') } },
      expect.any(Object),
    );
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('gates a move into Rejected behind a >=10-char note, via the per-card "Move to" select', async () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Ravshan Ismoilov', status: 'new' })];
    mockLeadsQuery({ data: leads });
    const mutation = mockUpdateLeadMutation();
    renderScreen();

    const select = screen.getByRole('combobox', { name: 'Move Ravshan Ismoilov to a different stage' });
    await act(async () => {
      await userEvent.selectOptions(select, 'rejected');
    });
    expect(mutation.mutate).not.toHaveBeenCalled();

    const dialog = screen.getByRole('dialog', { name: 'Move Ravshan Ismoilov to Rejected' });
    const confirmButton = within(dialog).getByRole('button', { name: 'Confirm move' });
    const textarea = within(dialog).getByLabelText('Note');

    await act(async () => {
      await userEvent.type(textarea, 'too short');
    });
    expect(confirmButton).toBeDisabled();

    await act(async () => {
      await userEvent.clear(textarea);
      await userEvent.type(textarea, 'Budget mismatch, will not proceed');
    });
    expect(confirmButton).toBeEnabled();

    await act(async () => {
      await userEvent.click(confirmButton);
    });

    expect(mutation.mutate).toHaveBeenCalledWith(
      { id: 'l1', input: { status: 'rejected', conversationComment: 'Budget mismatch, will not proceed' } },
      expect.any(Object),
    );
  });

  it('moves a card on drop into a different column, the keyboard-free path', async () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' })];
    mockLeadsQuery({ data: leads });
    const mutation = mockUpdateLeadMutation();
    renderScreen();

    const card = screen.getByTestId('kanban-card-l1');
    const destColumn = screen.getByTestId('kanban-column-could_not_connect');

    // Each event gets its own act() so the `dragging` state React committed
    // from dragstart is actually visible to the drop handler's closure —
    // batching all three fireEvent calls into one act() would let `onDrop`
    // read the stale (pre-dragstart) render's `dragging`, which is still
    // `null`, and the real browser always re-renders between separate
    // native drag events anyway.
    await act(async () => {
      fireEvent.dragStart(card, { dataTransfer: { setData: vi.fn(), effectAllowed: '' } });
    });
    await act(async () => {
      fireEvent.dragOver(destColumn);
    });
    await act(async () => {
      fireEvent.drop(destColumn);
    });

    expect(mutation.mutate).toHaveBeenCalledWith({ id: 'l1', input: { status: 'could_not_connect' } }, expect.any(Object));
  });

  it('does nothing when a card is dropped back onto its own column', async () => {
    const leads = [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' })];
    mockLeadsQuery({ data: leads });
    const mutation = mockUpdateLeadMutation();
    renderScreen();

    const card = screen.getByTestId('kanban-card-l1');
    const sameColumn = screen.getByTestId('kanban-column-new');

    await act(async () => {
      fireEvent.dragStart(card, { dataTransfer: { setData: vi.fn(), effectAllowed: '' } });
    });
    await act(async () => {
      fireEvent.dragOver(sameColumn);
    });
    await act(async () => {
      fireEvent.drop(sameColumn);
    });

    expect(mutation.mutate).not.toHaveBeenCalled();
  });
});

describe('KanbanScreen — Create lead', () => {
  it('opens the same Create lead form Leads uses, from the toolbar CTA', async () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    renderScreen();

    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: 'Create lead' }));
    });
    const dialog = screen.getByRole('dialog', { name: 'Create lead' });
    expect(within(dialog).getByRole('button', { name: 'Create lead' })).toBeDisabled();

    await act(async () => {
      await userEvent.click(within(dialog).getByRole('button', { name: 'Cancel' }));
    });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
