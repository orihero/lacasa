/**
 * Flag — the amber data-honesty banner (PLAN.md §4). Every place the console
 * would otherwise have to fabricate a number or a status the API can't back
 * yet (the 360° panorama proposal, `LeadStatus.SUCCESS` not existing in
 * Prisma) renders one of these naming exactly what's missing, instead of a
 * plausible-looking placeholder value.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import { EyeIcon } from "./icons";

export function Flag({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div
      role="note"
      className={clsx(
        "mb-3.5 flex items-center gap-[9px] rounded-input bg-warn-soft px-3.5 py-2.5 text-small leading-[1.5] text-warn-text",
        className,
      )}
    >
      {/* Eye, not a warning triangle — f-console.src.html's own `.flag` uses
          data-i="eye" on both occurrences (media-grid panorama note, kanban
          Success-stage note); this matches the prototype pixel, not a
          generic "warning" glyph. */}
      <EyeIcon size={14} className="shrink-0" />
      <span>{children}</span>
    </div>
  );
}
