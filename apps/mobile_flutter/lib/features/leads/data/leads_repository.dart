/// Data-access seam for every `leads` screen (`leads-list` §30,
/// `leads-kanban` §31, `lead-detail` §32, `create-lead` §33,
/// `kanban-move-sheet` §34). Two implementations exist —
/// [FixtureLeadsRepository] (bundled seed data, no network) and
/// [LiveLeadsRepository] (the real [LaCasaApi]) — see `leads_mode.dart` for
/// which one the app wires up by default and how to switch.
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws so widgets only need to know about that one exception hierarchy
/// regardless of which implementation is active.
library;

import '../../../api/api.dart';

abstract class LeadsRepository {
  /// `GET /leads` — the entire list, no pagination (see
  /// `WORK_TAB_CONTRACT.md` §4.1's `LeadsResource.list` doc comment). Both
  /// `leads-list` and `leads-kanban` read from this one fetch.
  Future<List<Lead>> list();

  /// A single lead by id — `lead-detail`'s data source when it's opened
  /// with only an id in hand (e.g. from `notifications`, which never has
  /// the full [Lead] already loaded the way a row tap on `leads-list`
  /// does).
  Future<Lead> getById(String id);

  Future<Lead> create(LeadWriteInput input);

  Future<Lead> update(String id, LeadWriteInput input);

  /// AGENT-only server-side (403 for a COWORKER session) — callers must
  /// gate the Delete affordance on role themselves rather than surface that
  /// 403 as a surprise; see `lead_detail_sheet.dart`'s own doc comment.
  Future<void> delete(String id);

  /// Backs the read-only "Coworker" line on `lead-detail`/`create-lead`
  /// (SCREENS.md §32/§33's "Coworker select (agent role only)"). **Not an
  /// assignment control** — see `lead_detail_sheet.dart`'s doc comment for
  /// why: `LeadWriteInput` has no `coworkerId` field at all, so there is no
  /// wire path that could ever persist a selection here, matching
  /// `AdWriteInput.coworkerId`'s identical, already-documented gap.
  Future<List<Coworker>> coworkers();
}
