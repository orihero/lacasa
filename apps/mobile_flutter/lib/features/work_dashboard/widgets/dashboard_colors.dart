/// Shared, non-themed chart colors for `dashboard`'s two hand-drawn charts
/// (`ads_statistics_panel.dart`, `coworker_statistics_section.dart`) — kept
/// in one place so both agree on what "Sold"/"Lead count"/"Sale count" mean
/// visually. "Created"/"Ads count" reuse [AppAccent.color] directly at each
/// call site rather than being re-exported here, since that constant
/// already lives in `theme/app_colors.dart` and every file below already
/// imports the theme barrel.
///
/// [kDashboardSoldColor] is the mockup's own `#5a5ac8` (`mockup-e-liquid-
/// glass.html`'s `gSld` chart gradient / `.bar-row__b.b2`), used for both the
/// "Sold" chart series and the "Lead count" coworker-bar segment — the
/// mockup itself reuses this one indigo for both, not a coincidence this
/// file is inventing.
///
/// [kDashboardSaleColor] is the legend swatch for "Sale count" — chosen
/// distinct from both `AppAccent.color` (pink) and [kDashboardSoldColor]
/// (indigo) so a three-segment bar row never reads as two same-colored
/// tracks, and sitting a hair off the mockup's own `.b3` end stop
/// (`#12a97a`) it predates. The bar itself uses the mockup's gradient
/// verbatim ([kDashboardSaleBarGradient]).
library;

import 'package:flutter/material.dart';

const Color kDashboardSoldColor = Color(0xFF5A5AC8);
const Color kDashboardSaleColor = Color(0xFF2FAE73);

/// `.bar-row__b.b2{background:linear-gradient(90deg,#8f8fe0,#5a5ac8)}` —
/// the coworker bar chart fills each bar with a left-to-right gradient, not
/// a flat color. CSS `90deg` is left→right, hence
/// [Alignment.centerLeft]→[Alignment.centerRight]. The "Ads count" bar uses
/// [AppAccent.gradient] (`var(--accent-grad)`) directly at the call site,
/// the same way its legend swatch uses [AppAccent.color].
const Gradient kDashboardLeadBarGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF8F8FE0), Color(0xFF5A5AC8)],
);

/// `.bar-row__b.b3{background:linear-gradient(90deg,#6fd6b0,#12a97a)}`.
const Gradient kDashboardSaleBarGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: [Color(0xFF6FD6B0), Color(0xFF12A97A)],
);
