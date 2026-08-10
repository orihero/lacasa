/// The bare title-plus-read-only-switch row every channel section on
/// `connected-accounts` (§21) opens with — "Create Instagram post" /
/// "Create Telegram post" / "Create Youtube post". Shared by all three
/// section widgets rather than copy-pasted three times.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'read_only_channel_switch.dart';

class ChannelToggleRow extends StatelessWidget {
  const ChannelToggleRow({super.key, required this.title, required this.on});

  final String title;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: type.panelHeading.copyWith(color: colors.ink),
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        ReadOnlyChannelSwitch(value: on),
      ],
    );
  }
}
