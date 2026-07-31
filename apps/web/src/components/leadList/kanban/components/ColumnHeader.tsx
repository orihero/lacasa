import React from "react";
import { UncontrolledBoardProps } from "@caldwell619/react-kanban";
import { Box, IconButton, Typography } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import MoreHorizIcon from "@mui/icons-material/MoreHoriz";
import randomRgba from "random-rgba";

import { createNewCard, CustomCard } from "../data";
import { ColoredBgText } from "./Card";
import StatusCell from "../../../status/StatusCell";
import { useNavigate, useParams } from "react-router-dom";

export const renderColumnHeader: UncontrolledBoardProps<CustomCard>["renderColumnHeader"] =
  (column) => {
    const navigate = useNavigate();
    const { id } = useParams();
    const onAddCard = () => {
      // navigate("/profile/" + id + "/create/leads");
      // const newCard = createNewCard();
      // Can be async, do mutation here awaiting result, then call `addCard`
      // addCard(newCard, { on: "top" });
    };
    return (
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          margin: "5px",
          border: "1px solid #dddd",
          padding: "5px",
          borderRadius: "5px",
          minWidth: "300px",
          maxWidth: "300px",
          width: "300px",
        }}
      >
        <Box sx={{ flexGrow: 1, display: "flex", gap: "10px" }}>
          <ColoredBgText>
            <StatusCell value={column.id} />
          </ColoredBgText>
          <Typography>{column.cards.length}</Typography>
        </Box>
        <Box sx={{ display: "flex" }}>
          {/* <IconButton>
            <MoreHorizIcon />
          </IconButton> */}
          {/* <IconButton onClick={onAddCard}>
            <AddIcon />
          </IconButton> */}
        </Box>
      </Box>
    );
  };
