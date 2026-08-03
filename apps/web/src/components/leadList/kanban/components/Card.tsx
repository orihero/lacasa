import { useEffect } from "react";
import {
  Grid2 as Grid,
  Card,
  CardContent,
  styled,
  Typography,
  Box,
} from "@mui/material";
import shouldForwardProp from "@emotion/is-prop-valid";

import { CustomCard } from "../data";
import {
  formatCallbackDate,
  formatCreatedAt,
} from "../../../../hooks/formatDate";

// Rendered as a plain JSX component (`<RenderCard isUpdated={...}
// handleOpenModal={...} {...card} />` in LeadKanbanList.tsx), not invoked
// through react-kanban's `renderCard(card, options)` callback signature —
// so its props are the board card's own fields plus the two extras merged
// in via spread, not `UncontrolledBoardProps<CustomCard>["renderCard"]`'s
// `(card, options)` shape.
export interface RenderCardProps extends CustomCard {
  isUpdated: boolean;
  handleOpenModal: (card: CustomCard) => void;
}

export const RenderCard = (card: RenderCardProps) => {
  useEffect(() => {
    //
  }, [card.isUpdated]);

  console.log(card);
  return (
    <Card
      sx={{
        width: "300px",
        margin: "5px",

        // boxShadow: "none",
        // border: "1px solid #ddd",
        cursor: "pointer",
      }}
      onClick={() => card.handleOpenModal(card)}
    >
      <CardContent component={(p) => <Grid {...p} container spacing={1} />}>
        <Grid>
          <Typography sx={{ fontWeight: "bold" }}>{card.title}</Typography>
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Typography sx={{ fontWeight: "bold" }}>
            {card.storyPoints}
            {card.ticketType}
          </Typography>
        </Grid>
        <Grid size={{ xs: 12 }}>
          <Typography sx={{ fontWeight: "500" }}>{card.comment}</Typography>
        </Grid>
        {card.status == "need_to_call_back" && card?.callbackDate && (
          <Typography
            bgcolor={"red"}
            padding={"3px"}
            borderRadius={1}
            fontSize={14}
            color="#fff"
          >
            {formatCallbackDate(card?.callbackDate)}
          </Typography>
        )}
        {(card.status == "rejected" || card.status == "accepted") &&
          card?.conversationComment && (
            <Typography
              bgcolor={"red"}
              padding={"3px"}
              borderRadius={1}
              fontSize={14}
              color="#fff"
            >
              {card.conversationComment}
            </Typography>
          )}
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            width: "100%",
            alignItems: "center",
          }}
        >
          <Typography color="#888" fontSize={12}>
            {formatCreatedAt(card?.createdAt)}
          </Typography>

          <Box sx={{ display: "flex", gap: "5px" }}>
            <Typography>{card?.coworkerFullName}</Typography>
            <img
              style={{
                width: "30px",
                height: "30px",
                borderRadius: "50%",
                objectFit: "cover",
              }}
              src={card.coworkerImg ?? "/avatar.jpg"}
              alt=""
            />
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
};

export const ColoredBgText = styled("span", { shouldForwardProp })<{
  // Optional: ColumnHeader.tsx's only caller renders it with no bgColor
  // today (a pre-existing gap — see report), which already produced an
  // invalid `background-color: undefined` declaration the browser ignores.
  bgColor?: string;
}>`
  background-color: ${({ bgColor }) => bgColor};
  border-radius: 4px;
  /* padding: 0 8px 1px 8px; */
`;
