import React from "react";

const Button = ({ title, btnClass, onClick }) => {
  return (
    <button
      onClick={onClick}
      className={`border-2 active:bg-[#051d42]  active:text-white sm:text-[1rem] text-[14px] transition sm:font-[600] font-[400] sm:px-[20.51px] px-[1rem] sm:py-[13.68px] py-[9px] rounded-lg bg-[#051d42] hover:bg-white hover:text-[#051d42] text-white hover:border-[#051d42] ${btnClass}`}
    >
      {title}
    </button>
  );
};

export default Button;
