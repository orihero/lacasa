import { Box, IconButton, Typography } from "@mui/material";
// import CloseIcon from "@mui/icons-material/Close";

export const renderColumnHeader = ({ title, cards }, { removeColumn }) => {
  return (
    <Box
      sx={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        backgroundColor: "red",
      }}
    >
      <Typography variant="subtitle2">
        {title} {cards.length}
      </Typography>
      <IconButton onClick={removeColumn}>{/* <CloseIcon /> */}x</IconButton>
    </Box>
  );
};
