import React from "react";
import { useTranslation } from "react-i18next";

const StatusAds = ({ value }) => {
  let backgroundColor, color;
  const { t } = useTranslation();

  switch (value) {
    case "1":
      backgroundColor = "#ff4d4d";
      color = "#FFFFFF";
      break;
    case "2":
      backgroundColor = "#4caf50";
      color = "#FFFFFF";
      break;
    case "3":
      backgroundColor = "#FFC107";
      color = "#FFFFFF";
      break;
    default:
      backgroundColor = "#ff9800";
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
      {value == "1" ? t("active") : value == "2" ? t("sold") : t("draft")}
    </span>
  );
};

export default StatusAds;
