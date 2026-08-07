/**
 * CreateLeadModal — the Leads screen's "Create lead" flow (PLAN.md §3.5's
 * toolbar CTA). `src/data/useLeads.ts` (the FOUNDATION CONTRACT's DATA-owned
 * module) exports only `useLeads`/`useUpdateLead` — no `useCreateLead`,
 * unlike Coworkers' explicit `useCreateCoworker`. Rather than ship a CTA that
 * opens nothing or silently no-ops (this codebase's own FilterChip draws the
 * line at exactly that: an unwired-looking control is a defect, not a detail
 * to fix later), this mutates through `apiClient.leads.create` directly —
 * the same resource method `useLeads.ts` would call if it grew this hook —
 * scoped entirely to this file so it stays inside src/screens/leads/
 * ownership. It invalidates `queryKeys.leads.all`, the exact key
 * `useUpdateLead` already invalidates, so the table picks up a created lead
 * the same way it picks up an edited one.
 *
 * The submit button is `variant="dark"`, not `primary`: the toolbar's
 * "Create lead" button is this screen's one accent element, and it's still
 * on screen (dimmed behind the overlay) while this is open.
 *
 * Built on the shared `@/ui/Modal` for the scrim/panel/Escape-to-close shell
 * — Coworkers and My ads each built the same overlay independently before
 * this was promoted; see that file's header.
 */
import { useState, type FormEvent } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import type { Lead } from '@lacasa/api-client';
import type { ApiError, LeadInput } from '@lacasa/domain';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from '@/data/queryKeys';
import { Button } from '@/ui/Button';
import { Field, PillInput, PillTextarea } from '@/ui/Field';
import { Modal } from '@/ui/Modal';
import { PlusIcon } from '@/ui/icons';

export function CreateLeadModal({ onClose }: { onClose: () => void }) {
  const queryClient = useQueryClient();
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [budget, setBudget] = useState('');
  const [comment, setComment] = useState('');

  const createLead = useMutation<Lead, ApiError, LeadInput>({
    mutationFn: (input) => apiClient.leads.create(input),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.leads.all });
      onClose();
    },
  });

  const trimmedName = fullName.trim();
  const trimmedPhone = phone.trim();
  const canSubmit = trimmedName.length > 0 && trimmedPhone.length > 0 && !createLead.isPending;

  function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!canSubmit) return;
    const trimmedComment = comment.trim();
    const trimmedBudget = budget.trim();
    createLead.mutate({
      fullName: trimmedName,
      phone: trimmedPhone,
      budget: trimmedBudget === '' ? null : Number(trimmedBudget),
      comment: trimmedComment === '' ? null : trimmedComment,
    });
  }

  return (
    <Modal title="Create lead" onClose={onClose}>
      <form onSubmit={handleSubmit} className="flex flex-col gap-3.5">
        <Field label="Full name">
          <PillInput
            value={fullName}
            onChange={(event) => setFullName(event.target.value)}
            placeholder="Dilnoza Yusupova"
            autoFocus
            required
          />
        </Field>
        <Field label="Phone">
          <PillInput
            value={phone}
            onChange={(event) => setPhone(event.target.value)}
            placeholder="+998901234501"
            required
          />
        </Field>
        <Field label="Budget" hint="Leave blank if unknown.">
          <PillInput
            type="number"
            min="0"
            value={budget}
            onChange={(event) => setBudget(event.target.value)}
            placeholder="50000"
          />
        </Field>
        <Field label="Interest">
          <PillTextarea
            value={comment}
            onChange={(event) => setComment(event.target.value)}
            placeholder="2–3 room apartment, Chilonzor or Yunusobod"
          />
        </Field>

        {createLead.isError ? (
          <p role="alert" className="text-caption text-err">
            {createLead.error.message}
          </p>
        ) : null}

        <div className="mt-1 flex justify-end gap-2">
          <Button type="button" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="dark" icon={PlusIcon} disabled={!canSubmit}>
            {createLead.isPending ? 'Creating…' : 'Create lead'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
