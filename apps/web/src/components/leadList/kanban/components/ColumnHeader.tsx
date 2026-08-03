import { ControlledBoardProps } from "@caldwell619/react-kanban";
import { Box, Typography } from "@mui/material";

import { CustomCard } from "../data";
import { ColoredBgText } from "./Card";
import StatusCell from "../../../status/StatusCell";

// Wired into LeadKanbanList.tsx's <ControlledBoard>, so this must match
// ControlledBoardProps's single-argument `renderColumnHeader` signature —
// not UncontrolledBoardProps's two-argument one (which also passes a
// `ColumnHeaderBag` this component never used).
export const renderColumnHeader: ControlledBoardProps<CustomCard>["renderColumnHeader"] =
  (column) => {
    // navigate("/profile/" + id + "/create/leads");
    // const newCard = createNewCard();
    // Can be async, do mutation here awaiting result, then call `addCard`
    // addCard(newCard, { on: "top" });
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
