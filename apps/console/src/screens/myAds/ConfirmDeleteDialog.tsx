/**
 * src/screens/myAds/ConfirmDeleteDialog — the "real confirmation step" the
 * build brief asks the trash row-action to have, built on the shared
 * `@/ui/Modal` (promoted from a duplicate this screen, Leads and Coworkers
 * each built independently — see that file's header). The overlay tint is a
 * translucent backdrop, not an elevation shadow — it doesn't reach for
 * `shadow-*` and so doesn't break the flat-depth rule.
 */
import { Button } from "@/ui/Button";
import { Modal } from "@/ui/Modal";

export function ConfirmDeleteDialog({
  adTitle,
  pending,
  onCancel,
  onConfirm,
}: {
  adTitle: string;
  pending: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  return (
    <Modal title="Delete this listing?" onClose={onCancel}>
      <p className="text-small leading-[1.5] text-ink-2">
        &ldquo;{adTitle}&rdquo; will be permanently removed. This can&rsquo;t be undone.
      </p>
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
