// Placeholder — see mockups/f/PLAN.md §3.3. Overwritten by the Listing editor screen agent.
// Renders for BOTH /ads/new and /ads/:id/edit (routes.tsx) — the create and
// edit forms are the same screen with a prefilled Ad.
import { ComingSoon } from "@/screens/ComingSoon";
import { NotePencilIcon } from "@/ui/icons";

export function ListingEditorScreen() {
  return (
    <ComingSoon crumb="Console · Workspace" title="Listing editor" icon={NotePencilIcon} planSection="§3.3" />
  );
}
