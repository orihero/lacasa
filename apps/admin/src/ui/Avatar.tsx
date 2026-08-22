/**
 * Avatar — the 40px chip beside a person's name in a record row.
 *
 * apps/web's avatars are `src={x?.avatar || "/avatar.jpg"}` at 150/100/50/40px;
 * 40px round is its small one (navbar, chart list), and that is the size a
 * record row wants. What differs here is the FALLBACK: apps/web serves a stock
 * photo, this app draws deterministic two-letter initials — same person, same
 * chip, every render — carrying `role="img"` and `aria-label={name}` so the row
 * announces the person rather than announcing nothing.
 *
 * No procedural persona art and no colour derived from the name: a hashed hue
 * would imply a category that does not exist, and on a surface where colour
 * means "waiting on you" or "irreversible", a user-coloured chip would read as
 * a status.
 *
 * Square by default, round with `round` — people are round, listings are
 * square, which is the only other clue at this size. The deleted app's
 * `size="md"` is not ported; nothing ever rendered it.
 */
import { initials } from "@/lib/format";
import "./avatar.scss";

export interface AvatarProps {
  src?: string | null;
  /** Required: it is the alt text, and the accessible name of the fallback. */
  name: string;
  round?: boolean;
  className?: string;
}

export function Avatar({ src, name, round, className }: AvatarProps) {
  const classes = ["avatar", round ? "avatar--round" : "", className ?? ""]
    .filter(Boolean)
    .join(" ");

  if (src) {
    return <img src={src} alt={name} className={classes} />;
  }
  return (
    <span role="img" aria-label={name} className={`${classes} avatar--initials`}>
      {initials(name)}
    </span>
  );
}
