/* eslint-env node */
/**
 * La Casa Control Room — the ADMIN design language as a Tailwind theme.
 *
 * Every value here is lifted from `mockups/build/web-admin.src.html`'s
 * `:root` block, which stays the visual source of truth: if a value here and
 * a value there disagree, the mockup is right and this file is the bug.
 *
 * THIS APP MUST NOT LOOK LIKE apps/console, AND THAT IS A SAFETY FEATURE,
 * NOT A STYLISTIC ONE. An admin holds destructive, irreversible power over
 * other people's accounts; the worst failure mode on this surface is acting
 * on the wrong one because it looked familiar. So where the console is a
 * light warm-grey canvas with a lime accent and Poppins numerals, this is:
 *
 *   1. DARK BY DEFAULT — near-black app canvas, one step lighter for cards.
 *      There is deliberately no light theme (the mockup ships a
 *      `[data-theme=light]` override as a prototype convenience; porting it
 *      would let the control room be mistaken for the console at a glance,
 *      which is the one thing the whole palette exists to prevent).
 *   2. AMBER SIGNAL, NEVER LIME. `acc` (#f0a93b) is this surface's one
 *      attention colour. La Casa magenta is reserved here for `danger` —
 *      destructive confirmation only — so the brand colour never reads as
 *      "safe" on the screen where safe and destructive sit side by side.
 *   3. MONOSPACE RECORDS. UUIDs, timestamps, counts and audit lines are
 *      `font-mono text-record` + `tabular-nums`: this surface reads records,
 *      not properties. `text-record` is the ONLY size the mono family is
 *      used at.
 *   4. DENSE ROWS. 38px table rows, no photography larger than 26px. An
 *      admin scans hundreds of rows; a comfortable console row height would
 *      halve what fits on screen.
 *
 * ONE SCALE PER THING, same discipline as apps/console/tailwind.config.js.
 * The mockup CSS drifted across nine corner radii (5/6/7/8/9/10/11/12/14) and
 * a dozen ad-hoc font sizes; each is collapsed to exactly one name below so
 * the drift cannot come back. Reach for an arbitrary `rounded-[9px]` or
 * `text-[11.7px]` in a screen and the rule is eroding.
 */
/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // ---- surfaces: four steps of near-black, darkest to lightest ----
        // `rail` is DARKER than `app` (not lighter, as a light UI would do):
        // the nav recedes and the records come forward.
        rail: "#0a0d14",
        app: "#080a10",
        // Sunk below the card: table headers, inputs, inert chips, the
        // "empty channel" of a progress bar.
        sunk: "#0c0f16",
        // The one raised surface — every panel, KPI tile and queue card.
        card: "#11141c",

        // ---- ink: four steps, brightest to faintest ----
        ink: "#e9ebf2",
        "ink-2": "#aeb2c2",
        muted: "#7c8195",
        // Dimmest readable step: table column headers and "—" no-value cells.
        faint: "#5a5f72",

        // ---- hairlines ----
        line: "rgba(255,255,255,.09)",
        // Half-strength: between table rows, where a full `line` at 38px row
        // height turns the table into a grid.
        "line-2": "rgba(255,255,255,.05)",

        // ---- amber signal ----
        acc: "#f0a93b",
        "acc-soft": "rgba(240,169,59,.15)",
        "acc-line": "rgba(240,169,59,.42)",
        // Ink ON amber (and on `ok`): the signal colours are backgrounds for
        // small solid controls, never text on the dark canvas at body size.
        "on-acc": "#12141a",
        "on-ok": "#04150c",

        // ---- destructive ----
        // La Casa magenta, quarantined to this one role. A `danger` button is
        // a confirmation of something irreversible, never a general accent.
        danger: "#f5439b",
        "danger-soft": "rgba(245,67,155,.16)",

        // ---- semantic status layer ----
        // A third category distinct from both the surfaces and the accent:
        // approved/rejected/pending, published/failed and the lead stages are
        // all already colour-coded and cannot all be amber.
        ok: "#2bb673",
        "ok-soft": "rgba(43,182,115,.15)",
        err: "#e5484d",
        "err-soft": "rgba(229,72,77,.15)",
        info: "#5b8def",
        "info-soft": "rgba(91,141,239,.15)",
      },

      /**
       * The one radius scale: tag 5 · act 6 · nav 7 · control 8 · panel 11 ·
       * modal 14. The mockup's stray 9/10/12px corners (`.who`, `.warn`,
       * `.ix__g button`) snap to the nearest of these rather than earning
       * three more steps.
       */
      borderRadius: {
        tag: "5px",
        act: "6px",
        nav: "7px",
        control: "8px",
        panel: "11px",
        modal: "14px",
      },

      /**
       * Named by ROLE, not by number, so a screen cannot quietly invent a
       * thirteenth size with an arbitrary `text-[11.7px]`. These are the
       * mockup's measured values — half-pixel and all — not a tidy geometric
       * ramp; do not "clean them up".
       */
      fontSize: {
        micro: ["9px", "1.3"], // rail section headers, brand sub-label
        caps: ["9.5px", "1.3"], // table column headers, KPI labels
        mini: ["10px", "1.35"], // rail count badges, tag text, row sub-lines
        tiny: ["10.5px", "1.4"], // panel subtitles, KPI deltas, kv terms
        record: ["11px", "1.45"], // THE mono size: UUIDs, audit lines, phones
        small: ["11.5px", "1.5"], // kv values, filter chips, segment labels
        body: ["12px", "1.45"], // table cells, buttons, rail nav rows
        label: ["12.5px", "1.45"], // the document base size, panel titles
        lg: ["13px", "1.4"], // modal titles
        title: ["13.5px", "1.35"], // the topbar page title
        xl: ["14px", "1.3"], // wordmark
        kpi: ["24px", "1"], // the big KPI numerals
      },

      letterSpacing: {
        // The KPI numerals and the wordmark pull in…
        display: "-0.9px",
        snug: "-0.3px",
        // …while every uppercase micro-label opens up. Three steps because
        // the smaller the caps, the more tracking they need to stay legible.
        caps: "0.4px",
        "caps-wide": "0.7px",
        "caps-widest": "1.1px",
      },

      fontFamily: {
        // Poppins ties the three surfaces to one company; the palette is what
        // tells them apart. Self-hosted via @fontsource/poppins in
        // src/styles/index.css, never from a CDN.
        sans: ["Poppins", "system-ui", "-apple-system", "Segoe UI", "sans-serif"],
        mono: ["ui-monospace", "Cascadia Mono", "Consolas", "monospace"],
      },

      /**
       * The mockup's `--shadow`: a 1px contact edge plus a wide, heavily
       * negative-spread ambient. Unlike apps/console (which bans shadows
       * outright), depth is load-bearing here — on a near-black canvas the
       * only thing separating `card` from `app` is 9% of luminance, and the
       * contact edge is what stops a panel dissolving into the background.
       */
      boxShadow: {
        panel: "0 1px 2px rgba(0,0,0,.6), 0 10px 30px -22px rgba(0,0,0,1)",
      },

      // The shell: a 224px rail against a fluid records column. No max-width
      // — an admin's 8-column user table wants every pixel of a wide monitor,
      // where the console's property cards do not.
      width: { rail: "224px" },
      gridTemplateColumns: { shell: "224px 1fr" },

      // 38px rows (see rule 4) and the 26px row avatar, as named sizes so a
      // screen cannot drift a table to 44px one row at a time.
      height: { row: "38px", topbar: "50px" },
      minHeight: { row: "38px" },
      spacing: { av: "26px" },
    },
  },
  plugins: [],
};
