/**
 * src/theme — the MUI theme that makes this app look like apps/web.
 *
 * apps/web itself has no theme: it renders MUI with factory defaults and beats
 * them into shape with a universal `font-family` rule plus one-off `sx` props
 * (web-design-contract.md §15.2). That works there because its MUI surface is
 * three tables and two modals. It would not work here — the control room is
 * MUI end to end (tables, dialogs, buttons, selects, skeletons, chips), and
 * "retype the yellow at every use site" across a surface this size is how the
 * yellow stops being one yellow.
 *
 * So the divergence is deliberate and narrow: every value below is a colour or
 * a metric quoted from apps/web's SCSS, moved into one file so MUI's defaults
 * cannot leak through. Nothing new is invented here. A component that needs a
 * shape apps/web draws by hand still gets a hand-written SCSS file next to it —
 * this theme covers what MUI renders, not what we render.
 *
 * The palette, with the job each colour does in apps/web:
 *   #fece51  accent yellow — every primary button, the active nav row, the role
 *            badge, the input focus ring. Flat: no gradient, no hover shift.
 *   #051d42  navy — the secondary/cancel button (`.cancel-btn`).
 *   #f5f6fa  the app canvas behind the white panels (`.agent-content`).
 *   #ffffff  every panel (`.sidebar`, `.content-list`, every MUI Paper).
 *   #dedede  list-row border;  #eeeeee row hover;  #e0e0e0 filter-control border
 *   #dddd    the hairline on inputs (a 4-digit typo for #dd that apps/web has
 *            carried since the beginning; kept as-is so a copied rule matches)
 *   #8d99ae  muted icon grey;  #2b2d42 dark icon / body ink
 *   rgb(216,72,53)  the destructive button (`.delete-btn`)
 */
import { createTheme } from "@mui/material/styles";

const ACCENT = "#fece51";
const NAVY = "#051d42";
const CANVAS = "#f5f6fa";
const PANEL = "#ffffff";
const INK = "#2b2d42";
const MUTED = "#8d99ae";
const HAIRLINE = "#dddd";
const ROW_BORDER = "#dedede";
const ROW_HOVER = "#eeeeee";
const CONTROL_BORDER = "#e0e0e0";
const DESTRUCTIVE = "rgb(216, 72, 53)";

