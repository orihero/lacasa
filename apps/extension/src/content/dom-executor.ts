// Executes LLM field actions against the live DOM (docs/07 §4-5). The action
// vocabulary has no "submit" action, and this module independently refuses
// anything that looks like a publish/share control — defense in depth.
import type { FieldAction, PhotoPayload } from "../lib/types";

const SUBMIT_WORDS = /(опубликовать|publish|joylashtirish|e['’]lon berish|share|поделиться|далее.*опублик)/i;

export function looksLikeSubmit(el: Element): boolean {
  if ((el as HTMLInputElement).type === "submit") return true;
  if (el.tagName === "BUTTON" && (el as HTMLButtonElement).type === "submit" && el.closest("form")) {
    const label = accessibleName(el);
    if (SUBMIT_WORDS.test(label)) return true;
  }
  return SUBMIT_WORDS.test(accessibleName(el));
}

function accessibleName(el: Element): string {
  return (el.getAttribute("aria-label") ?? el.textContent ?? "").replace(/\s+/g, " ").trim();
}

// React installs its value tracking on the prototype setter; setting through
// it plus a real input/change event makes React observe a genuine edit.
export function setNativeValue(el: HTMLInputElement | HTMLTextAreaElement, value: string): void {
  const proto = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
  const setter = Object.getOwnPropertyDescriptor(proto, "value")?.set;
  setter?.call(el, value);
  el.dispatchEvent(new Event("input", { bubbles: true }));
  el.dispatchEvent(new Event("change", { bubbles: true }));
}

function setContentEditable(el: HTMLElement, value: string): void {
  el.focus();
  const selection = window.getSelection();
  selection?.selectAllChildren(el);
  // execCommand is deprecated but still the only way to write into
  // contenteditable so that React/Lexical editors (Instagram's caption box)
  // register the edit through their beforeinput/input pipeline.
  document.execCommand("selectAll", false);
  document.execCommand("insertText", false, value);
  el.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText", data: value }));
}

export function setNativeSelect(el: HTMLSelectElement, optionText: string): boolean {
  const opt = Array.from(el.options).find((o) => o.text.trim() === optionText.trim());
  if (!opt) return false;
  const setter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, "value")?.set;
  setter?.call(el, opt.value);
  el.dispatchEvent(new Event("change", { bubbles: true }));
  return true;
}

export function clickOption(el: Element): void {
  for (const type of ["pointerdown", "mousedown", "mouseup", "click"] as const) {
    el.dispatchEvent(new MouseEvent(type, { bubbles: true, cancelable: true, view: window }));
  }
}

function simulateTyping(el: HTMLInputElement | HTMLTextAreaElement, value: string): void {
  el.focus();
  setNativeValue(el, "");
  let current = "";
  for (const ch of value) {
    current += ch;
    el.dispatchEvent(new KeyboardEvent("keydown", { key: ch, bubbles: true }));
    el.dispatchEvent(new InputEvent("beforeinput", { bubbles: true, cancelable: true, inputType: "insertText", data: ch }));
    const proto = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(proto, "value")?.set?.call(el, current);
    el.dispatchEvent(new InputEvent("input", { bubbles: true, inputType: "insertText", data: ch }));
    el.dispatchEvent(new KeyboardEvent("keyup", { key: ch, bubbles: true }));
  }
  el.dispatchEvent(new Event("change", { bubbles: true }));
}

export interface ApplyResult {
  ref: string;
  ok: boolean;
  reason?: string;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export async function applyAction(a: FieldAction): Promise<ApplyResult> {
  const el = document.querySelector(`[data-lacasa-ref="${a.ref}"]`);
  if (!el) return { ref: a.ref, ok: false, reason: "element vanished before apply" };
  if (looksLikeSubmit(el)) return { ref: a.ref, ok: false, reason: "refused: looks like a publish/submit control" };

  if (a.action === "set-value") {
    if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
      setNativeValue(el, a.value);
      await sleep(60);
      if (el.value !== a.value) {
        simulateTyping(el, a.value);
        await sleep(60);
        if (el.value !== a.value) return { ref: a.ref, ok: false, reason: "value did not persist" };
      }
      return { ref: a.ref, ok: true };
    }
    if ((el as HTMLElement).isContentEditable) {
      setContentEditable(el as HTMLElement, a.value);
      await sleep(60);
      return { ref: a.ref, ok: true };
    }
    return { ref: a.ref, ok: false, reason: "not a writable element" };
  }

  if (a.action === "select-option") {
    if (el instanceof HTMLSelectElement) {
      const ok = setNativeSelect(el, a.value);
      return { ref: a.ref, ok, reason: ok ? undefined : "option not found" };
    }
    // Custom dropdown: open it, then click the matching visible option.
    clickOption(el);
    await sleep(250);
    const option = Array.from(document.querySelectorAll('[role="option"], li'))
      .filter((o) => (o as HTMLElement).offsetParent !== null)
      .find((o) => (o.textContent ?? "").trim() === a.value.trim());
    if (!option) return { ref: a.ref, ok: false, reason: "dropdown option not found" };
    clickOption(option);
    await sleep(120);
    return { ref: a.ref, ok: true };
  }

  // click-radio — plain click on a custom widget/radio/toggle.
  clickOption(el);
  await sleep(120);
  return { ref: a.ref, ok: true };
}

// input.files is read-only; a DataTransfer builds a real FileList without
// touching the OS file dialog (docs/07 §5).
export function attachPhotos(input: HTMLInputElement, photos: PhotoPayload[]): void {
  const dt = new DataTransfer();
  for (const p of photos) {
    const binary = atob(p.b64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    dt.items.add(new File([bytes], p.filename, { type: p.mime }));
  }
  const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "files")?.set;
  if (setter) setter.call(input, dt.files);
  else input.files = dt.files;
  input.dispatchEvent(new Event("change", { bubbles: true }));
}

export function waitForMutation(target: Node, timeoutMs = 5000): Promise<boolean> {
  return new Promise((resolve) => {
    const observer = new MutationObserver(() => {
      observer.disconnect();
      clearTimeout(timer);
      resolve(true);
    });
    const timer = setTimeout(() => {
      observer.disconnect();
      resolve(false);
    }, timeoutMs);
    observer.observe(target, { childList: true, subtree: true });
  });
}
