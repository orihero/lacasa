/**
 * The equivalent of apps/web's src/__tests__/smoke.test.jsx: it proves the
 * vitest + jsdom + RTL wiring works before any screen depends on it.
 *
 * It asserts a little more than apps/web's does, because two of this app's
 * foundations are exactly the kind of thing that fails silently:
 *
 *  · i18n — a missing key renders as the key itself, so a locale file that
 *    failed to load looks like a UI full of camelCase rather than an error.
 *  · the MUI theme — a component rendered without a ThemeProvider falls back
 *    to MUI's factory defaults (Roboto, MUI blue, 4px radii) and still renders
 *    perfectly well. It just stops looking like apps/web.
 */
import { render, screen } from "@testing-library/react";
import { ThemeProvider } from "@mui/material/styles";
import Button from "@mui/material/Button";
import { describe, expect, it } from "vitest";
import i18n from "@/i18n";
import { theme } from "@/theme";

describe("control room scaffold", () => {
  it("renders an MUI component through the app theme", () => {
    render(
      <ThemeProvider theme={theme}>
        <Button variant="contained">{i18n.t("signIn")}</Button>
      </ThemeProvider>,
    );

    expect(screen.getByRole("button", { name: "Sign in" })).toBeInTheDocument();
  });

  it("carries La Casa's accent yellow, not MUI's default primary", () => {
    expect(theme.palette.primary.main).toBe("#fece51");
    expect(theme.palette.primary.contrastText).toBe("#000000");
    expect(theme.typography.fontFamily).toContain("Plus Jakarta Sans");
  });

  it("resolves copy in all three languages, falling back to English", async () => {
    expect(i18n.t("controlRoom")).toBe("Control room");

    await i18n.changeLanguage("ru");
    expect(i18n.t("controlRoom")).toBe("Пункт управления");

    await i18n.changeLanguage("uz");
    expect(i18n.t("controlRoom")).toBe("Boshqaruv markazi");

    // An audit type is an identifier, not prose — it stays byte-identical in
    // every locale so the log can still be scanned by prefix.
    expect(i18n.t("auditTypeOlxCrosspostAborted")).toBe("olx.crosspost_aborted");

    await i18n.changeLanguage("en");
  });
});
