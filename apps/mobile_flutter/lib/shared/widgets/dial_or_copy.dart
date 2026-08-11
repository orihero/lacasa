/// The dial-a-phone-number-with-honest-fallback pattern, shared by every
/// call button that dials via [LinkLauncher.dial]: `profile-agent`'s own
/// phone row, `listing-detail`'s agent block ([ListingAgentRow]) and
/// `agent-profile`'s Call action ([AgentInfoBlock]). Byte-identical logic
/// existed independently in all three before this pass — the cross-slice
/// coherence review that found it promoted it here rather than leaving a
/// third copy to drift out of sync with the other two.
///
/// A device can decline a `tel:` intent for reasons this app cannot fix —
/// no dialer installed, or the OS refusing the launch — so [dialOrCopyPhone]
/// never treats that as a dead end: it falls back to copying the number and
/// says so in the toast, the same honesty rule every other stand-in in this
/// app follows.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../platform/link_launcher.dart';
import 'toast.dart';

/// Dials [phone] through [linkLauncherProvider]. If nothing on the device
/// answers the `tel:` intent, copies [phone] to the clipboard and shows a
/// toast saying exactly that instead of leaving the tap looking like it did
/// nothing.
Future<void> dialOrCopyPhone(
  BuildContext context,
  WidgetRef ref,
  String phone,
) async {
  final dialed = await ref.read(linkLauncherProvider).dial(phone);
  if (!context.mounted || dialed) return;

  await Clipboard.setData(ClipboardData(text: phone));
  if (!context.mounted) return;
  LaCasaToast.showSuccess(
    context,
    AppLocalizations.of(context).sharedDialFallbackToastMessage(phone),
  );
}
