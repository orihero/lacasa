/**
 * Avatar — the control room's `.av` chip. 26px in a table row, 34px on a
 * queue card, and never larger: this surface's job is records, and a face
 * big enough to be a portrait is a face big enough to be mistaken for the
 * marketplace (tailwind.config.js rule 4).
 *
 * Square by default (`rounded-act`), round with `round` — the mockup uses
 * `.av--r` for people and the plain square for listings, which is a useful
 * distinction to keep at 26px where a name is the only other clue.
 *
 * The fallback is a deterministic two-letter initials chip: same person,
 * same chip, every render. No procedural persona art, and no colour derived
 * from the name either — a hashed hue would imply a category that doesn't
 * exist, and on the amber/green/magenta palette a stray user-coloured chip
 * would read as a status.
 */
import clsx from "clsx";
import { initials } from "@/lib/format";

type Size = "sm" | "md";

const SIZE_BOX: Record<Size, string> = {
  sm: "h-av w-av", // 26px — table rows
  md: "h-[34px] w-[34px]", // queue cards
};

const SIZE_TEXT: Record<Size, string> = {
  sm: "text-mini",
  md: "text-small",
};

export interface AvatarProps {
  src?: string | null;
  name: string;
  size?: Size;
  round?: boolean;
  className?: string;
}

export function Avatar({ src, name, size = "sm", round, className }: AvatarProps) {
  const shape = clsx(SIZE_BOX[size], round ? "rounded-full" : "rounded-act");

  if (src) {
    return (
      <img
        src={src}
        alt={name}
        className={clsx("shrink-0 bg-sunk object-cover", shape, className)}
      />
    );
  }
  return (
    <span
      role="img"
      aria-label={name}
      className={clsx(
        "grid shrink-0 place-items-center bg-sunk font-bold text-muted",
        shape,
        SIZE_TEXT[size],
        className,
      )}
    >
      {initials(name)}
    </span>
  );
}
