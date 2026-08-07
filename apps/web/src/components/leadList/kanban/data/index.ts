import type { Card } from "@caldwell619/react-kanban";
import type { DateLike, LeadStatusKey } from "@lacasa/domain";

// This module used to scaffold a demo Kanban board (a `board` constant and
// `createNewCard()` built from `random-rgba` + `@faker-js/faker`, plus a
// `ticketType`/`assigneeId`/`prLink`-shaped CustomCard) — leftovers from the
// @caldwell619/react-kanban starter template. Neither package is (or ever
// was) a dependency of this workspace, and nothing in LeadKanbanList ever
// imported `board`/`createNewCard`: LeadKanbanList.tsx builds its own board
// straight from the `list`/`coworkerList` stores. Since every consumer only
// ever imported the `CustomCard` *type* (a type-only usage that Vite/esbuild
// elides from the bundle), that demo data never actually ran — but it did
// block `tsc`. It's removed here and CustomCard now describes what
// generateBoard() in LeadKanbanList.tsx actually builds from a Lead.
export interface CustomCard extends Card {
  id: string;
  coworkerId: string;
  coworkerFullName: string;
  coworkerImg: string;
  createdAt: DateLike;
  /** Reuses the kanban template's "story points" slot to show the lead's phone number. */
  storyPoints: string;
  comment: string | null;
  callbackDate: DateLike;
  status: LeadStatusKey;
  conversationComment: string;
  /**
   * Leftover from the demo template's TicketType field. generateBoard()
   * never sets it, so it has always rendered as nothing in Card.tsx; kept
   * (optional, unpopulated) rather than removed to avoid touching that
   * render output as part of a type-only pass — see report.
   */
  ticketType?: string;
}
