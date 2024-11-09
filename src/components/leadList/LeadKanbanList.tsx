import { KanbanBoard, UncontrolledBoard } from "@caldwell619/react-kanban";
import { styled, Typography } from "@mui/material";
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { useLeadStore } from "../../lib/useLeadStore";
import { Filters, renderCard, renderColumnHeader } from "./kanban/components";
import { board, CustomCard } from "./kanban/data";
import { useUserStore } from "../../lib/userStore";
import "./leadList.scss";
import { useCoworkerStore } from "../../lib/useCoworkerStore";

export default function LeadKanbanList() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { id } = useParams();
  const { isLoading, list, fetchLeadList } = useLeadStore();
  const { list: coworkerList, fetchCoworkerList } = useCoworkerStore();
  const [kanbanBoard, setKanbanBoard] = useState({ columns: [] });
  const { currentUser } = useUserStore();

  useEffect(() => {
    if (currentUser.role == "agent") {
      fetchLeadList(id);
      fetchCoworkerList(id);
    } else if (currentUser.role == "coworker") {
      fetchLeadList(currentUser.agentId);
      fetchCoworkerList(currentUser.agentId);
    }
  }, [currentUser?.agentId, id]);

  useEffect(() => {
    if (!isLoading && list.length > 0 && coworkerList?.length) generateBoard();
  }, [list?.length, coworkerList.length]);

  const handleNavigateNew = () => {
    navigate("/profile/" + id + "/create/leads");
  };

  console.log(coworkerList);

  const generateBoard = async () => {
    console.log("render");
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
              console.log({ c });
              return [
                ...p,
                {
                  id: c.id,
                  coworkerId: c.coworkerId,
                  coworkerFullName: coworkerList?.find(
                    (i) => i.id == c.coworkerId,
                  )?.fullName,
                  coworkerImg: coworkerList?.find((i) => i.id == c.coworkerId)
                    ?.avatar,
                  createdAt: c.createdAt,
                  storyPoints: c.budget,
                  title: c.fullName,
                  comment: c.comment,
                  callbackDate: c.callbackDate,
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

  console.log("====================================");
  console.log({ kanbanBoard });
  console.log("====================================");

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
            <UncontrolledBoard
              initialBoard={kanbanBoard}
              renderColumnHeader={renderColumnHeader}
              renderCard={renderCard}
              onCardNew={() => alert("Kanban new card")}
            />
          </NotionStyles>
        )}
      </div>
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
