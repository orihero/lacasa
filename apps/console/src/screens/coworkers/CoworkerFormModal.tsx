/**
 * CoworkerFormModal — the create/edit form behind the ghost row and the row
 * "edit" action, backed by the real POST/PATCH /coworkers endpoints
 * (`CoworkerCreateInput`/`CoworkerUpdateInput` from @lacasa/domain, the same
 * zod schemas apps/api/src/routes/coworkers.js validates against).
 *
 * Password is required on create (the schema's own `min(6)`) and optional on
 * edit ("leave blank to keep it") — the same asymmetry the API's two zod
 * schemas encode (coworkerCreateSchema.password vs. coworkerUpdateSchema's
 * `.optional()`). The `mode` discriminant on props (rather than a bare
 * `coworker?: Coworker`) is what lets `onSubmit` be typed as exactly
 * `CoworkerCreateInput` or exactly `CoworkerUpdateInput` per call site,
 * instead of a union the caller would have to cast out of.
 */
import { useState, type FormEvent } from "react";
import type { Coworker } from "@lacasa/api-client";
import type { CoworkerCreateInput, CoworkerUpdateInput } from "@lacasa/domain";
import { Button } from "@/ui/Button";
import { Field, PillInput } from "@/ui/Field";
import { Modal } from "@/ui/Modal";

interface CommonProps {
  onClose: () => void;
  isSubmitting: boolean;
  error?: unknown;
}

export type CoworkerFormModalProps =
  | (CommonProps & { mode: "create"; onSubmit: (input: CoworkerCreateInput) => void })
  | (CommonProps & { mode: "edit"; coworker: Coworker; onSubmit: (input: CoworkerUpdateInput) => void });

function errorMessage(error: unknown): string | null {
  if (error == null) return null;
  if (error instanceof Error) return error.message;
  return "Something went wrong.";
}

export function CoworkerFormModal(props: CoworkerFormModalProps) {
  const { onClose, isSubmitting, error } = props;
  const coworker = props.mode === "edit" ? props.coworker : undefined;

  const [fullName, setFullName] = useState(coworker?.fullName ?? "");
  const [email, setEmail] = useState(coworker?.email ?? "");
  const [phoneNumber, setPhoneNumber] = useState(coworker?.phoneNumber ?? "");
  const [password, setPassword] = useState("");

  function handleSubmit(event: FormEvent) {
    event.preventDefault();
    const trimmedPhone = phoneNumber.trim();

    if (props.mode === "edit") {
      const input: CoworkerUpdateInput = {
        fullName: fullName.trim(),
        email: email.trim(),
        // Sent verbatim, including ''. `trimmedPhone || undefined` would
        // turn a deliberate clear into an omitted key: fetchTransport's
        // JSON.stringify drops undefined-valued keys entirely, and the
        // server's PATCH handler only writes phoneNumber when the key is
        // present (`if (phoneNumber !== undefined) data.phoneNumber = …` —
        // apps/api/src/routes/coworkers.js), so an omitted key is a silent
        // no-op that leaves the old number in place. coworkerUpdateSchema's
        // phoneNumber is `z.string().max(30).optional()` with no `.min()`,
        // so '' is a valid value that really clears the column.
        phoneNumber: trimmedPhone,
      };
      // Blank means "don't change it" — coworkerUpdateSchema.password is
      // optional; sending an empty string would fail its own min(6).
      if (password.trim()) input.password = password.trim();
      props.onSubmit(input);
    } else {
      props.onSubmit({
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: trimmedPhone || undefined,
        password,
      });
    }
  }

  const isEdit = props.mode === "edit";

  return (
    <Modal title={isEdit ? "Edit coworker" : "Create coworker"} onClose={onClose}>
      <form onSubmit={handleSubmit} className="flex flex-col gap-3.5">
        <Field label="Full name">
          <PillInput
            value={fullName}
            onChange={(event) => setFullName(event.target.value)}
            required
            autoFocus
          />
        </Field>
        <Field label="Email">
          <PillInput
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            required
          />
        </Field>
        <Field label="Phone">
          <PillInput
            type="tel"
            value={phoneNumber}
            onChange={(event) => setPhoneNumber(event.target.value)}
            placeholder="+998 90 000 00 00"
          />
        </Field>
        <Field
          label={isEdit ? "New password" : "Password"}
          hint={isEdit ? "Leave blank to keep the current password." : "At least 6 characters."}
        >
          <PillInput
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            required={!isEdit}
            minLength={isEdit ? undefined : 6}
          />
        </Field>
        {error != null ? <p className="text-caption text-err">{errorMessage(error)}</p> : null}
        <div className="mt-1 flex justify-end gap-2">
          <Button type="button" onClick={onClose}>
            Cancel
          </Button>
          {/* dark, not primary — the accent is spoken for by the ghost row
              that opens this modal (PLAN.md §1's one-accent-per-screen rule);
              F's own stage-gate modal makes the same call (btn--dark "Move
              lead"), so this isn't a new convention. */}
          <Button type="submit" variant="dark" disabled={isSubmitting}>
            {isSubmitting ? "Saving…" : isEdit ? "Save changes" : "Create coworker"}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
