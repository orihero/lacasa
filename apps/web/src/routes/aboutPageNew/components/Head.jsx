import React from "react";
import { style } from "../../../util/styles";
import Button from "./Button";
import { BtnPlay, HeadImg, HeadImg2 } from "../../../assets";
import { useTranslation } from "react-i18next";

const Head = () => {
  let sum = [1, 2, 3, 4, 5];
  const { t } = useTranslation();

  return (
    <div
      id="home"
      className={`${style.fB} ${style.containerComponent} lg:!pt-[20px] md:!pt-[100px] !pt-[70px] gap-4`}
    >
      <div className={`${style.fCol} xl:w-[50%] w-full gap-5`}>
        <h1 className={`${style.h1}`}>
          {t("headline.title")}
          <span className="text-yellow-400">{t("headline.titleSpan")}</span>
        </h1>
        <p className={`${style.p}`}>{t("headline.subtitle")}</p>
        <div className={`${style.f} sm:gap-5 gap-2`}>
          <Button title={t("headline.btn")} btnClass={``} />
          <button
            className={`${style.f} sm:text-[1rem] text-[14px] sm:gap-3 gap-1 transition hover:scale-110 text-yellow-400 font-[500]`}
          >
            <img className="sm:w-[46px] w-[35px] " src={BtnPlay} alt="" />
            <span>{t("headline.watchDemo")}</span>
          </button>
        </div>
      </div>
      <div
        className={`xl:w-[45%] w-full ${style.f} xl:justify-end flex-col justify-center items-center relative`}
      >
        <img
          className="xl:w-[85%] md:w-[70%] sm:h-[300px] xl:h-auto w-full z-10 object-cover"
          src={HeadImg}
          alt=""
        />
        <div className={`${style.fCol} absolute left-0 bottom-20 z-0`}>
          {sum.map((item, idx) => {
            return (
              <img key={idx} className="w-72 mb-3" src={HeadImg2} alt="" />
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default Head;
