import {
  ControlledBoard,
  KanbanBoard,
  moveCard,
  OnDragEndNotification,
} from "@caldwell619/react-kanban";
import { Box, Button, Drawer, Modal, styled, Typography } from "@mui/material";
import { resolveCardMoveAction } from "@lacasa/domain";
import type { LeadStatusKey } from "@lacasa/domain";
import type { Coworker, Lead } from "@lacasa/api-client";
import React, { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
import { useLeadStore } from "../../lib/useLeadStore";
import { useUserStore } from "../../lib/userStore";
import LeadUpdate from "../leadUpdate/LeadUpdate";
import { Filters, RenderCard, renderColumnHeader } from "./kanban/components";
import { CustomCard } from "./kanban/data";
import "./leadList.scss";
import { Triangle } from "react-loader-spinner";

// useLeadStore/useCoworkerStore are plain untyped JS stores (out of scope
// for this pass — see report), so `list`/`coworkerList` come back inferred
// as `never[]`. @lacasa/api-client's `Lead`/`Coworker` are what those
// stores' own `apiClient.leads.list()`/`apiClient.coworkers.list()` calls
// are actually typed to resolve, so casting to them here (rather than to
// `any`) reflects the real shape without widening it away.

// The exact (source, destination) pair handleCardMove receives from
// react-kanban's onCardDragEnd, stashed for confirm-callback/confirm-comment
// moves so handleSave can finish the move once the modal is submitted.
type DragEndArgs = Parameters<OnDragEndNotification<CustomCard>>;
interface PendingMove {
  source: DragEndArgs[1];
  destination: DragEndArgs[2];
}

export default function LeadKanbanList() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { id } = useParams();
  const { isLoading, list, fetchLeadList, updateLeadById, isUpdated } =
    useLeadStore();
  const { list: coworkerList, fetchCoworkerList } = useCoworkerStore();
  const [kanbanBoard, setKanbanBoard] = useState<KanbanBoard<CustomCard>>({
    columns: [],
  });
  const [selectCard, setSelectCard] = useState<CustomCard | null>(null);
  const [moveObject, setMoveObject] = useState<PendingMove | undefined>(
    undefined,
  );
  const { currentUser } = useUserStore();
  const [open, setOpen] = React.useState(false);
  const [openModalType, setOpenModalType] = React.useState("");
  const [callBackTime, setCallBackTime] = React.useState("");
  const [commentConver, setCommentConverstion] = React.useState("");
  const [isOpenDrawer, setIsOpenDrawer] = useState(false);
  const handleOpen = (card: CustomCard) => {
    setIsOpenDrawer(true);
    setSelectCard(card);
  };
  const handleClose = () => {
    setOpen(false);
    setOpenModalType("");
  };

  useEffect(() => {
    if (currentUser?.role == "agent") {
      fetchLeadList(id);
      fetchCoworkerList(id);
    } else if (currentUser?.role == "coworker") {
      fetchLeadList(currentUser.agentId);
      fetchCoworkerList(currentUser.agentId);
    }
  }, [
    currentUser?.agentId,
    currentUser?.role,
    id,
    isUpdated,
    fetchLeadList,
    fetchCoworkerList,
  ]);

  const handleNavigateNew = () => {
    navigate("/profile/" + id + "/create/leads");
  };

  // Depends on the full `list`/`coworkerList` arrays (not just their
  // lengths) because it reads coworker name/avatar per card and rebuilds
  // every column from `list` contents, not just its size.
  const generateBoard = useCallback(async () => {
    const columnIds: LeadStatusKey[] = [
      "new",
      "could_not_connect",
      "need_to_call_back",
      // "pick_date",
      "rejected",
      "accepted",
    ];
    const leads = list as Lead[];
    const coworkers = coworkerList as Coworker[];
    let board: KanbanBoard<CustomCard> = {
      columns: columnIds.map((e) => {
        return {
          id: e,
          title: t(e),
          cards: leads.reduce<CustomCard[]>((p, c) => {
            if (c.status == e) {
              return [
                ...p,
                {
                  id: c.id,
                  coworkerId: c.coworkerId,
                  coworkerFullName:
                    coworkers?.find((i) => i.id == c.coworkerId)?.fullName ??
                    "",
                  coworkerImg:
                    coworkers?.find((i) => i.id == c.coworkerId)?.avatar ??
                    "/avatar.jpg",
                  createdAt: c.createdAt,
                  storyPoints: c.phone,
                  title: c.fullName,
                  comment: c.comment,
                  callbackDate: c.callbackDate,
                  // `c.status` is a plain `string` on the API-client Lead
                  // type; `e` is the already-narrowed LeadStatusKey we just
                  // confirmed it equals above.
                  status: e,
                  conversationComment: c?.conversationComment ?? "",
                },
              ];
            }
            return p;
          }, []),
        };
      }),
    };

    setKanbanBoard(board);
  }, [list, coworkerList, t]);

  useEffect(() => {
    if ((!isLoading && list.length > 0) || coworkerList?.length)
      generateBoard();
  }, [list, coworkerList, isLoading, generateBoard]);

  const handleCardMove: OnDragEndNotification<CustomCard> = async (
    _card,
    source,
    destination,
  ) => {
    const sourceColumn = source?.fromColumnId as LeadStatusKey;
    const destColumn = destination?.toColumnId as LeadStatusKey;
    const action = resolveCardMoveAction(sourceColumn, destColumn, _card);

    if (action.type === "confirm-callback") {
      setOpen(true);
      setSelectCard(action.card);
      setMoveObject({ source, destination });
      return;
    }

    if (action.type === "confirm-comment") {
      setOpenModalType("rejected_accepted");
      setSelectCard(action.card);
      setOpen(true);
      setMoveObject({ source, destination });
      return;
    }

    // Server logs the LEAD_STATUS_CHANGED activity event itself.
    await updateLeadById(_card?.id, {
      ..._card,
      status: destination?.toColumnId,
    });

    setKanbanBoard((currentBoard) => {
      return moveCard(currentBoard, source, destination);
    });
  };

  const handleSave = async () => {
    // Genuine latent bug fixed here: handleSave previously read
    // `moveObject.source`/`moveObject?.destination` unconditionally, even
    // though `moveObject` only gets set by handleCardMove's
    // confirm-callback/confirm-comment branches. Nothing else clears
    // `open`/`openModalType` in a way that lets Save fire without a drag
    // having happened first, so this hasn't been observed to crash — but
    // there was no guard against it, and `moveObject.source` (no `?.`) would
    // have thrown if it ever did. Same reasoning for `selectCard`.
    if (!moveObject || !selectCard) return;
    const { source, destination } = moveObject;

    if (openModalType == "rejected_accepted") {
      await updateLeadById(selectCard.id, {
        ...selectCard,
        conversationComment: commentConver,
        status: destination?.toColumnId,
      });

      setKanbanBoard((currentBoard) => {
        return moveCard(currentBoard, source, destination);
      });
      handleClose();
    } else {
      await updateLeadById(selectCard.id, {
        ...selectCard,
        callbackDate: callBackTime,
        status: destination?.toColumnId,
      });

      setKanbanBoard((currentBoard) => {
        return moveCard(currentBoard, source, destination);
      });
      handleClose();
    }
  };

  const style = {
    position: "absolute",
    top: "50%",
    left: "50%",
    transform: "translate(-50%, -50%)",
    width: 400,
    bgcolor: "background.paper",
    boxShadow: 24,
    p: 4,
  };

  return (
    <div className="ads-list-content">
      <div className="ads-new">
        <div className="ads-title">
          <Typography variant="h5">{t("kanban")}</Typography>
        </div>
        <button onClick={handleNavigateNew}>{t("addNewLead")}</button>
      </div>
      {isUpdated && (
        <div className="loading-kanban">
          <Triangle
            visible={true}
            height="80"
            width="80"
            color="#4fa94d"
            ariaLabel="triangle-loading"
            wrapperStyle={{}}
            wrapperClass=""
          />
        </div>
      )}
      <div className="kanban-content">
        {kanbanBoard.columns.length > 0 && (
          <NotionStyles
            style={{
              height: "580px",
              overflow: "scroll",
            }}
          >
            {/* <Typography variant="h4">Kanban</Typography> */}
            <Filters />
            {/* <UncontrolledBoard
              initialBoard={kanbanBoard}
              renderColumnHeader={renderColumnHeader}
              renderCard={renderCard}
              onCardDragEnd={(e) => console.log(e.title, "onCardDragEnd")}
            /> */}
            <ControlledBoard
              renderCard={(card) => (
                <RenderCard
                  isUpdated={isUpdated}
                  handleOpenModal={handleOpen}
                  {...card}
                />
              )}
              renderColumnHeader={renderColumnHeader}
              onCardDragEnd={handleCardMove}
              // renderColumnAdder={() => <div>sas</div>}
              allowAddCard={false}
            >
              {kanbanBoard}
            </ControlledBoard>
          </NotionStyles>
        )}
      </div>
      <Modal
        open={open}
        onClose={handleClose}
        aria-labelledby="modal-modal-title"
        aria-describedby="modal-modal-description"
      >
        <Box sx={style}>
          {openModalType == "rejected_accepted" ? (
            <div className="kanban-modal">
              <Typography id="modal-modal-title" variant="h6" component="h2">
                Suxbat haqida qisqacha yozing
              </Typography>
              <div className="field">
                <label>{t("commit")}:</label>
                <textarea
                  minLength={10}
                  onChange={(e) => setCommentConverstion(e.target.value)}
                ></textarea>
              </div>
            </div>
          ) : (
            <div className="kanban-modal">
              <Typography id="modal-modal-title" variant="h6" component="h2">
                Keyingi qo&apos;ng&apos;iroq qilish vaqtini kiriting
              </Typography>
              <div className="field">
                <label>{t("callTime")}:</label>
                <input
                  onChange={(e) => setCallBackTime(e.target.value)}
                  type="datetime-local"
                  placeholder={t("select_date")}
                />
              </div>
            </div>
          )}
          <Box sx={{ gap: "10px", display: "flex" }}>
            <Button
              variant="outlined"
              color="error"
              onClick={handleClose}
              className="cancel-btn"
            >
              {t("cancel")}
            </Button>
            <Button variant="contained" onClick={handleSave}>
              {t("save")}
            </Button>
          </Box>
        </Box>
      </Modal>
      <Drawer
        anchor={"right"}
        open={isOpenDrawer}
        onClose={() => setIsOpenDrawer(false)}
      >
        <LeadUpdate
          leadId={selectCard?.id}
          onClose={() => setIsOpenDrawer(false)}
        />
      </Drawer>
    </div>
  );
}

const NotionStyles = styled("div")`
  & * {
    font-family: "Segoe" !important;
  }
  & h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    font-family: "Segoe Bold" !important;
  }
  & .react-kanban-column {
    padding: 0;
    background-color: transparent;
  }
`;
