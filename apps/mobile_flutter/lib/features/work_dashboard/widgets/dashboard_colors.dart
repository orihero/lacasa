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
/// [kDashboardSaleColor] has no mockup precedent — the mockup was built
/// before "Sale count" had any real data behind it (it rendered as a
/// permanent em dash, see `coworker_statistics_section.dart`'s doc comment),
/// so there is no `.b3`/third gradient to match. Chosen distinct from both
/// [AppAccent.color] (pink) and [kDashboardSoldColor] (indigo) so a
/// three-segment bar row never reads as two same-colored tracks.
library;

import 'package:flutter/material.dart';

const Color kDashboardSoldColor = Color(0xFF5A5AC8);
const Color kDashboardSaleColor = Color(0xFF2FAE73);
