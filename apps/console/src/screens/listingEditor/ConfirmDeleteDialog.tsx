/**
 * ConfirmDeleteDialog — this screen's own copy of the same shape
 * `myAds/ConfirmDeleteDialog.tsx` already built on `@/ui/Modal` (the
 * console's one modal grammar — scrim, Escape-to-close, no bespoke overlay).
 * Duplicated rather than imported across the folder boundary per the HARD
 * RULES (each screen owns its own directory); the two are intentionally
 * near-identical.
 */
import { Button } from "@/ui/Button";
import { Modal } from "@/ui/Modal";

export function ConfirmDeleteDialog({
  adTitle,
  pending,
  error,
  onCancel,
  onConfirm,
}: {
  adTitle: string;
  pending: boolean;
  error?: string | null;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal title="Delete this listing?" onClose={onCancel}>
      <p className="text-small leading-[1.5] text-ink-2">
        &ldquo;{adTitle}&rdquo; will be permanently removed. This can&rsquo;t be undone.
      </p>
      {error ? (
        <p role="alert" className="mt-2 text-caption text-err">
          {error}
        </p>
      ) : null}
      <div className="mt-5 flex justify-end gap-2">
        <Button variant="default" onClick={onCancel} disabled={pending}>
          Cancel
        </Button>
        <Button variant="danger" onClick={onConfirm} disabled={pending}>
          {pending ? "Deleting…" : "Delete"}
        </Button>
      </div>
    </Modal>
  );
}
