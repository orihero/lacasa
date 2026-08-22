/**
 * LeadsScreen.test.tsx — mocks the data layer (`@/data/useLeads`) rather
 * than a real network, and every icon (`@/ui/icons`) with a plain `<svg>`
 * stand-in rather than the real `@phosphor-icons/react` — see this folder's
 * testUtils.tsx for why a real Phosphor icon cannot mount in this workspace
 * at all right now.
 *
 * `react-router-dom` and `@tanstack/react-query` are ALSO fully mocked here,
 * not just spied on: both are hoisted to the *workspace root*
 * node_modules (confirmed — neither has a nested copy under
 * apps/console/node_modules, unlike react-dom itself), so a real
 * `<MemoryRouter>` or `<QueryClientProvider>` rendered through this file's
 * (correctly nested) `react-dom/client` root crashes with "Cannot read
 * properties of null (reading 'useEffect')" — the same class of
 * cross-instance React bug the design-system agent found for
 * @phosphor-icons/react and @testing-library/react, but on two packages
 * every screen and every data hook in this app depends on, which makes it
 * materially worse: this is very likely a REAL `npm run dev`/`vite build`
 * defect too, not just a test artifact, since Vite's dev/build resolution
 * follows the same node_modules algorithm. Flagged in the final report —
 * fixing it needs a `resolve.dedupe` in vite.config.ts/vitest.config.ts,
 * neither of which is in this screen's owned path list.
 * LeadsScreen itself only ever calls `useNavigate()` (no `<Link>`/
 * `useLocation`, checked) and CreateLeadModal only ever calls
 * `useMutation`/`useQueryClient` — mocking exactly those four named exports
 * means neither a real router nor a real query client needs to mount at all.
 */
import { act } from 'react';
import { screen, within } from '@testing-library/dom';
import userEvent from '@testing-library/user-event';
import type { UseMutationResult, UseQueryResult } from '@tanstack/react-query';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { Lead } from '@lacasa/api-client';
import type { ApiError } from '@lacasa/domain';
import { formatDateTime } from '@/lib/format';
import { useLeads, useUpdateLead, type UpdateLeadVariables } from '@/data/useLeads';
import { LeadsScreen } from '../LeadsScreen';
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

