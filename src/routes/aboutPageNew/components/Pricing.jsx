import React, { useState } from "react";
import { style } from "../../../util/styles";
import { pricing } from "../../../util/constants";
import { galchka, galchkaWhite } from "../../../assets";
import Button from "./Button";
import { useTranslation } from "react-i18next";

const Pricing = () => {
  const [hover, setHover] = useState(null);
  const { t } = useTranslation();
  return (
    <div
      id="pricing"
      className={`${style.containerComponent} ${style.fCol} items-center sm:!py-16 md:!py-0 lg:!py-32 py-0`}
    >
      <h3 className={`${style.h3} mb-4`}>{t("pricingTitle")}</h3>
      <span className={`${style.span} max-w-[550px] text-center mb-16`}>
        {t("pricingSubtitle")}
      </span>
      <ul className={`${style.fA} gap-6`}>
        {pricing.map((i, idx) => {
          return (
            <li
              key={idx}
              onMouseOver={() => setHover(i.id)}
              onMouseOut={() => setHover(null)}
              className={`${style.fCol} ${
                hover === i.id ? "bg-blue scale-110" : "bg-white"
              } gap-5 items-start transition duration-150 cursor-pointer border-[3px] rounded-xl  p-4 sm:p-6 md:p-8 lg:p-10 border-blue  max-w-[450px] flex flex-col justify-between`}
            >
              <div className="flex flex-col gap-2">
                <p
                  className={`${style.p} ${
                    hover === i.id ? "!text-white" : "!text-priceBlack"
                  } !font-[500]`}
                >
                  {t(i.title)}
                </p>
                <h3
                  className={`${style.h3} ${
                    hover === i.id ? "!text-white" : "!text-priceBlack"
                  }`}
                >
                  {t(i.price)}
                </h3>
                <span
                  className={`${style.span} ${
                    hover === i.id ? "!text-white" : "!text-priceBlack"
                  } w-[300px]`}
                >
                  {t(i.info)}
                </span>
                <ul className={`${style.fCol} gap-2`}>
                  {i.completeds.map((item, index) => {
                    return (
                      <li
                        key={index}
                        className={`${style.f} flex-nowrap gap-3 max-w-[300px]`}
                      >
                        <img
                          src={hover === i.id ? galchkaWhite : galchka}
                          alt=""
                        />
                        <span
                          className={`${style.span} !text-[15px] ${
                            hover === i.id ? "!text-white" : ""
                          }`}
                        >
                          {t(item)}
                        </span>
                      </li>
                    );
                  })}
                </ul>
              </div>
              <Button
                title={t("pricingBtn")}
                btnClass={`!bg-white border-2 border-blue !text-blue`}
              />
            </li>
          );
        })}
      </ul>
    </div>
  );
};

export default Pricing;
