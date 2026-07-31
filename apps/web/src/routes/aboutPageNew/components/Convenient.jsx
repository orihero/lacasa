import React from "react";
import { style } from "../../../util/styles";
import { laptop } from "../../../assets";
import { useTranslation } from "react-i18next";

const Convenient = () => {
  const { i18n } = useTranslation();

  return (
    <div
      className={`${style.containerComponent} mb-28 sm:mb-24 sm:!py-16 md:!py-24 lg:!py-32 py-12 h-full`}
    >
      <div
        className={`w-full h-[300px] md:h-[450px] sm:h-[350px] lg:h-[606px] bg-blue ${style.fCol} rounded-[30px] relative items-center py-20`}
      >
        <h3 className={`${style.h3} !text-white mb-4`}>Easy and Convenient</h3>
        <hr className="max-w-[200px] bg-white md:h-2 h-1 md:w-full w-[100px] rounded-sm" />
        <div className="sm:w-[80%] absolute md:top-[190px] lg:top-[210px] top-[150px]">
          <img
            src={laptop}
            className={`w-[100%] h-[100%] object-cover`}
            alt=""
          />
          <iframe
            width="560"
            height="315"
            src={
              i18n.language === "uz"
                ? "https://www.youtube.com/embed/p1_9iIZshnU?si=ujE2VQ8W-oWJeQ3b"
                : "https://www.youtube.com/embed/jK8BTbzaFdw?si=9eZblcO4xoT2lmiM"
            }
            title="YouTube video player"
            frameborder="0"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            referrerpolicy="strict-origin-when-cross-origin"
            allowfullscreen
            style={{
              position: "absolute",
              top: "45%",
              left: "50%",
              width: "76%",
              height: "85%",
              transform: "translate(-50%, -50%)",
            }}
          ></iframe>
        </div>
      </div>
    </div>
  );
};

export default Convenient;
