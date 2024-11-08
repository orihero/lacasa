import { KanbanBoard, UncontrolledBoard } from "@caldwell619/react-kanban";
import { styled, Typography } from "@mui/material";
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate, useParams } from "react-router-dom";
import { useLeadStore } from "../../lib/useLeadStore";
import { Filters, renderCard, renderColumnHeader } from "./kanban/components";
import { board, CustomCard } from "./kanban/data";

export default function LeadKanbanList() {
  const navigate = useNavigate();
  const { t } = useTranslation();
  const { id } = useParams();
  const { isLoading, list, fetchLeadList } = useLeadStore();
  const [kanbanBoard, setKanbanBoard] = useState({ columns: [] });

  const handleNavigateNew = () => {
    navigate("/profile/" + id + "/create/leads");
  };

  const generateBoard = async () => {
    let board: KanbanBoard<CustomCard> = {
      columns: [
        "new",
        "could_not_connect",
        "need_to_call_back",
        "pick_date",
        "rejected",
        "accepted",
      ].map(e => {
        return {
          id: e,
          title: t(e),
          cards: (list as []).reduce<CustomCard[]>((p, c) => {
            if (c.status === e) {
              return [...p, { id: c.id, assigneeId: c.workerId, createdAt: new Date(c.createdAt), storyPoints: c.budget, title: c.fullName, }]
            }
          }, []) || []
        }
      })
    };
    setKanbanBoard(board)
  };

  useEffect(() => {
    fetchLeadList(id);
  }, [])

  useEffect(() => {
    if (!isLoading && list.length > 0)
      generateBoard();
  }, [list]);

  console.log('====================================');
  console.log({ kanbanBoard });
  console.log('====================================');

  return (
    <div className="ads-list-content">
      <div className="ads-new">
        <button onClick={handleNavigateNew}>{t("addNewLead")}</button>
      </div>
      {kanbanBoard.columns.length > 0 && <NotionStyles>
        <Typography variant="h4">Kanban</Typography>
        <Filters />
        <UncontrolledBoard
          initialBoard={kanbanBoard}
          renderColumnHeader={renderColumnHeader}
          renderCard={renderCard}
        />
      </NotionStyles>}
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
