// Asserts the actual wire envelopes this extension builds (window.postMessage
// with the page, chrome.runtime.sendMessage with the background worker) are
// still recognized by @lacasa/crosspost-protocol's type guards. types.ts and
// messaging.ts locally override the `channel` field's casing (see the
// CASING NOTE there); this test is what would catch it if a future change
// drifted the *shape* (source tags, discriminant values, field names) away
// from the shared contract, independent of that one known deviation.
import { describe, expect, it } from "vitest";
import {
  PAGE_SOURCE as PROTOCOL_PAGE_SOURCE,
  EXT_SOURCE as PROTOCOL_EXT_SOURCE,
  isPageMessage,
  isExtensionMessage,
  isCrosspostRequestMessage,
  isCrosspostPingMessage,
  isCrosspostPongMessage,
  isCrosspostResultMessage,
  isBackgroundRequest,
  isCrosspostRequestAction,
  isJobRequestAction,
  isMapFieldsAction,
  isConfirmAction,
  isFetchPhotosAction,
  isJobDoneAction,
  isOkResponse,
  isErrResponse,
} from "@lacasa/crosspost-protocol";
import { EXT_SOURCE, PAGE_SOURCE } from "./messaging";

describe("origin tags stay in sync with @lacasa/crosspost-protocol", () => {
  it("PAGE_SOURCE and EXT_SOURCE match the package's constants", () => {
    expect(PAGE_SOURCE).toBe(PROTOCOL_PAGE_SOURCE);
    expect(EXT_SOURCE).toBe(PROTOCOL_EXT_SOURCE);
  });
});

describe("page <-> extension postMessage envelopes", () => {
  it("the CROSSPOST_REQUEST envelope apps/web sends satisfies the protocol's guards", () => {
    // Mirrors what content/lacasa-bridge.ts receives as `event.data` — built
    // the way apps/web/src/services/crosspost.ts's requestCrosspost() does,
    // channel included, at today's (lowercase) wire casing.
    const wire: unknown = {
      source: PAGE_SOURCE,
      type: "CROSSPOST_REQUEST",
      requestId: "req-1",
      channel: "olx",
      adId: "ad-1",
      ad: { title: "Nice flat" },
      photoUrls: ["https://example.com/1.jpg"],
      token: "tok",
      apiBase: "https://api.example.com",
    };
    expect(isPageMessage(wire)).toBe(true);
    expect(isCrosspostRequestMessage(wire)).toBe(true);
  });

  it("the CROSSPOST_PING envelope apps/web sends satisfies the protocol's guards", () => {
    const wire: unknown = { source: PAGE_SOURCE, type: "CROSSPOST_PING", id: "ping-1" };
    expect(isPageMessage(wire)).toBe(true);
    expect(isCrosspostPingMessage(wire)).toBe(true);
  });

  it("the CROSSPOST_PONG envelope lacasa-bridge.ts replies with satisfies the protocol's guards", () => {
    // Built exactly as content/lacasa-bridge.ts's CROSSPOST_PING handler does.
    const wire: unknown = { source: EXT_SOURCE, type: "CROSSPOST_PONG", id: "ping-1" };
    expect(isExtensionMessage(wire)).toBe(true);
    expect(isCrosspostPongMessage(wire)).toBe(true);
  });

  it("the CROSSPOST_RESULT envelope lacasa-bridge.ts replies with satisfies the protocol's guards", () => {
    // Built exactly as content/lacasa-bridge.ts's CROSSPOST_REQUEST handler
    // does once sendToBackground() resolves, both on success and failure.
    const okWire: unknown = { source: EXT_SOURCE, type: "CROSSPOST_RESULT", requestId: "req-1", ok: true, error: undefined };
    const errWire: unknown = { source: EXT_SOURCE, type: "CROSSPOST_RESULT", requestId: "req-1", ok: false, error: "boom" };
    expect(isCrosspostResultMessage(okWire)).toBe(true);
    expect(isCrosspostResultMessage(errWire)).toBe(true);
  });

  it("rejects an envelope from an unrelated postMessage source", () => {
    const wire: unknown = { source: "some-other-extension", type: "CROSSPOST_PING", id: "x" };
    expect(isPageMessage(wire)).toBe(false);
    expect(isExtensionMessage(wire)).toBe(false);
  });
});

