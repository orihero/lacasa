/**
 * Tag — the status pill.
 *
 * apps/web has exactly one badge shape, inline-styled identically in
 * `StatusCell.jsx` and `StatusAds.jsx` (web-design-contract.md §2.3):
 *
 *   padding 4px 8px · border-radius 4px · bold · font-size 10px · inline-block
 *
 * That geometry is reproduced here on an MUI `Chip`, and the six tones draw
 * their colours from apps/web's own two status tables so a control-room badge
 * and a CRM badge are the same object.
 *
 * WHAT RENDERS THROUGH IT: role, realtor status, realtor kind and audit type —
 * and nothing else (PRECEDENCE.md, factual correction 5). Ad stage renders
 * nowhere in this app, and publication status renders as plain text inside the
 * overview's counts breakdown, never as a Tag.
 *
 * The tone allocation is MEANING, not decoration, and must survive:
 *   · `acc`    — WAITING ON YOU: a pending application, a queue depth, an
 *                unreviewed item. It is the accent yellow, and the overview's
 *                queue counts are only scannable because nothing else uses it.
 *   · `danger` — CAN DO SOMETHING IRREVERSIBLE. On the admin role badge this is
 *                the same warning read from the other direction.
 *   · `ok`/`err` — settled outcomes. `info` — a neutral classification.
 *   · `mute`   — the absence of one.
 *
 * NO `text-transform: capitalize`, which apps/web's badge does have. Its badge
 * is handed raw wire values (`could_not_connect`); every label here arrives
 * already cased from the label maps, and capitalising would rewrite the audit
 * types — `ad.created` is deliberately lowercase `noun.verb` so the log can be
 * scanned by prefix, and CSS would turn it into `Ad.created`. Copy is owned by
 * the screen specs, so the transform goes rather than the copy.
 */
import Chip from "@mui/material/Chip";
import type { ReactNode } from "react";
import type { Tone } from "@/lib/labels";
import type { IconComponent } from "./icons";

/**
 * Re-exported, not redeclared. Tone is allocated by the label maps in
 * `@/lib/labels` — it is a statement about what a value MEANS, not about how a
 * pill is painted — and a second declaration of the same union here is exactly
 * how the two would drift apart. Screens may import it from either module.
 */
export type { Tone };

/**
 * Every colour below is quoted from apps/web. `ok`, `err`, `info` and `mute`
 * are `StatusCell.jsx`'s `accepted` / `could_not_connect` / `new` / `pick_date`
 * rows; `acc` is La Casa yellow with black text, which is what apps/web's own
 * "this one" badge is (`.user-role { background-color: #fece51 }`); `danger` is
 * the delete button's red (`.delete-btn { background-color: rgb(216, 72, 53) }`),
 * the one colour apps/web reserves for an action you cannot take back.
 *
 * `err` and `danger` are two neighbouring reds by inheritance, and that is
 * deliberate rather than sloppy: both mean "bad", and the distinction between a
 * settled bad outcome and an irreversible power is carried by the label beside
 * the colour, not by the hue.
 */
const TONE: Record<Tone, { backgroundColor: string; color: string }> = {
  ok: { backgroundColor: "#28a745", color: "#ffffff" },
  acc: { backgroundColor: "#fece51", color: "#000000" },
  err: { backgroundColor: "#dc3545", color: "#ffffff" },
  info: { backgroundColor: "#007bff", color: "#ffffff" },
  mute: { backgroundColor: "#e0e0e0", color: "#000000" },
  danger: { backgroundColor: "rgb(216, 72, 53)", color: "#ffffff" },
};

export function Tag({
  tone = "mute",
  dot,
  icon: Icon,
  children,
}: {
  tone?: Tone;
  /** A decorative leading dot in the current colour; `aria-hidden`. */
  dot?: boolean;
  icon?: IconComponent;
  children: ReactNode;
}) {
  return (
    <Chip
      component="span"
      size="small"
      label={
        <>
          {dot ? <span className="tag__dot" aria-hidden="true" /> : null}
          {Icon ? <Icon size={10} aria-hidden="true" /> : null}
          {children}
        </>
      }
      sx={{
        ...TONE[tone],
        height: "auto",
        borderRadius: "4px",
        "& .MuiChip-label": {
          display: "inline-flex",
          alignItems: "center",
          gap: "4px",
          padding: "4px 8px",
          fontSize: "10px",
          fontWeight: 700,
          lineHeight: 1.2,
        },
        "& .tag__dot": {
          width: "5px",
          height: "5px",
          flex: "none",
          borderRadius: "50%",
          backgroundColor: "currentColor",
        },
      }}
    />
  );
}
