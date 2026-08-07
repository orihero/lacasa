import { beforeEach, describe, expect, it } from "vitest";
import { snapshotCategoryPanel, snapshotStep, structuralHash } from "./dom-snapshot";

// jsdom has no layout engine, so every element's getBoundingClientRect()
// reports a zero-size rect by default — isVisible() would reject everything.
// Stub a non-zero rect so `display`/`visibility`/`hidden` (which jsdom does
// compute) remain the only things driving visibility in these tests.
beforeEach(() => {
  Element.prototype.getBoundingClientRect = () =>
    ({ width: 100, height: 20, top: 0, left: 0, right: 100, bottom: 20, x: 0, y: 0, toJSON() {} }) as DOMRect;
  document.body.innerHTML = "";
});

describe("snapshotCategoryPanel", () => {
  it("returns null when fewer than two candidate options exist", () => {
    document.body.innerHTML = `<div id="root"><div role="option">Only one</div></div>`;
    const root = document.getElementById("root")!;
    expect(snapshotCategoryPanel(root, 0)).toBeNull();
  });

  it("collects visible role=option candidates into a category-step node", () => {
    document.body.innerHTML = `
      <div id="root">
        <div role="option">Apartments</div>
        <div role="option">Houses</div>
        <div role="option" style="display:none">Hidden</div>
      </div>`;
    const root = document.getElementById("root")!;
    const node = snapshotCategoryPanel(root, 2);
    expect(node).not.toBeNull();
    expect(node!.kind).toBe("category-step");
    expect(node!.level).toBe(2);
    expect(node!.options.map((o) => o.label)).toEqual(["Apartments", "Houses"]);
    expect(node!.ref).toBeTruthy();
  });

  it("ignores role=option elements with no visible text", () => {
    document.body.innerHTML = `
      <div id="root">
        <div role="option">   </div>
        <div role="option">Real text</div>
      </div>`;
    const root = document.getElementById("root")!;
    // only one candidate has text -> below the 2-candidate threshold
    expect(snapshotCategoryPanel(root, 0)).toBeNull();
  });

  it("reuses an existing data-lacasa-ref instead of minting a new one", () => {
    document.body.innerHTML = `
      <div id="root" data-lacasa-ref="root-ref">
        <div role="option">A</div>
        <div role="option">B</div>
      </div>`;
    const root = document.getElementById("root")!;
    const node = snapshotCategoryPanel(root, 0);
    expect(node!.ref).toBe("root-ref");
  });
});

describe("snapshotStep", () => {
  it("skips hidden inputs, submit inputs, and disabled elements", () => {
    document.body.innerHTML = `
      <form id="root">
        <input type="hidden" name="csrf" value="x" />
        <input type="submit" value="Go" />
        <input type="text" name="visible" disabled />
        <input type="text" name="price" />
      </form>`;
    const root = document.getElementById("root")!;
    const nodes = snapshotStep(root) as Array<{ tag: string; name?: string }>;
    expect(nodes).toHaveLength(1);
    expect(nodes[0].tag).toBe("input");
    expect(nodes[0].name).toBe("price");
  });

  it("captures select options and the currently selected value", () => {
    document.body.innerHTML = `
      <form id="root">
        <select name="rooms">
          <option>1</option>
          <option selected>2</option>
          <option>3</option>
        </select>
      </form>`;
    const root = document.getElementById("root")!;
    const [node] = snapshotStep(root) as Array<{ tag: string; value?: string; options?: string[] }>;
    expect(node.tag).toBe("select");
    expect(node.value).toBe("2");
    expect(node.options).toEqual(["1", "2", "3"]);
  });

  it("resolves a label via a matching label[for]", () => {
    document.body.innerHTML = `
      <form id="root">
        <label for="addr">Address</label>
        <input id="addr" type="text" />
      </form>`;
    const root = document.getElementById("root")!;
    const [node] = snapshotStep(root) as Array<{ label?: string }>;
    expect(node.label).toBe("Address");
  });

  it("drops buttons with no resolvable text label", () => {
    document.body.innerHTML = `
      <form id="root">
        <button></button>
        <button>Next</button>
      </form>`;
    const root = document.getElementById("root")!;
    const nodes = snapshotStep(root) as Array<{ label?: string }>;
    expect(nodes).toHaveLength(1);
    expect(nodes[0].label).toBe("Next");
  });

  it("captures contenteditable text as the field value", () => {
    document.body.innerHTML = `<div id="root"><div contenteditable="true">Caption text</div></div>`;
    const root = document.getElementById("root")!;
    const [node] = snapshotStep(root) as Array<{ role?: string; value?: string }>;
    expect(node.role).toBe("textbox");
    expect(node.value).toBe("Caption text");
  });
});

describe("structuralHash", () => {
  it("is deterministic for the same field shape", () => {
    const nodes = [{ ref: "f1", tag: "input", role: undefined, label: "Address", path: [0] }] as never;
    expect(structuralHash(nodes)).toBe(structuralHash(nodes));
  });

  it("differs when the field shape (label/role/tag) changes", () => {
    const a = [{ ref: "f1", tag: "input", label: "Address", path: [0] }] as never;
    const b = [{ ref: "f1", tag: "input", label: "Phone", path: [0] }] as never;
    expect(structuralHash(a)).not.toBe(structuralHash(b));
  });

  it("hashes category-step nodes by option count, not labels", () => {
    const a = [{ ref: "c1", kind: "category-step" as const, level: 0, options: [{ ref: "o1", label: "X" }] }];
    const b = [{ ref: "c1", kind: "category-step" as const, level: 0, options: [{ ref: "o1", label: "Y" }] }];
    expect(structuralHash(a)).toBe(structuralHash(b));
  });
});
