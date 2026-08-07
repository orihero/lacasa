import { describe, expect, it } from "vitest";
import { loadConfig } from "../../src/lib/config.js";

const VALID_ENV = {
  DATABASE_URL: "postgresql://u:p@localhost:5432/db",
  JWT_SECRET: "secret",
  MINIO_ACCESS_KEY: "key",
  MINIO_SECRET_KEY: "secret",
};

describe("loadConfig", () => {
  it("throws one error listing every missing required var at once", () => {
    expect(() => loadConfig({})).toThrowError(
      /DATABASE_URL: Required[\s\S]*JWT_SECRET: Required[\s\S]*MINIO_ACCESS_KEY: Required[\s\S]*MINIO_SECRET_KEY: Required/,
    );
  });

  it("applies documented defaults when optional vars are unset", () => {
    const config = loadConfig(VALID_ENV);
    expect(config.PORT).toBe(4200);
    expect(config.JWT_EXPIRES_IN).toBe("7d");
    expect(config.MINIO_BUCKET).toBe("lacasa");
    expect(config.MINIO_PUBLIC_URL).toBe("http://localhost:9000/lacasa");
    expect(config.LLM_MODEL).toBe("claude-opus-5");
    expect(config.OLX_DAILY_CAP).toBe(15);
    expect(config.IG_ASSIST_DAILY_CAP).toBe(5);
    expect(config.MINIO_USE_SSL).toBe(false);
  });

  it("treats a blank KEY= (empty string) the same as unset", () => {
    const config = loadConfig({ ...VALID_ENV, CORS_ORIGIN: "", LLM_MODEL: "" });
    expect(config.CORS_ORIGIN).toBeUndefined();
    expect(config.LLM_MODEL).toBe("claude-opus-5");
  });

  it("derives IG_CONFIGURED / LLM_CONFIGURED from the presence of their vars", () => {
    expect(loadConfig(VALID_ENV).IG_CONFIGURED).toBe(false);
    expect(loadConfig(VALID_ENV).LLM_CONFIGURED).toBe(false);
    expect(
      loadConfig({ ...VALID_ENV, IG_APP_ID: "a", IG_APP_SECRET: "b", IG_REDIRECT_URI: "c", ANTHROPIC_API_KEY: "k" })
        .IG_CONFIGURED,
    ).toBe(true);
  });

  it("respects an explicit MINIO_PUBLIC_URL instead of deriving one", () => {
    const config = loadConfig({ ...VALID_ENV, MINIO_PUBLIC_URL: "https://cdn.example.com" });
    expect(config.MINIO_PUBLIC_URL).toBe("https://cdn.example.com");
  });
});
