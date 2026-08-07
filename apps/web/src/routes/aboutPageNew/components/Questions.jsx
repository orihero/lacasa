import React from "react";
import { style } from "../../../util/styles";
import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Typography,
} from "@mui/material";
import AddCircleIcon from "@mui/icons-material/AddCircle";
import { questions } from "../../../util/constants";
import { useTranslation } from "react-i18next";
const Questions = () => {
  const [expanded, setExpanded] = React.useState(false);
  const { t } = useTranslation();

  const handleChange = (panel) => (event, isExpanded) => {
    setExpanded(isExpanded ? panel : false);
  };
  return (
    <div
      className={`${style.containerComponent} ${style.fCol} items-center  md:!py-30 xl:!py-40 py-20`}
    >
      <span className={`${style.span} text-center font-bold`}>We answered</span>
      <h2 className={`${style.h2} text-center sm:mb-14 md:mb-18 mb-10`}>
        {t("frequentlyAskedQuestions")}
      </h2>

      <div className="sm:w-[95%] w-full">
        {questions?.length &&
          questions?.map((item, index) => (
            <Accordion
              key={item.id}
              expanded={expanded === `panel${index + 1}`}
              onChange={handleChange(`panel${index + 1}`)}
              className="!shadow-none border-b-2 rounded-none py-2"
            >
              <AccordionSummary
                expandIcon={<AddCircleIcon sx={{ color: "#fece51" }} />}
                aria-controls={`panel${index + 1}bh-content`}
                id={`panel${index + 1}bh-header`}
              >
                <Typography
                  sx={{ width: "90%", flexShrink: 0, fontSize: "1.2rem" }}
                >
                  {t(item.title)}
                </Typography>
              </AccordionSummary>
              <AccordionDetails sx={{ width: "80%" }}>
                <Typography className="text-lg" sx={{ fontSize: "1rem" }}>
                  {t(item.subtitle)}
                </Typography>
              </AccordionDetails>
            </Accordion>
          ))}
      </div>
    </div>
  );
};

export default Questions;
