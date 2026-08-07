/**
 * StageGateModal — Decision 6.5's required-field gate (kanbanHelpers.ts's
 * `gateFor`, @lacasa/domain's `resolveCardMoveAction`): moving a lead to
 * Need to call back needs a callback date/time, moving to Rejected or
 * Accepted needs a note of real substance. One modal handles both shapes,
 * built on the shared `@/ui/Modal` grammar (see CreateLeadModal's own file
 * header for why every overlay in this app goes through it).
 *
 * The note is written to `conversationComment`, not `comment` — `comment`
 * already means "what the lead is interested in" everywhere else in this
 * console (LeadsScreen's Interest column, CreateLeadModal's Interest field);
 * `conversationComment` reads as "notes from this interaction," which is
 * what a rejection/acceptance reason actually is.
 */
import { useState, type FormEvent } from 'react';
import type { LeadStatusKey } from '@lacasa/domain';
import { LEAD_STATUS_LABEL } from '@/lib/labels';
import { Button } from '@/ui/Button';
import { Field, PillInput, PillTextarea } from '@/ui/Field';
import { Modal } from '@/ui/Modal';
import { isNoteValid, type StageGateKind } from './kanbanHelpers';

export type GateConfirmPayload = { callbackDate: Date } | { conversationComment: string };

export function StageGateModal({
  leadName,
  destColumn,
  kind,
  pending,
  onCancel,
  onConfirm,
}: {
  leadName: string;
  destColumn: LeadStatusKey;
  kind: StageGateKind;
  pending: boolean;
  onCancel: () => void;
  onConfirm: (payload: GateConfirmPayload) => void;
}) {
  const [callbackValue, setCallbackValue] = useState('');
  const [note, setNote] = useState('');

  const targetLabel = LEAD_STATUS_LABEL[destColumn];
  const callbackValid = callbackValue.trim() !== '' && !Number.isNaN(new Date(callbackValue).getTime());
  const noteValid = isNoteValid(note);
  const canSubmit = (kind === 'callback' ? callbackValid : noteValid) && !pending;

  function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!canSubmit) return;
    if (kind === 'callback') {
      onConfirm({ callbackDate: new Date(callbackValue) });
    } else {
      onConfirm({ conversationComment: note.trim() });
    }
  }

  return (
    <Modal title={`Move ${leadName} to ${targetLabel}`} onClose={onCancel}>
      <form onSubmit={handleSubmit} className="flex flex-col gap-3.5">
        {kind === 'callback' ? (
          <Field label="Callback date & time" hint="Required before this lead can move to Need to call back.">
            <PillInput
              type="datetime-local"
              value={callbackValue}
              onChange={(event) => setCallbackValue(event.target.value)}
              autoFocus
              required
            />
          </Field>
        ) : (
          <Field
            label="Note"
            hint={`At least 10 characters — why this lead is moving to ${targetLabel}.`}
          >
            <PillTextarea
              value={note}
              onChange={(event) => setNote(event.target.value)}
              placeholder="Reason for this move…"
              autoFocus
            />
          </Field>
        )}

        <div className="mt-1 flex justify-end gap-2">
          <Button type="button" onClick={onCancel}>
            Cancel
          </Button>
          <Button type="submit" variant="dark" disabled={!canSubmit}>
            {pending ? 'Moving…' : 'Confirm move'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
