/**
 * The environment strip's derivation. It exists to stop an admin approving an
 * application in the production tab while they think they are in the local
 * one, so the property that matters is that it FAILS LOUD: anything this
 * cannot prove is localhost renders in the irreversible register, and an
 * operator can label an environment but cannot label a remote database as
 * safe.
 */
import { render, screen } from "@testing-library/react";
import { beforeAll, describe, expect, it } from "vitest";
import i18n from "@/i18n";
import { EnvStrip, describeEnvironment } from "../EnvStrip";

const t = (key: string): string => i18n.t(key);

beforeAll(async () => {
  await i18n.changeLanguage("en");
});

describe("describeEnvironment", () => {
  it("reads a loopback API base as local", () => {
    expect(describeEnvironment(t, { apiBaseUrl: "http://localhost:4200/api" })).toEqual({
      name: "Local",
      target: "localhost",
      isLocal: true,
    });
    expect(describeEnvironment(t, { apiBaseUrl: "http://127.0.0.1:4200/api" }).isLocal).toBe(
      true,
    );
  });

  it("shows the host, not the full URL", () => {
    // "lacasa-prod.example.com" is what an operator recognises; the "/api"
    // suffix every base URL shares is noise in a strip this small.
    expect(describeEnvironment(t, { apiBaseUrl: "https://lacasa-prod.example.com/api" })).toEqual(
      {
        name: "Remote",
        target: "lacasa-prod.example.com",
        isLocal: false,
      },
    );
  });

  it("treats an unparseable base URL as remote", () => {
    // Fail loud. A base URL this cannot read is not evidence of safety.
    expect(describeEnvironment(t, { apiBaseUrl: "not a url" })).toEqual({
      name: "Remote",
      target: "not a url",
      isLocal: false,
    });
  });

  it("resolves a same-origin '/api' base against the page's own origin", () => {
    expect(
      describeEnvironment(t, { apiBaseUrl: "/api", origin: "https://admin.lacasa.uz" }),
    ).toEqual({
      name: "Remote",
      target: "admin.lacasa.uz",
      isLocal: false,
    });
  });

  it("lets an operator label the name and the target", () => {
    expect(
      describeEnvironment(t, {
        apiBaseUrl: "https://api.internal/api",
        envName: "  Staging  ",
        dbLabel: "  lacasa-staging  ",
      }),
    ).toEqual({ name: "Staging", target: "lacasa-staging", isLocal: false });
  });

  it("does not let a label make a remote database read as local", () => {
    // Tone is derived from the hostname, never configured: a deployment can be
    // misconfigured but a hostname cannot lie about where the bytes are going.
    expect(
      describeEnvironment(t, {
        apiBaseUrl: "https://api.lacasa.uz/api",
        envName: "Local",
        dbLabel: "totally safe",
      }).isLocal,
    ).toBe(false);
  });

  it("ignores a whitespace-only label and falls back to the derived value", () => {
    expect(describeEnvironment(t, { apiBaseUrl: "http://localhost:4200/api", envName: "   " })).
      toEqual({ name: "Local", target: "localhost", isLocal: true });
  });
});

describe("EnvStrip", () => {
  it("announces the environment and the target as one standing statement", () => {
    render(<EnvStrip />);

    const strip = screen.getByRole("status");
    expect(strip.getAttribute("aria-label")).toMatch(/^Environment: .+, writing to .+$/);
  });
});
