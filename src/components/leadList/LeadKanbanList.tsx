import {
  KanbanBoard,
  UncontrolledBoard,
  ControlledBoard,
  moveCard,
  OnDragEndNotification,
  Card,
} from "@caldwell619/react-kanban";
import { Box, Drawer, Modal, styled, Typography } from "@mui/material";
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { useLeadStore } from "../../lib/useLeadStore";
import { Filters, RenderCard, renderColumnHeader } from "./kanban/components";
import { board, CustomCard } from "./kanban/data";
import { useUserStore } from "../../lib/userStore";
import "./leadList.scss";
import { useCoworkerStore } from "../../lib/useCoworkerStore";
import { Triangle } from "react-loader-spinner";
import LeadUpdate from "../leadUpdate/LeadUpdate";

export default function LeadKanbanList() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { id } = useParams();
  const { isLoading, list, fetchLeadList, updateLeadById, isUpdated } =
    useLeadStore();
  const { list: coworkerList, fetchCoworkerList } = useCoworkerStore();
  const [kanbanBoard, setKanbanBoard] = useState({ columns: [] });
  const [selectCard, setSelectCard] = useState({});
  const [moveObject, setMoveObject] = useState();
  const { currentUser } = useUserStore();
  const [open, setOpen] = React.useState(false);
  const [openModalType, setOpenModalType] = React.useState("");
  const [callBackTime, setCallBackTime] = React.useState("");
  const [commentConver, setCommentConverstion] = React.useState("");
  const [isOpenDrawer, setIsOpenDrawer] = useState(false);
  const handleOpen = (card) => {
    setIsOpenDrawer(true);
    setSelectCard(card);
  };
  const handleClose = () => {
    setOpen(false);
    setOpenModalType("");
  };

  useEffect(() => {
    if (currentUser.role == "agent") {
      fetchLeadList(id);
      fetchCoworkerList(id);
    } else if (currentUser.role == "coworker") {
      fetchLeadList(currentUser.agentId);
      fetchCoworkerList(currentUser.agentId);
    }
  }, [currentUser?.agentId, id, isUpdated]);

  useEffect(() => {
    if (!isLoading && list.length > 0 && coworkerList?.length) generateBoard();
  }, [list?.length, coworkerList.length]);

  const handleNavigateNew = () => {
    navigate("/profile/" + id + "/create/leads");
  };

  const generateBoard = async () => {
    let board: KanbanBoard<CustomCard> = {
      columns: [
        "new",
        "could_not_connect",
        "need_to_call_back",
        // "pick_date",
        "rejected",
        "accepted",
      ].map((e) => {
        return {
          id: e,
          title: t(e),
          cards: (list as []).reduce<CustomCard[]>((p, c) => {
            if (c.status == e) {
              return [
                ...p,
                {
                  id: c.id,
                  coworkerId: c.coworkerId,
                  coworkerFullName:
                    coworkerList?.find((i) => i.id == c.coworkerId)?.fullName ??
                    "",
                  coworkerImg:
                    coworkerList?.find((i) => i.id == c.coworkerId)?.avatar ??
                    "/avatar.jpg",
                  createdAt: c.createdAt,
                  storyPoints: c.budget,
                  title: c.fullName,
                  comment: c.comment,
                  callbackDate: c.callbackDate,
                  status: c.status,
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
  };

  const handleCardMove: OnDragEndNotification<Card> = async (
    _card,
    source,
    destination,
  ) => {
    if (destination?.toColumnId == "need_to_call_back") {
      setOpen(true);
      setSelectCard(_card);
      // @ts-ignore
      setMoveObject({ source, destination });
    } else if (
      destination?.toColumnId == "rejected" ||
      destination?.toColumnId == "accepted"
    ) {
      setOpenModalType("rejected_accepted");
      setSelectCard(_card);
      setOpen(true);
      // @ts-ignore
      setMoveObject({ source, destination });
    } else {
      await updateLeadById(_card?.id, {
        ..._card,
        status: destination?.toColumnId,
      });
      setKanbanBoard((currentBoard) => {
        return moveCard(currentBoard, source, destination);
      });
    }
  };

  const handleSave = async () => {
    if (openModalType == "rejected_accepted") {
      await updateLeadById(selectCard?.id, {
        ...selectCard,
        conversationComment: commentConver,
        status: moveObject?.destination?.toColumnId,
      });

      setKanbanBoard((currentBoard) => {
        return moveCard(
          currentBoard,
          moveObject.source,
          moveObject?.destination,
        );
      });
      handleClose();
    } else {
      await updateLeadById(selectCard?.id, {
        ...selectCard,
        callbackDate: callBackTime,
        status: moveObject?.destination?.toColumnId,
      });
      setKanbanBoard((currentBoard) => {
        return moveCard(
          currentBoard,
          moveObject.source,
          moveObject?.destination,
        );
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

  if (isUpdated) {
    return (
      <div className="loading">
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
    );
  }

  return (
    <div className="ads-list-content">
      <div className="ads-new">
        <button onClick={handleNavigateNew}>{t("addNewLead")}</button>
      </div>
      <div className="kanban-content">
        {kanbanBoard.columns.length > 0 && (
          <NotionStyles>
            <Typography variant="h4">Kanban</Typography>
            <Filters />
            {/* <UncontrolledBoard
              initialBoard={kanbanBoard}
              renderColumnHeader={renderColumnHeader}
              renderCard={renderCard}
              onCardDragEnd={(e) => console.log(e.title, "onCardDragEnd")}
            /> */}
            <ControlledBoard
              renderCard={(card) => (
                // @ts-ignore
                <RenderCard
                  isUpdated={isUpdated}
                  handleOpenModal={handleOpen}
                  {...card}
                />
              )}
              // @ts-ignore
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
                Keyingi qo'ng'iroq qilish vaqtini kiriting
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
          <div className="buttons">
            <button onClick={handleClose} className="cancel-btn">
              {t("cancel")}
            </button>
            <button onClick={handleSave}>{t("save")}</button>
          </div>
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
    font-family: "Roboto" !important;
  }
  & h1,
  h2,
  h3,
  h4,
  h5,
  h6 {
    font-family: "Roboto" !important;
  }
  & .react-kanban-column {
    padding: 0;
    background-color: transparent;
  }
`;
