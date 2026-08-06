/* eslint-env node */
/**
 * La Casa Console — the Direction F design language as a Tailwind theme.
 *
 * Every value here is lifted from `mockups/f/build/f-tokens.css`, which
 * `mockups/f/PLAN.md` §1 settled after the magenta accent was built and then
 * reversed by the user on the rendered prototype (04.08.2026). The prototype
 * stays the visual source of truth: if a value here and a value there ever
 * disagree, the prototype is right and this file is the bug.
 *
 * Three rules this theme is built to enforce:
 *
 *  1. ONE SCALE PER THING. The mockup CSS had 28/30px card-radius drift and a
 *     three-way --pill / --pill-white / --text / --text-primary naming split.
 *     Each value gets exactly one name here so the drift cannot come back.
 *  2. THE ACCENT MARKS EXACTLY ONE THING PER SCREEN (PLAN.md §1's lint
 *     criterion). `accent` is lime; it is never text. Ink on lime is
 *     `accent-text` (dark olive). Reach for `accent` a second time on a screen
 *     and the rule is eroding — see the discipline table in PLAN.md.
 *  3. FLAT DEPTH. F has no drop shadows anywhere. Hover / focus / selected all
 *     read through color-shift alone. Tailwind's default `shadow-*` utilities
 *     still exist but using one in this app is a design regression.
 *
 * The `semantic status layer` (ok/warn/err/info/mute) is a deliberate THIRD
 * color category, distinct from both the neutrals and the accent: Active/Sold/
 * Draft, Published/Awaiting/Failed and the lead stages are all already
 * color-coded and cannot all be the accent without breaking rule 2.
 */
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // ---- neutrals: F's warm-grey canvas, verbatim ----
        canvas: "#E9E9E7",
        surface: "#F5F5F3",
        // Zebra rows, inert switch tracks, count-pill fills. Also the
        // deliberate, scoped exception to F's hairline-free purity on the
        // four table screens (PLAN.md §1).
        "surface-inner": "#ECECEA",
        // The near-white of raised controls: buttons, chips, inputs, rail rows.
        pill: "#FCFCFA",
        dark: "#1E1E1E",
        "dark-text": "#F5F5F3",
        ink: "#1B1B1B",
        "ink-2": "#8E8E8C",
        hairline: "rgba(0,0,0,.07)",

        // ---- accent ----
        accent: "#CDF44A",
        // Large-surface / selected-row variant. Lime at full strength across a
        // whole table row is unreadable; this is the same hue, calmed down.
        "accent-tint": "#E2F79E",
        // Ink ON lime. The accent itself is never used as a text color.
        "accent-text": "#2A3505",

        // ---- semantic status layer ----
        // Desaturated on purpose so it coexists with the warm greys instead of
        // competing with the one accent thing each screen is allowed.
        ok: "#3E9B63",
        "ok-soft": "#DFEEE4",
        warn: "#C08A2D",
        "warn-soft": "#F3EAD5",
        // The ink used on warn-soft (amber data-honesty flags) — warn itself
        // fails contrast on its own soft background at flag body-text sizes.
        "warn-text": "#77521A",
        err: "#C74F44",
        "err-soft": "#F4DFDC",
        info: "#4A7DB5",
        "info-soft": "#E0E9F2",
        mute: "#8E8E8C",
        "mute-soft": "#ECECEA",
      },

      /**
       * The one radius scale: `rounded-full` (pills, avatars, chips) ·
       * card 28 · kanban 20 · input 14 · chip 10. The mockup CSS also had a
       * few stray 12px corners (.act__i, .kbc__mid); those snap to `input`
       * here rather than earning a sixth step.
       */
      borderRadius: {
        card: "28px",
        kanban: "20px",
        input: "14px",
        chip: "10px",
      },

      /**
       * F's numerals and labels were tuned against Inter, then re-tuned for
       * Poppins (PLAN.md §1) — which is why these are half-pixel values rather
       * than a tidy geometric ramp. They are measured, not invented; do not
       * "clean them up". Names are by role so a screen cannot quietly invent a
       * 16th size with an arbitrary `text-[13.7px]`.
       */
      fontSize: {
        micro: ["10px", "1.3"], // cover badges, index-card subtitles
        mini: ["10.5px", "1.3"], // rail group labels, kanban count pills
        tiny: ["11px", "1.35"], // table headers, sub-labels under a name
        caption: ["11.5px", "1.5"], // stat deltas, hints, kanban body copy
        small: ["12px", "1.5"], // panel subtitles, breadcrumbs, legends, flags
        label: ["12.5px", "1.4"], // segmented controls, filter chips
        body: ["13px", "1.45"], // table cells, buttons, inputs, channel rows
        nav: ["13.5px", "1.4"], // topbar zone pills, rail items
        md: ["14px", "1.45"],
        lg: ["15px", "1.4"],
        brand: ["16px", "1.3"], // wordmark
        title: ["17px", "1.3"], // panel titles
        xl: ["18px", "1.25"],
        "2xl": ["19px", "1.25"],
        h1: ["30px", "1.05"], // page titles
        stat: ["38px", "1.1"], // the big stat-card numerals
      },

      letterSpacing: {
        // F's display tracking. -0.02em on the big numerals and page titles,
        // -0.01em on panel titles and the wordmark.
        display: "-0.02em",
        snug: "-0.01em",
        // Uppercase micro-labels (rail groups, table headers) open up instead.
        caps: "0.05em",
        "caps-wide": "0.09em",
      },

      fontFamily: {
        // Poppins ties the console to the marketplace surface; loaded
        // self-hosted via @fontsource/poppins in src/styles/index.css, never
        // from a CDN.
        sans: ["Poppins", "Segoe UI", "system-ui", "-apple-system", "sans-serif"],
        mono: ["ui-monospace", "Cascadia Mono", "Consolas", "monospace"],
      },

      // The single shell: 1480px wide, 28px side padding, 236px rail.
      maxWidth: { shell: "1480px" },
      width: { rail: "236px" },
      flexBasis: { rail: "236px" },

      borderWidth: { 1.5: "1.5px" },
    },
  },
  plugins: [],
};
