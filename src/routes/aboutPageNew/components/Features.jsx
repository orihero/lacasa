import React, { useState } from "react";
import { features } from "../../../util/constants";
import { style } from "../../../util/styles";
import { useTranslation } from "react-i18next";
const Features = () => {
  const [hover, setHover] = useState(null);
  const { t } = useTranslation();

  return (
    <div
      id="features"
      className={`${style.containerComponent} ${style.fCol} items-center`}
    >
      <span className={`${style.span} font-bold`}>{t("featuresSubtitle")}</span>
      <h2 className={`${style.h2} sm:mb-14 md:mb-18 mb-10 text-[#051d42]`}>
        {t("featuresTitle")}{" "}
        <span className="!text-[#fece51]">{t("featuresServices")}</span>
      </h2>
      <ul className={`${style.fA} gap-7 w-full`}>
        {features.map((i, idx) => {
          return (
            <li
              onMouseOver={() => setHover(i.id)}
              onMouseOut={() => setHover(null)}
              key={idx}
              // style={{ height: "620px" }}
              className={`${style.fCol} ${
                hover === i.id ? "bg-blue" : "bg-white"
              } items-start border-img lg:p-10 p-5 cursor-pointer rounded-[40px] max-w-[380px] md:w-[45%] lg:w-full transition duration-150`}
            >
              <div
                className={`${style.fCol} items-center justify-center rounded-xl bg-white p-1 max-w-[90px]  md:mb-4 sm:mb-2 mb-1 sm:w-[70px] lg:w-full w-[50px] max-h-[90px] sm:h-[70px] lg:h-full h-[50px]`}
              >
                <img
                  className="max-w-[80px] sm:w-[60px] lg:w-full w-[40px] h-[40px] sm:h-[60px] lg:h-full"
                  src={i.img}
                  alt=""
                />
              </div>
              {/* border-b-2 mb-3  */}
              <p
                className={`${style.p} ${
                  hover === i.id ? "!text-white" : "!text-[#fece51]"
                } md:mb-7 transition duration-150 mb-2 uppercase font-bold`}
              >
                {t(i.title)}
              </p>
              <span
                className={`${style.span} ${
                  hover === i.id ? "!text-white" : ""
                } lg:mb-16 md:mb-10 mb-5 transition duration-150`}
              >
                {t(i.info)}
              </span>
              {/* <button
                className={`${style.span} !text-blue ${
                  hover === i.id ? "!text-white" : ""
                } transition duration-150`}
              >
                {t("learnMore")}
              </button> */}
            </li>
          );
        })}
      </ul>
    </div>
  );
};

export default Features;