export const theme = createTheme({
  palette: {
    mode: "light",
    primary: {
      main: ACCENT,
      // Black text on the yellow, exactly as the SCSS button rule leaves it:
      // it sets a background and no colour, so the button inherits the
      // browser's default black. MUI would otherwise compute white here and
      // the accent's whole identity is black-on-yellow.
      contrastText: "#000000",
    },
    secondary: {
      main: NAVY,
      contrastText: "#ffffff",
    },
    error: {
      main: DESTRUCTIVE,
      contrastText: "#ffffff",
    },
    background: {
      default: CANVAS,
      paper: PANEL,
    },
    text: {
      primary: INK,
      secondary: MUTED,
    },
    divider: ROW_BORDER,
    action: {
      hover: ROW_HOVER,
    },
  },

  typography: {
    // Restated even though `* { font-family }` in index.scss already wins, so
    // that anything reading the theme (a styled() call, a chart label) gets the
    // same answer as anything reading the cascade.
    fontFamily: '"Plus Jakarta Sans", sans-serif',
    // The sizes apps/web actually renders. h5 is the dominant screen-title
    // convention (`<Typography variant="h5">` inside `.ads-title`); h2 is the
    // dashboard's `.chart-header h2`; h1 is the profile page's light 2rem
    // title. The rest are MUI's defaults, untouched, because apps/web never
    // renders them.
    h1: { fontSize: "2rem", fontWeight: 300 },
    h2: { fontSize: "1.5rem", fontWeight: 700 },
    h5: { fontSize: "1.5rem", fontWeight: 400 },
    button: {
      // apps/web's buttons are plain `<button>`s with no text-transform, so
      // MUI's SHOUTING default is the single most foreign-looking thing it
      // would bring in.
      textTransform: "none",
      fontWeight: 600,
    },
  },

  // Square. `.content-list`, `.sidebar` and every SCSS button in apps/web have
  // no border-radius at all; MUI's 4px default is what would make a rebuilt
  // screen read as "an MUI app" rather than "the console".
  shape: { borderRadius: 0 },

  components: {
    MuiButton: {
      defaultProps: {
        disableElevation: true,
      },
      styleOverrides: {
        contained: {
          // The five-line accent block repeated verbatim in fourteen of
          // apps/web's SCSS files. Note the hover: apps/web's buttons have no
          // hover state, and MUI's default darkening would introduce one.
          padding: "12px 24px",
          boxShadow: "none",
          "&:hover": { boxShadow: "none" },
        },
        containedPrimary: {
          backgroundColor: ACCENT,
          color: "#000000",
          "&:hover": { backgroundColor: ACCENT },
        },
        containedSecondary: {
          backgroundColor: NAVY,
          color: "#ffffff",
          "&:hover": { backgroundColor: NAVY },
        },
        outlined: {
          padding: "11px 23px", // 12/24 less the 1px border, so the two line up
        },
      },
    },

    MuiPaper: {
      styleOverrides: {
        rounded: { borderRadius: 0 },
      },
    },

    MuiTableCell: {
      styleOverrides: {
        root: {
          borderBottom: `1px solid ${ROW_BORDER}`,
        },
        head: {
          // Sticky headers sit over scrolling rows; apps/web's tables are white
          // panels, so the header has to be opaque or the rows read through it.
          backgroundColor: PANEL,
          fontWeight: 600,
        },
      },
    },

    MuiTableRow: {
      styleOverrides: {
        root: {
          "&.MuiTableRow-hover:hover": {
            backgroundColor: ROW_HOVER,
          },
        },
      },
    },

    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          "& .MuiOutlinedInput-notchedOutline": {
            borderColor: HAIRLINE,
            borderWidth: "1px",
          },
          "&:hover .MuiOutlinedInput-notchedOutline": {
            borderColor: HAIRLINE,
          },
          // The yellow focus ring: `input:focus { border: 1px solid #fece51; }`.
          // Held at 1px because MUI thickens a focused outline to 2px, which
          // next to apps/web's 1px inputs reads as a different control.
          "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
            borderColor: ACCENT,
            borderWidth: "1px",
          },
          "&.Mui-error .MuiOutlinedInput-notchedOutline": {
            borderColor: "red",
          },
        },
      },
    },

    MuiSelect: {
      styleOverrides: {
        select: {
          // apps/web's filter bar uses native selects at this geometry
          // (`padding: 10px; border: 1px solid #e0e0e0; font-size: 14px`).
          padding: "10px",
          fontSize: "14px",
        },
      },
    },

    MuiInputBase: {
      styleOverrides: {
        input: {
          fontSize: "14px",
        },
      },
    },

    MuiFormLabel: {
      styleOverrides: {
        root: {
          fontSize: "10px",
          color: INK,
          "&.Mui-focused": { color: INK },
        },
      },
    },

    MuiDialog: {
      styleOverrides: {
        paper: {
          borderRadius: 0,
        },
      },
    },

    MuiDivider: {
      styleOverrides: {
        root: { borderColor: CONTROL_BORDER },
      },
    },

    MuiSkeleton: {
      styleOverrides: {
        root: {
          // The skeletons the screen specs require (6×6 applications, 8×8
          // users, 8×5 audit) are the one thing on this surface apps/web has no
          // equivalent for, so they are toned down to the row borders rather
          // than MUI's default grey, which is louder than any real row.
          backgroundColor: ROW_HOVER,
        },
      },
    },
  },
});

export default theme;