// CreateLeadModal's own mutation, scoped entirely to this file's component —
// not to be confused with the DATA-owned useUpdateLead mocked above.
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
  const mutation = {
    mutate: vi.fn(),
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
  return render(<LeadsScreen />);
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe('LeadsScreen — loading / error / empty states', () => {
  it('shows a table skeleton while the query is loading, no lead rows yet', () => {
    mockLeadsQuery({ isLoading: true });
    mockUpdateLeadMutation();
    const { container } = renderScreen();
    expect(container.querySelectorAll('tbody tr')).toHaveLength(6);
    expect(container.querySelector('.animate-pulse')).not.toBeNull();
    expect(screen.queryByText('Dilnoza Yusupova')).not.toBeInTheDocument();
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

  it('shows a real empty state, not an invented row, when the list is empty', () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    const { container } = renderScreen();

    expect(screen.getByText('No leads yet')).toBeInTheDocument();
    expect(container.querySelectorAll('tbody tr')).toHaveLength(0);
  });
});

describe('LeadsScreen — populated table', () => {
  it('renders real Lead fields, with null budget/interest as an em dash rather than 0 or blank', () => {
    const leads = [
      makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', phone: '+998901234501', budget: 50000, comment: 'Chilonzor flat' }),
      makeLead({ id: 'l2', fullName: 'Malika Tosheva', phone: '+998977654321', budget: null, comment: null, status: 'could_not_connect' }),
    ];
    mockLeadsQuery({ data: leads });
    mockUpdateLeadMutation();
    renderScreen();

    expect(screen.getByText('Dilnoza Yusupova')).toBeInTheDocument();
    expect(screen.getByText('+998901234501')).toBeInTheDocument();
    expect(screen.getByText('Chilonzor flat')).toBeInTheDocument();
    expect(screen.getByText('$50,000')).toBeInTheDocument();

    expect(screen.getByText('Malika Tosheva')).toBeInTheDocument();
    // Two "—"s for Malika alone (budget, interest) plus one more for her
    // unset callback date — never a fabricated $0 or empty string.
    expect(screen.getAllByText('—').length).toBeGreaterThanOrEqual(3);
  });

  it('flags that LeadStatus.SUCCESS is not in the Prisma schema yet, naming only the five real statuses', () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    renderScreen();

    const flag = screen.getByRole('note');
    expect(flag.textContent).toContain('LeadStatus.SUCCESS');
    expect(flag.textContent).toContain('New, Could not connect, Need to call back, Rejected, Accepted');
  });

  it('accent-tints only the New-stage row(s) — the screen’s one accent element alongside the Create lead CTA', () => {
    const leads = [
      makeLead({ id: 'l1', status: 'new' }),
      makeLead({ id: 'l2', fullName: 'Bekzod Nazarov', phone: '+998912345678', status: 'accepted' }),
    ];
    mockLeadsQuery({ data: leads });
    mockUpdateLeadMutation();
    const { container } = renderScreen();

    const rows = [...container.querySelectorAll('tbody tr')];
    expect(rows[0]).toHaveAttribute('data-selected', '');
    expect(rows[1]).not.toHaveAttribute('data-selected');
  });

  it('marks a today-or-overdue callback with the warn tone; a callback well in the future stays plain text', () => {
    const now = new Date();
    const dueDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 15, 0, 0);
    const futureDate = new Date(now.getFullYear() + 5, 0, 1, 9, 0, 0);
    const leads = [
      makeLead({ id: 'l1', fullName: 'Aziz Karimov', phone: '+998933456712', callbackDate: dueDate.toISOString() }),
      makeLead({ id: 'l2', fullName: 'Later Lead', phone: '+998900000001', callbackDate: futureDate.toISOString() }),
    ];
    mockLeadsQuery({ data: leads });
    mockUpdateLeadMutation();
    renderScreen();

    // formatDateTime's "DD.MM.YYYY | HH:MM" can carry a doubled space before
    // the time (lib/__tests__/format.test.ts already matches it with a
    // `\s+` regex rather than a literal single space) — collapsed here too,
    // since @testing-library/dom's own text matcher normalizes the *DOM*
    // side of the comparison but not a literal string passed in as-is.
    const collapse = (value: string) => value.replace(/\s+/g, ' ');

    const dueEl = screen.getByText(collapse(formatDateTime(dueDate.toISOString())));
    expect(dueEl.className).toContain('bg-warn-soft');

    const futureEl = screen.getByText(collapse(formatDateTime(futureDate.toISOString())));
    expect(futureEl.className).not.toContain('bg-warn-soft');
  });

  it('wires the stage select to useUpdateLead, sending the chosen status for the right lead', async () => {
    const mutate = vi.fn();
    mockLeadsQuery({ data: [makeLead({ id: 'l1', fullName: 'Dilnoza Yusupova', status: 'new' })] });
    mockUpdateLeadMutation({ mutate });
    renderScreen();

    const select = screen.getByRole('combobox', { name: 'Stage for Dilnoza Yusupova' });
    await userEvent.selectOptions(select, 'accepted');
    expect(mutate).toHaveBeenCalledWith({ id: 'l1', input: { status: 'accepted' } });
  });

  it('falls back to a read-only tag (no editable select) for a status outside the five real LeadStatus members', () => {
    mockLeadsQuery({ data: [makeLead({ id: 'l1', status: 'some_future_status' })] });
    mockUpdateLeadMutation();
    renderScreen();

    expect(screen.queryByRole('combobox')).not.toBeInTheDocument();
    expect(screen.getByText('some_future_status')).toBeInTheDocument();
  });
});

describe('LeadsScreen — Table/Kanban seg and Create lead', () => {
  it('routes to /leads/kanban on the Kanban seg option rather than rendering a kanban view inline', async () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    renderScreen();

    await userEvent.click(screen.getByRole('button', { name: 'Kanban' }));
    expect(mockNavigate).toHaveBeenCalledWith('/leads/kanban');
  });

  it('opens a real Create lead form from the toolbar CTA, requires name+phone before it is submittable, and Cancel closes it', async () => {
    mockLeadsQuery({ data: [] });
    mockUpdateLeadMutation();
    renderScreen();

    // Explicit act() around each interaction: @testing-library/user-event is
    // itself hoisted to the workspace root (same conflict described in this
    // file's header) and can't reliably auto-batch its own updates against
    // *this* file's correctly-nested React — wrapping with `act` imported
    // straight from 'react' (which this test file, living under
    // apps/console/src, always resolves to the correct nested copy) makes
    // the updates flush deterministically instead of warning.
    await act(async () => {
      await userEvent.click(screen.getByRole('button', { name: 'Create lead' }));
    });
    const dialog = screen.getByRole('dialog', { name: 'Create lead' });
    const submit = within(dialog).getByRole('button', { name: 'Create lead' });
    expect(submit).toBeDisabled();

    await act(async () => {
      await userEvent.type(within(dialog).getByLabelText('Full name'), 'New Lead');
    });
    expect(submit).toBeDisabled();
    await act(async () => {
      await userEvent.type(within(dialog).getByLabelText('Phone'), '+998900000000');
    });
    expect(submit).toBeEnabled();

    await act(async () => {
      await userEvent.click(within(dialog).getByRole('button', { name: 'Cancel' }));
    });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
