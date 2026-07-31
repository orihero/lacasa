// Accessibility-tree-style serializer (docs/07 §3.1). Refs are injected as
// data-lacasa-ref and valid for this run only — nothing hardcodes a selector
// against the host site's DOM.
import type { CategoryStepNode, FieldNode, SnapshotNode } from "../lib/types";

let refCounter = 0;
const nextRef = () => `f${++refCounter}`;

const MAX_NODES = 150;

function isVisible(el: Element): boolean {
  const he = el as HTMLElement;
  if (he.hidden) return false;
  const style = window.getComputedStyle(he);
  if (style.display === "none" || style.visibility === "hidden") return false;
  const rect = he.getBoundingClientRect();
  return rect.width > 0 && rect.height > 0;
}

function textOf(el: Element | null): string {
  return (el?.textContent ?? "").replace(/\s+/g, " ").trim().slice(0, 120);
}

function resolveLabel(el: Element): string | undefined {
  const id = el.getAttribute("id");
  if (id) {
    const forLabel = document.querySelector(`label[for="${CSS.escape(id)}"]`);
    if (forLabel) return textOf(forLabel);
  }
  const aria = el.getAttribute("aria-label");
  if (aria) return aria.slice(0, 120);
  const labelledBy = el.getAttribute("aria-labelledby");
  if (labelledBy) {
    const parts = labelledBy
      .split(/\s+/)
      .map((lid) => textOf(document.getElementById(lid)))
      .filter(Boolean);
    if (parts.length) return parts.join(" ").slice(0, 120);
  }
  const wrapping = el.closest("label");
  if (wrapping) return textOf(wrapping);
  // Last resort: nearest preceding text among ancestors' previous siblings.
  let node: Element | null = el;
  for (let depth = 0; depth < 4 && node; depth++) {
    let sib = node.previousElementSibling;
    while (sib) {
      const t = textOf(sib);
      if (t) return t;
      sib = sib.previousElementSibling;
    }
    node = node.parentElement;
  }
  return undefined;
}

function childIndexPath(el: Element, root: Element): number[] {
  const path: number[] = [];
  let node: Element | null = el;
  while (node && node !== root) {
    const parent: Element | null = node.parentElement;
    if (!parent) break;
    path.unshift(Array.from(parent.children).indexOf(node));
    node = parent;
  }
  return path;
}

function setRef(el: Element): string {
  const existing = el.getAttribute("data-lacasa-ref");
  if (existing) return existing;
  const ref = nextRef();
  el.setAttribute("data-lacasa-ref", ref);
  return ref;
}

export function snapshotCategoryPanel(root: Element, level: number): CategoryStepNode | null {
  // Category pickers are lists of clickable options without name attributes:
  // role=option/menuitem/listitem entries, or a list of buttons/links.
  const candidates = Array.from(
    root.querySelectorAll('[role="option"], [role="menuitem"], li > button, li > a, [data-testid*="category"] button'),
  ).filter((el) => isVisible(el) && textOf(el));
  if (candidates.length < 2) return null;
  return {
    ref: setRef(root),
    kind: "category-step",
    level,
    options: candidates.slice(0, 80).map((el) => ({ ref: setRef(el), label: textOf(el) })),
  };
}

export function snapshotStep(root: Element): SnapshotNode[] {
  const nodes: SnapshotNode[] = [];
  const selector =
    'input, select, textarea, [role="radio"], [role="checkbox"], [role="combobox"], [role="listbox"], [contenteditable="true"], button';
  const elements = Array.from(root.querySelectorAll(selector)).filter(isVisible);

  for (const el of elements) {
    if (nodes.length >= MAX_NODES) break;
    const tag = el.tagName.toLowerCase();
    const type = el.getAttribute("type") ?? undefined;
    if (tag === "input" && (type === "hidden" || type === "submit")) continue;
    if ((el as HTMLInputElement).disabled) continue;

    const node: FieldNode = {
      ref: setRef(el),
      tag,
      role: el.getAttribute("role") ?? (el.getAttribute("contenteditable") === "true" ? "textbox" : undefined),
      type,
      name: el.getAttribute("name") ?? undefined,
      id: el.getAttribute("id") ?? undefined,
      label: resolveLabel(el),
      placeholder: el.getAttribute("placeholder") ?? el.getAttribute("aria-placeholder") ?? undefined,
      required: el.hasAttribute("required") || el.getAttribute("aria-required") === "true" || undefined,
      path: childIndexPath(el, root),
    };

    if (tag === "select") {
      const select = el as HTMLSelectElement;
      node.value = select.selectedOptions[0]?.text?.trim();
      node.options = Array.from(select.options)
        .map((o) => o.text.trim())
        .filter(Boolean)
        .slice(0, 60);
    } else if (tag === "input" || tag === "textarea") {
      node.value = (el as HTMLInputElement).value?.slice(0, 200) || undefined;
    } else if (tag === "button") {
      node.label = node.label ?? textOf(el);
      if (!node.label) continue;
    } else if (el.getAttribute("contenteditable") === "true") {
      node.value = textOf(el).slice(0, 200) || undefined;
    }

    nodes.push(node);
  }
  return nodes;
}

// Structural hash for drift telemetry (docs/07 §6): labels + roles + tags,
// not values.
export function structuralHash(nodes: SnapshotNode[]): string {
  const sig = nodes
    .map((n) => ("kind" in n ? `cat:${n.options.length}` : `${n.tag}:${n.role ?? ""}:${n.label ?? ""}`))
    .join("|");
  let hash = 0;
  for (let i = 0; i < sig.length; i++) {
    hash = (hash * 31 + sig.charCodeAt(i)) | 0;
  }
  return String(hash >>> 0);
}
