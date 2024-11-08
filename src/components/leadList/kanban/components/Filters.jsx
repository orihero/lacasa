import { TextField, styled } from "@mui/material";
// import SearchIcon from "@mui/icons-material/Search";

export const Filters = () => {
  return <div>1</div>;
};

const NoBorderSelect = styled(TextField)`
  & *:before {
    border-bottom: none !important;
  }
  & *:after {
    border-bottom: none !important;
  }
`;