describe("content-script <-> background chrome.runtime envelopes", () => {
  it("the CROSSPOST_REQUEST action lacasa-bridge.ts sends satisfies isBackgroundRequest", () => {
    // Mirrors content/lacasa-bridge.ts's sendToBackground({ type: "CROSSPOST_REQUEST", job }) call.
    const wire: unknown = {
      type: "CROSSPOST_REQUEST",
      job: {
        channel: "instagram",
        adId: "ad-1",
        ad: { title: "Nice flat" },
        photoUrls: [],
        token: "tok",
        apiBase: "https://api.example.com",
      },
    };
    expect(isBackgroundRequest(wire)).toBe(true);
    if (isBackgroundRequest(wire)) expect(isCrosspostRequestAction(wire)).toBe(true);
  });

  it("the JOB_REQUEST action olx/instagram-autofill.ts send satisfies isBackgroundRequest", () => {
    const wire: unknown = { type: "JOB_REQUEST" };
    expect(isBackgroundRequest(wire)).toBe(true);
    if (isBackgroundRequest(wire)) expect(isJobRequestAction(wire)).toBe(true);
  });

  it("the MAP_FIELDS action satisfies isBackgroundRequest", () => {
    // Mirrors content/olx-autofill.ts's field-mapping call, snapshot from
    // content/dom-snapshot.ts's snapshotStep().
    const wire: unknown = {
      type: "MAP_FIELDS",
      step: "details",
      snapshot: [{ ref: "f1", tag: "input", path: [0] }],
    };
    expect(isBackgroundRequest(wire)).toBe(true);
    if (isBackgroundRequest(wire)) expect(isMapFieldsAction(wire)).toBe(true);
  });

  it("the CONFIRM action olx/instagram-autofill.ts send satisfies isBackgroundRequest for every ConfirmEvent", () => {
    for (const event of ["drafted", "published", "failed", "aborted", "dom-drift"]) {
      const wire: unknown = { type: "CONFIRM", event };
      expect(isBackgroundRequest(wire)).toBe(true);
      if (isBackgroundRequest(wire)) expect(isConfirmAction(wire)).toBe(true);
    }
  });

  it("the FETCH_PHOTOS action satisfies isBackgroundRequest", () => {
    const wire: unknown = { type: "FETCH_PHOTOS", urls: ["https://example.com/1.jpg"] };
    expect(isBackgroundRequest(wire)).toBe(true);
    if (isBackgroundRequest(wire)) expect(isFetchPhotosAction(wire)).toBe(true);
  });

  it("the JOB_DONE action satisfies isBackgroundRequest", () => {
    const wire: unknown = { type: "JOB_DONE" };
    expect(isBackgroundRequest(wire)).toBe(true);
    if (isBackgroundRequest(wire)) expect(isJobDoneAction(wire)).toBe(true);
  });

  it("rejects an unrecognized action type", () => {
    expect(isBackgroundRequest({ type: "NOT_A_REAL_ACTION" })).toBe(false);
    expect(isBackgroundRequest(null)).toBe(false);
    expect(isBackgroundRequest("CROSSPOST_REQUEST")).toBe(false);
  });
});

describe("background response envelope", () => {
  it("the shape service-worker.ts's onMessage listener replies with satisfies isOkResponse/isErrResponse", () => {
    // Mirrors background/service-worker.ts's onMessage listener.
    const okRes: unknown = { ok: true, data: { started: true } };
    const errRes: unknown = { ok: false, error: "Another cross-post is already in progress" };
    expect(isOkResponse(okRes as { ok: true; data: unknown } | { ok: false; error: string })).toBe(true);
    expect(isErrResponse(errRes as { ok: true; data: unknown } | { ok: false; error: string })).toBe(true);
  });
});
