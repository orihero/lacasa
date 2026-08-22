// Outline + tooltip on low-confidence/unresolved fields (docs/07 §6):
// highlight, don't guess.

const OUTLINE = "2px solid #ff9500";

export function highlightField(ref: string, message: string): void {
  const el = document.querySelector(`[data-lacasa-ref="${ref}"]`) as HTMLElement | null;
  if (!el) return;
  el.style.outline = OUTLINE;
  el.style.outlineOffset = "2px";
  el.title = `La Casa: ${message}`;
}

export function clearHighlights(): void {
  document.querySelectorAll("[data-lacasa-ref]").forEach((el) => {
    (el as HTMLElement).style.outline = "";
    (el as HTMLElement).title = "";
  });
}
