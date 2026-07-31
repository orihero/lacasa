import React, { useRef, useState } from "react";
import { style } from "../../../util/styles";
import { services } from "../../../util/constants";
import { useTranslation } from "react-i18next";

const Services = () => {
  const { t } = useTranslation();
  const cardRef = useRef(null);
  const containerRef = useRef(null);
  const [width, setWidth] = useState(0);

  const selectChoose = (id) => {
    if (cardRef.current) {
      setWidth(id * cardRef.current.offsetWidth);
    }
  };

  const disableTouch = (e) => {
    e.preventDefault();
  };

  return (
    <div
      className={`${style.containerComponent} ${style.fCol} items-center`}
      ref={containerRef}
    >
      {/* <span className={`${style.span} font-bold`}>We are the best</span> */}
      <h2 className={`${style.h2} sm:mb-14 md:mb-18 mb-10`}>
        {t("whyChoose")}
      </h2>
      <ul
        style={{
          scrollbarWidth: "none",
          msOverflowStyle: "none",
        }}
        className={`w-full rounded-xl border-[3px] border-[#051d42] bg-white grid grid-flow-col auto-cols-[100%] justify-between overflow-x-hidden mb-7`} // `overflow-x-hidden` bilan scrollni yashiramiz
        onTouchStart={disableTouch}
        onTouchMove={disableTouch}
        onTouchEnd={disableTouch}
      >
        {services.map((i, idx) => {
          return (
            <li
              key={idx}
              ref={cardRef}
              style={{ transform: `translateX(-${width}px)` }}
              className={`${style.fCol} transition-transform duration-500 p-5 sm:p-10 md:p-20 w-full items-center`}
            >
              <img
                src={i.img}
                className={`mb-7 max-w-[147px] w-[80px] sm:w-[100px] md:w-full`}
                alt=""
              />
              <p
                className={`${style.p} text-center !text-[#fece51] !font-bold mb-4`}
              >
                {t(i.title)}
              </p>
              <span className={`${style.span} text-center max-w-[650px]`}>
                {t(i.info)}
              </span>
            </li>
          );
        })}
      </ul>
      <div className={`${style.f} gap-4`}>
        {services.map((i, index) => {
          return (
            <button
              key={index}
              onClick={() => selectChoose(index)}
              disabled={width == index * cardRef.current?.offsetWidth}
              className={`w-[40px] h-[40px] rounded-full border-2 ${
                width == index * cardRef.current?.offsetWidth
                  ? "bg-[#051d42]"
                  : "bg-white"
              } border-[#051d42]`}
            ></button>
          );
        })}
      </div>
    </div>
  );
};

export default Services;
