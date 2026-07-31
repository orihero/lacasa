import { FC } from "react";
import { Box, Divider } from "@mui/material";

import { NewMenu } from "./Header";

export const Filters: FC = () => {
  return (
    <>
      <Box sx={{ display: "flex" }}>
        <Box sx={{ flexGrow: 1 }}>
          {/* <NormalCaseButton
            size="small"
            variant="text"
            startIcon={<AddIcon fontSize="small" />}
          >
            Add a view
          </NormalCaseButton> */}
        </Box>
        <Box>
          {/* <NormalCaseButton size='small' variant='text'>
            Properties
          </NormalCaseButton>
          <NormalCaseButton size='small' variant='text'>
            Project
          </NormalCaseButton>
          <NormalCaseButton size='small' variant='text'>
            Filter
          </NormalCaseButton>
          <NormalCaseButton size='small' variant='text'>
            Sort
          </NormalCaseButton>
          <NormalCaseButton size='small' variant='text' endIcon={<SearchIcon />}>
            Search
          </NormalCaseButton> */}
          {/* <IconButton>
            <MoreHorizIcon />
          </IconButton> */}
          <NewMenu />
        </Box>
      </Box>
      <Divider />
    </>
  );
};
