/// `.sw.ro` — the read-only channel-status switch every row on
/// `connected-accounts` (§21) uses. SCREENS.md §5's "Toggle states" rule is
/// explicit: these three switches (Instagram/Telegram/YouTube) are status
/// indicators only, never directly tappable — connecting/disconnecting
/// happens exclusively through the buttons beneath each row. Deliberately
/// **not** `settings_screen.dart`'s `_NotificationsSwitch`: that one is a
/// real, tappable control with its own `GestureDetector`/`onChanged` — the
/// two widgets look almost identical but must never be confused for one
/// another, hence two small widgets rather than one with a `readOnly` flag
/// that would make every call site re-verify which behaviour it got.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class ReadOnlyChannelSwitch extends StatelessWidget {
  const ReadOnlyChannelSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return Semantics(
      // No `button: true` — this control cannot be tapped, so it must never
      // present as one to assistive tech either.
      toggled: value,
      label: value ? 'Connected' : 'Not connected',
      child: Container(
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value ? AppAccent.gradient : null,
          color: value ? null : colors.sunk,
          border: value ? null : Border.all(color: colors.line, width: 1),
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x47140F20),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
