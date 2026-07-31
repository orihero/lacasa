import React, { useEffect } from "react";
import { UncontrolledBoardProps } from "@caldwell619/react-kanban";
import {
  Grid2 as Grid,
  Card,
  CardContent,
  styled,
  Typography,
  Box,
} from "@mui/material";
import shouldForwardProp from "@emotion/is-prop-valid";

import { CustomCard, ticketTypeToBgColor } from "../data";
import {
  formatCallbackDate,
  formatCreatedAt,
} from "../../../../hooks/formatDate";

export const RenderCard: UncontrolledBoardProps<CustomCard>["renderCard"] = (
  card,
) => {
  useEffect(() => {
    //
  }, [card.isUpdate]);

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
  bgColor: string;
}>`
  background-color: ${({ bgColor }) => bgColor};
  border-radius: 4px;
  /* padding: 0 8px 1px 8px; */
`;
