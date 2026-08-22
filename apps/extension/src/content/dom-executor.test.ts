import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  applyAction,
  attachPhotos,
  clickOption,
  looksLikeSubmit,
  setNativeSelect,
  setNativeValue,
  waitForMutation,
} from "./dom-executor";

// Vitest's default (non-VM) jsdom environment exposes `window` as the Node
// `global` object with jsdom's properties proxied onto it (see vitest's
// environments.js `populateGlobal`) rather than a real jsdom Window
// instance. That makes `x instanceof Window` false, so jsdom's WebIDL
// brand-check on `new MouseEvent(type, { view: window })` throws here even
// though the same code runs fine in a real browser content script. Stub a
// minimal MouseEvent for the tests that exercise clickOption so we cover the
// real branching (event type + order) without fighting that environment
// limitation.
class FakeMouseEvent extends Event {
  constructor(type: string, init?: MouseEventInit) {
    super(type, init);
  }
}

beforeEach(() => {
  document.body.innerHTML = "";
});

describe("looksLikeSubmit", () => {
  it("flags input[type=submit]", () => {
    document.body.innerHTML = `<input type="submit" value="Go" />`;
    expect(looksLikeSubmit(document.querySelector("input")!)).toBe(true);
  });

  it("flags a submit button inside a form whose label matches a submit word", () => {
    document.body.innerHTML = `<form><button type="submit">Publish</button></form>`;
    expect(looksLikeSubmit(document.querySelector("button")!)).toBe(true);
  });

  it("flags any element whose accessible name matches a submit word, even without a form", () => {
    document.body.innerHTML = `<div aria-label="Share to feed"></div>`;
    expect(looksLikeSubmit(document.querySelector("div")!)).toBe(true);
  });

  it("does not flag an ordinary text field", () => {
    document.body.innerHTML = `<input type="text" aria-label="Price" />`;
    expect(looksLikeSubmit(document.querySelector("input")!)).toBe(false);
  });
});

describe("setNativeValue", () => {
  it("sets the value through the native setter and fires input+change", () => {
    document.body.innerHTML = `<input type="text" />`;
    const el = document.querySelector("input")!;
    const events: string[] = [];
    el.addEventListener("input", () => events.push("input"));
    el.addEventListener("change", () => events.push("change"));

    setNativeValue(el, "hello");

    expect(el.value).toBe("hello");
    expect(events).toEqual(["input", "change"]);
  });

  it("works on textareas too", () => {
    document.body.innerHTML = `<textarea></textarea>`;
    const el = document.querySelector("textarea")!;
    setNativeValue(el, "long description");
    expect(el.value).toBe("long description");
  });
});

describe("setNativeSelect", () => {
  it("selects the option matching the given text and fires change", () => {
    document.body.innerHTML = `<select><option>One</option><option>Two</option></select>`;
    const el = document.querySelector("select")!;
    let changed = false;
    el.addEventListener("change", () => (changed = true));

    const ok = setNativeSelect(el, "Two");

    expect(ok).toBe(true);
    expect(el.value).toBe(el.options[1].value);
    expect(changed).toBe(true);
  });

  it("returns false and leaves selection untouched when no option matches", () => {
    document.body.innerHTML = `<select><option selected>One</option><option>Two</option></select>`;
    const el = document.querySelector("select")!;
    const before = el.value;

    const ok = setNativeSelect(el, "Three");

    expect(ok).toBe(false);
    expect(el.value).toBe(before);
  });

  it("trims whitespace when matching option text", () => {
    document.body.innerHTML = `<select><option>  Spacey  </option></select>`;
    const el = document.querySelector("select")!;
    expect(setNativeSelect(el, "Spacey")).toBe(true);
  });
});

describe("clickOption", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("dispatches the full pointer/mouse sequence in order", () => {
    vi.stubGlobal("MouseEvent", FakeMouseEvent);
    document.body.innerHTML = `<div></div>`;
    const el = document.querySelector("div")!;
    const seen: string[] = [];
    for (const type of ["pointerdown", "mousedown", "mouseup", "click"]) {
      el.addEventListener(type, () => seen.push(type));
    }
    clickOption(el);
    expect(seen).toEqual(["pointerdown", "mousedown", "mouseup", "click"]);
  });
});

