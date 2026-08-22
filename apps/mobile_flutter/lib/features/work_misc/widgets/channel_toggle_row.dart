/// The header row every channel section on `connected-accounts` (§21)
/// opens with — the mockup's `.chan__h`: a 38px brand tile, the channel
/// title over a small status subtitle, and the read-only status switch.
/// Shared by all three section widgets rather than copy-pasted three times.
///
/// **The brand tile's gradient is passed in by the caller, not themed.**
/// `.chan__ic.ig/.tg/.yt` are Instagram/Telegram/YouTube brand gradients —
/// they belong to those companies, not to Direction E's palette, so they
/// stay local consts at each call site instead of leaking into
/// `lib/theme/`. The glyphs are Material stand-ins for the mockup's
/// Phosphor brand marks, per the substitution policy documented in
/// `navigation/shell/glass_tab_bar.dart`.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'read_only_channel_switch.dart';

class ChannelToggleRow extends StatelessWidget {
  const ChannelToggleRow({
    super.key,
    required this.title,
    required this.on,
    required this.icon,
    required this.iconGradient,
    this.subtitle,
  });

  final String title;
  final bool on;

  /// Glyph painted white inside the brand tile — `.chan__ic .i{font-size:19px}`.
  final IconData icon;

  /// The channel's brand gradient — `.chan__ic.ig/.tg/.yt`.
  final Gradient iconGradient;

  /// `.lrow__s` under the title. Optional so a channel with nothing
  /// honest to say there renders the title alone rather than a blank line.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      children: [
        // `.chan__ic{width:38px;height:38px;border-radius:13px;
        // font-size:19px;color:#fff}`.
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: iconGradient,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
        // `.chan__h{gap:12px}`.
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // `.lrow__t{font-size:13px;font-weight:600;color:var(--ink)}`.
              Text(title, style: type.rowTitle.copyWith(color: colors.ink)),
              if (subtitle case final subtitle?) ...[
                // `.lrow__s{margin-top:2px;font-size:10.5px;
                // color:var(--muted)}`.
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        ReadOnlyChannelSwitch(value: on),
      ],
    );
  }
}
