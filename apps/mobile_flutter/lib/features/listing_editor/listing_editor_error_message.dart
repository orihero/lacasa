/// The one place this feature turns a thrown error into a sentence a user
/// can act on.
///
/// **Why this is a top-level function and not a private copy per screen.**
/// Every write this feature makes — `create-listing`'s Create,
/// `edit-listing`'s Save and Delete, `publish-status`' Retry,
/// `publish-channels-sheet`'s Instagram and Telegram fan-out — can fail for
/// genuinely different reasons, and the app's honesty rule says the user
/// must be able to tell them apart: a server validation rejection ("Price
/// must be a number") is a thing you fix, being offline is a thing you wait
/// out, and an unrecognised failure is neither. `publish-status` and
/// `publish-channels-sheet` each already drew that distinction with their
/// own identical private `_messageFor`; the three write sites on the app's
/// longest form did not — they passed
/// `errorMessage: (_) => listingEditorGenericErrorMessage`, which threw the
/// typed exception away and reported "Something went wrong." for all three
/// situations. Both private copies are gone and all six sites call this, so
/// there is genuinely one mapping to change rather than a shared helper
/// sitting next to survivors of the consolidation.
///
/// **The three branches, in order:**
/// - [ApiErrorException] — the server wrote a specific, user-legible
///   sentence for this exact rejection (see `ApiException.message`'s own
///   doc comment). Show it verbatim; nothing this client could substitute
///   would be more useful than what the server already said.
/// - [NetworkException] — the request never reached a server, so there is
///   no server sentence to show and "something went wrong" would be a lie
///   about where the problem is. `listingEditorNetworkErrorMessage` names
///   the connection and tells the user to retry.
/// - anything else (a `FormatException` off a malformed body, a bug) —
///   `listingEditorGenericErrorMessage`, which stays as the honest "we do
///   not know" case rather than the catch-all it had become.
///
/// Takes [l10n] rather than a [BuildContext] because it is a pure function,
/// not a widget — see `lib/l10n/README.md`'s guidance for threading
/// localization through a non-widget file. Takes `Object` (not
/// [ApiException]) because that is the type `LaCasaToast.run`'s
/// `errorMessage` callback is handed, and a repository is free to let a
/// non-[ApiException] escape.
library;

import '../../api/api.dart';
import '../../l10n/generated/app_localizations.dart';

String listingEditorErrorMessage(AppLocalizations l10n, Object error) {
  if (error is ApiErrorException) return error.message;
  if (error is NetworkException) return l10n.listingEditorNetworkErrorMessage;
  return l10n.listingEditorGenericErrorMessage;
}
