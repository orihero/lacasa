/**
 * MediaPanel — mockups/f/PLAN.md §3.3's media grid: hero "Cover" badge on
 * the first photo, a dashed "+" add-tile, an "Upload" button in the panel
 * head, and the amber-flagged "360°" roadmap note (Decision 6.3 — no
 * `AdMediaType.PANORAMA` exists, so this is a general banner naming the gap,
 * never a per-photo badge implying one specific photo already has a tour).
 *
 * `photos: string[]` is `Ad`'s real, writable field (packages/api-client's
 * `Ad` interface names it explicitly) — every tile here is a real URL from
 * a real upload, not seed art.
 */
import { useRef } from "react";
import { Panel, PanelHead } from "@/ui/Panel";
import { Button } from "@/ui/Button";
import { Flag } from "@/ui/Flag";
import { IconButton } from "@/ui/IconButton";
import { CameraIcon, TrashIcon, PlusIcon } from "@/ui/icons";

export function MediaPanel({
  photos,
  uploading,
  uploadError,
  onAddFiles,
  onRemove,
}: {
  photos: string[];
  uploading: boolean;
  uploadError: string | null;
  onAddFiles: (files: FileList) => void;
  onRemove: (index: number) => void;
}) {
  const fileInputRef = useRef<HTMLInputElement>(null);

  function openFilePicker() {
    fileInputRef.current?.click();
  }

  function handleFileChange(event: React.ChangeEvent<HTMLInputElement>) {
    if (event.target.files && event.target.files.length > 0) {
      onAddFiles(event.target.files);
    }
    // Reset so picking the exact same file again still fires onChange.
    event.target.value = "";
  }

  return (
    <Panel className="mt-[18px]">
      <PanelHead
        title="Media"
        sub={`${photos.length} photo${photos.length === 1 ? "" : "s"}`}
      >
        <Button icon={CameraIcon} onClick={openFilePicker} disabled={uploading}>
          {uploading ? "Uploading…" : "Upload"}
        </Button>
      </PanelHead>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={handleFileChange}
      />

      <Flag>
        360° panorama is a roadmap proposal — <span className="font-mono">AdMediaType</span> has no{" "}
        <span className="font-mono">PANORAMA</span> member yet.
      </Flag>

      {uploadError ? (
        <p role="alert" className="mb-3.5 text-caption text-err">
          {uploadError}
        </p>
      ) : null}

      <div className="grid grid-cols-3 gap-2.5 sm:grid-cols-4">
        {photos.map((url, index) => (
          <div key={`${url}-${index}`} className="group relative aspect-square overflow-hidden rounded-input bg-surface-inner">
            <img src={url} alt={`Listing photo ${index + 1}`} className="h-full w-full object-cover" />
            {index === 0 ? (
              <span className="absolute left-1.5 top-1.5 rounded-chip bg-dark px-2 py-[3px] text-micro font-semibold text-dark-text">
                Cover
              </span>
            ) : null}
            <div className="absolute right-1.5 top-1.5 opacity-0 transition-opacity group-hover:opacity-100">
              <IconButton
                icon={TrashIcon}
                label={`Remove photo ${index + 1}`}
                size="sm"
                onClick={() => onRemove(index)}
              />
            </div>
          </div>
        ))}
        <button
          type="button"
          onClick={openFilePicker}
          disabled={uploading}
          className="flex aspect-square items-center justify-center rounded-input border-1.5 border-dashed border-black/[.16] text-ink-2 transition-colors hover:bg-surface-inner disabled:cursor-not-allowed disabled:opacity-50"
        >
          <PlusIcon size={18} />
        </button>
      </div>

      <p className="mt-2.5 text-caption text-ink-2">
        The first photo is used as the cover everywhere — search results, Telegram and Instagram.
      </p>
    </Panel>
  );
}
