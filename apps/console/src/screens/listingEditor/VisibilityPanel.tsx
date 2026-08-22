/**
 * VisibilityPanel — mockups/f/PLAN.md §3.3's "Visibility" panel: Active
 * (real, writable `active` boolean), Assign coworker (inert — `coworkerId`
 * is set once on create and never reassignable via PATCH, per
 * `apps/api/src/services/adService.js#updateAd`, which never touches it —
 * rendering a working `<select>` here would be a fake affordance), Mark as
 * sold (UI-only switch that becomes `stage: '2'` on save — see
 * `adFormFields.ts#buildAdInput`).
 */
import type { Coworker } from "@lacasa/api-client";
import { Panel, PanelHead } from "@/ui/Panel";
import { Switch } from "@/ui/Switch";

export function VisibilityPanel({
  active,
  onActiveChange,
  markAsSold,
  onMarkAsSoldChange,
  coworker,
}: {
  active: boolean;
  onActiveChange: (checked: boolean) => void;
  markAsSold: boolean;
  onMarkAsSoldChange: (checked: boolean) => void;
  coworker: Coworker | undefined | null;
}) {
  return (
    <Panel className="mt-[18px]">
      <PanelHead title="Visibility" />
      <div className="flex flex-col gap-2">
        <div className="flex items-center gap-3 rounded-input border border-hairline bg-pill px-3.5 py-2.5">
          <div className="min-w-0 flex-1">
            <b className="block text-body font-semibold text-ink">Active</b>
            <span className="block text-caption text-ink-2">Visible in search results</span>
          </div>
          <Switch checked={active} onChange={onActiveChange} label="Active — visible in search results" />
        </div>

        <div className="flex items-center gap-3 rounded-input border border-hairline bg-pill px-3.5 py-2.5">
          <div className="min-w-0 flex-1">
            <b className="block text-body font-semibold text-ink">Assign coworker</b>
            <span className="block text-caption text-ink-2">
              {coworker === undefined ? "Loading…" : coworker ? coworker.fullName : "Unassigned"}
            </span>
          </div>
          {/* No picker: coworkerId is set once at creation and is never
              reassignable via PATCH — a working <select> here would promise
              a mutation that doesn't exist. */}
        </div>

        <div className="flex items-center gap-3 rounded-input border border-hairline bg-pill px-3.5 py-2.5">
          <div className="min-w-0 flex-1">
            <b className="block text-body font-semibold text-ink">Mark as sold</b>
            <span className="block text-caption text-ink-2">Moves to the Sold stage on save</span>
          </div>
          <Switch checked={markAsSold} onChange={onMarkAsSoldChange} label="Mark as sold" />
        </div>
      </div>
    </Panel>
  );
}
