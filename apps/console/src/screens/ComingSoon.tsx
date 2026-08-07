/**
 * src/screens/ComingSoon — what every not-yet-built screen renders until its
 * screen agent replaces the placeholder with the real thing. Names the
 * screen and cites the exact mockups/f/PLAN.md section that specs it — no
 * lorem ipsum, no invented chart or number standing in for the real one.
 */
import { PageHead } from "@/shell/PageHead";
import { EmptyState } from "@/ui/States";
import type { IconComponent } from "@/ui/icons";

export interface ComingSoonProps {
  crumb: string;
  title: string;
  icon: IconComponent;
  /** e.g. "§3.1" — the mockups/f/PLAN.md §3 subsection this screen wireframes. */
  planSection: string;
}

export function ComingSoon({ crumb, title, icon, planSection }: ComingSoonProps) {
  return (
    <>
      <PageHead crumb={crumb} title={title} />
      <EmptyState
        icon={icon}
        title={`${title} is not built yet`}
        sub={`See mockups/f/PLAN.md ${planSection} for the wireframe this screen will implement.`}
      />
    </>
  );
}