describe("applyAction", () => {
  beforeEach(() => {
    Element.prototype.getBoundingClientRect = () =>
      ({ width: 100, height: 20, top: 0, left: 0, right: 100, bottom: 20, x: 0, y: 0, toJSON() {} }) as DOMRect;
    vi.stubGlobal("MouseEvent", FakeMouseEvent);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("fails when the ref no longer exists in the DOM", async () => {
    const result = await applyAction({ ref: "gone", action: "set-value", value: "x", confidence: 1 });
    expect(result).toEqual({ ref: "gone", ok: false, reason: "element vanished before apply" });
  });

  it("refuses to act on an element that looks like a publish control", async () => {
    document.body.innerHTML = `<button data-lacasa-ref="f1" aria-label="Publish now"></button>`;
    const result = await applyAction({ ref: "f1", action: "click-radio", value: "", confidence: 1 });
    expect(result.ok).toBe(false);
    expect(result.reason).toMatch(/refused/);
  });

  it("set-value writes into a text input", async () => {
    document.body.innerHTML = `<input data-lacasa-ref="f1" type="text" />`;
    const result = await applyAction({ ref: "f1", action: "set-value", value: "12345", confidence: 1 });
    expect(result).toEqual({ ref: "f1", ok: true });
    expect((document.querySelector("input") as HTMLInputElement).value).toBe("12345");
  });

  it("select-option picks the matching <select> option", async () => {
    document.body.innerHTML = `<select data-lacasa-ref="f1"><option>1</option><option>2</option></select>`;
    const result = await applyAction({ ref: "f1", action: "select-option", value: "2", confidence: 1 });
    expect(result.ok).toBe(true);
  });

  it("select-option reports failure when the <select> has no matching option", async () => {
    document.body.innerHTML = `<select data-lacasa-ref="f1"><option>1</option></select>`;
    const result = await applyAction({ ref: "f1", action: "select-option", value: "9", confidence: 1 });
    expect(result).toEqual({ ref: "f1", ok: false, reason: "option not found" });
  });

  it("click-radio clicks the target element", async () => {
    document.body.innerHTML = `<div data-lacasa-ref="f1" role="radio"></div>`;
    let clicked = false;
    document.querySelector("div")!.addEventListener("click", () => (clicked = true));
    const result = await applyAction({ ref: "f1", action: "click-radio", value: "", confidence: 1 });
    expect(result).toEqual({ ref: "f1", ok: true });
    expect(clicked).toBe(true);
  });
});

describe("attachPhotos", () => {
  // jsdom does not implement the drag-and-drop APIs (no DataTransfer, and
  // FileList has no public constructor — see jsdom#2401), so there is no way
  // to produce a real, webidl-branded FileList from outside the DOM. Stand
  // in a duck-typed DataTransfer and relax the input's `files` setter (which
  // normally throws on anything that isn't a branded FileList) for the
  // scope of these tests, so we can still exercise the real logic: base64
  // decoding into File objects, attach order, and the change event.
  let filesDescriptor: PropertyDescriptor | undefined;

  beforeEach(() => {
    filesDescriptor = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, "files");
    class FakeDataTransfer {
      private _files: File[] = [];
      items = {
        add: (file: File) => {
          this._files.push(file);
        },
      };
      get files() {
        return this._files;
      }
    }
    vi.stubGlobal("DataTransfer", FakeDataTransfer);
    Object.defineProperty(HTMLInputElement.prototype, "files", {
      configurable: true,
      get() {
        return (this as unknown as { _testFiles?: File[] })._testFiles ?? [];
      },
      set(v: File[]) {
        (this as unknown as { _testFiles?: File[] })._testFiles = v;
      },
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    if (filesDescriptor) Object.defineProperty(HTMLInputElement.prototype, "files", filesDescriptor);
  });

  it("builds a FileList on the input from the given photo payloads and fires change", () => {
    document.body.innerHTML = `<input type="file" multiple />`;
    const input = document.querySelector("input")!;
    let changed = false;
    input.addEventListener("change", () => (changed = true));

    // "aGVsbG8=" === base64("hello")
    attachPhotos(input, [{ b64: "aGVsbG8=", mime: "image/jpeg", filename: "a.jpg" }]);

    expect(input.files).toHaveLength(1);
    expect(input.files![0].name).toBe("a.jpg");
    expect(input.files![0].type).toBe("image/jpeg");
    expect(changed).toBe(true);
  });

  it("attaches multiple photos in order", () => {
    document.body.innerHTML = `<input type="file" multiple />`;
    const input = document.querySelector("input")!;
    attachPhotos(input, [
      { b64: "aGVsbG8=", mime: "image/jpeg", filename: "a.jpg" },
      { b64: "d29ybGQ=", mime: "image/png", filename: "b.png" },
    ]);
    expect(input.files).toHaveLength(2);
    expect(Array.from(input.files!).map((f) => f.name)).toEqual(["a.jpg", "b.png"]);
  });
});

describe("waitForMutation", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("resolves true as soon as a child mutation is observed", async () => {
    document.body.innerHTML = `<div id="target"></div>`;
    const target = document.getElementById("target")!;
    const promise = waitForMutation(target, 1000);
    target.appendChild(document.createElement("span"));
    await expect(promise).resolves.toBe(true);
  });

  it("resolves false when no mutation happens before the timeout", async () => {
    vi.useFakeTimers();
    document.body.innerHTML = `<div id="target"></div>`;
    const target = document.getElementById("target")!;
    const promise = waitForMutation(target, 50);
    vi.advanceTimersByTime(60);
    await expect(promise).resolves.toBe(false);
  });
});
