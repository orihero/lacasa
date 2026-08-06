/**
 * DeleteCoworkerModal — the confirmation step in front of
 * `DELETE /coworkers/:id`. Removing a coworker's account is destructive and
 * immediate (apps/api/src/routes/coworkers.js hard-deletes the row, no
 * soft-delete/undo), so the trash icon in RowActions never fires the
 * mutation directly — it only opens this.
 */
import type { Coworker } from "@lacasa/api-client";
import { Button } from "@/ui/Button";
import { Modal } from "@/ui/Modal";

function errorMessage(error: unknown): string | null {
  if (error == null) return null;
  if (error instanceof Error) return error.message;
  return "Something went wrong.";
}

export function DeleteCoworkerModal({
  coworker,
  onClose,
  onConfirm,
  isSubmitting,
  error,
}: {
  coworker: Coworker;
  onClose: () => void;
  onConfirm: () => void;
  isSubmitting: boolean;
  error?: unknown;
}) {
  return (
    <Modal title="Delete coworker" onClose={onClose}>
      <p className="text-body text-ink-2">
        Remove <span className="font-semibold text-ink">{coworker.fullName}</span> from your team? They lose
        access immediately. This cannot be undone.
      </p>
      {error != null ? <p className="mt-2 text-caption text-err">{errorMessage(error)}</p> : null}
      <div className="mt-4 flex justify-end gap-2">
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="danger" onClick={onConfirm} disabled={isSubmitting}>
          {isSubmitting ? "Deleting…" : "Delete coworker"}
        </Button>
      </div>
    </Modal>
  );
}
