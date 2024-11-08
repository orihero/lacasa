import React from "react";

const StatusCell = ({ value }) => {
  let backgroundColor, color;

  switch (value) {
    case "new":
      backgroundColor = "#007BFF";
      color = "#FFFFFF";
      break;
    case "could_not_connect":
      backgroundColor = "#DC3545";
      color = "#FFFFFF";
      break;
    case "need_to_call_back":
      backgroundColor = "#FFC107";
      color = "#FFFFFF";
      break;
    case "pick_date":
      backgroundColor = "#E0E0E0";
      color = "#000000";
      break;
    case "rejected":
      backgroundColor = "#6C757D";
      color = "#FFFFFF";
      break;
    case "accepted":
      backgroundColor = "#28A745";
      color = "#FFFFFF";
      break;
    default:
      backgroundColor = "#FFFFFF";
      color = "#000000";
  }

  return (
    <span
      style={{
        backgroundColor,
        color,
        padding: "4px 8px",
        borderRadius: "4px",
        display: "inline-block",
        fontWeight: "bold",
        textTransform: "capitalize",
        fontSize: "10px",
      }}
    >
      {value}
    </span>
  );
};

export default StatusCell;
