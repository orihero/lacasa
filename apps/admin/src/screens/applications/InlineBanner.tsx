/**
 * InlineBanner — a strip above the table for facts that arrived AFTER the page
 * rendered: "another admin already decided this one", "the background refresh
 * failed".
 *
 * Why not `ui/States`' Notice, which is the same shape? Two reasons, and both
 * are about meaning rather than layout:
 *
 *  · Notice offers only `acc` and `danger`. On this surface the accent yellow
 *    means WAITING ON YOU and the `.delete-btn` red means IRREVERSIBLE — and a
 *    message saying a decision has already been taken is neither. Painting it
 *    yellow would put a second kind of yellow next to the pending queue's badge
 *    and cost that badge its meaning; painting it red would imply something was
 *    destroyed. So `neutral` is the app canvas grey with the plain hairline, and
 *    `error` is apps/web's warm blush behind its settled-outcome red.
 *  · Notice is permanent, and both of these messages are transient by nature:
 *    the stale-decision one is answered by the refetch it announces, and a
 *    banner that cannot be cleared becomes wallpaper long before it stops being
 *    displayed.
 *
 * `role="status"`, NEVER `alert`. Both messages would interrupt a screen reader
 * mid-sentence if announced assertively, and neither is urgent enough to justify
 * that on a screen where the admin is part-way through a decision. The
 * applications suite asserts that no element on the 409 path carries `alert` —
 * the only `alert` this screen may ever render is the in-dialog error of a
 * decision that genuinely failed.
 */
import type { ReactNode } from "react";
import { useTranslation } from "react-i18next";
import { IconButton } from "@/ui/IconButton";
import { CircleAlert, Info, X } from "@/ui/icons";
import "./inlineBanner.scss";

export type InlineBannerTone = "neutral" | "error";

export function InlineBanner({
  tone = "neutral",
  children,
  onDismiss,
}: {
  tone?: InlineBannerTone;
  children: ReactNode;
  /** Renders the close affordance. Omit for a banner that must stay put. */
  onDismiss?: () => void;
}) {
  const { t } = useTranslation();
  const isError = tone === "error";
  const Icon = isError ? CircleAlert : Info;

  return (
    <div role="status" className={isError ? "inline-banner inline-banner--error" : "inline-banner"}>
      <span className="inline-banner__icon">
        <Icon size={16} aria-hidden="true" />
      </span>
      <div className="inline-banner__text">{children}</div>
      {onDismiss ? (
        <span className="inline-banner__dismiss">
          <IconButton icon={X} label={t("dismiss")} size="sm" onClick={onDismiss} />
        </span>
      ) : null}
    </div>
  );
}
