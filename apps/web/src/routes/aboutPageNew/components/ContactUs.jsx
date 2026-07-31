import React, { useState } from "react";
import { style } from "../../../util/styles";
import Button from "./Button";
import { useTranslation } from "react-i18next";
import axios from "axios";

const ContactUs = () => {
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    message: "",
  });
  const { t } = useTranslation();

  const handleSubmit = async () => {
    if (!formData.name || !formData.phone) {
      console.log("Majburiy maydonlar to'ldirilmagan");
      alert(t("requiredFields"));
    } else if (!formData.phone.match(/^\+998\d{9}$/)) {
      console.log("Telefon raqami noto'g'ri formatda");
      alert(t("invalidPhone"));
    } else {
      const message = `
      Name: ${formData.name}
      Phone: ${formData.phone}
      Message: ${formData.message}
      `;
      const formDataTelegram = new FormData();
      formDataTelegram.append("chat_id", "-1002366623212");
      formDataTelegram.append("text", message);
      formDataTelegram.append("parse_mode", "Markdown");
      const token = "7558469078:AAFkpNkDzySQM79gJLBOyCTeidl1Y8uwY6Q"; // Your Bot Token

      try {
        const response = await axios.post(
          `https://api.telegram.org/bot${token}/sendMessage`,
          formDataTelegram,
        );
        console.log("Message sent successfully:", response.data);
        alert(t("messageSent"));
      } catch (error) {
        console.error("Xatolik yuz berdi:", error);
        return null;
      }

      const newEntry = {
        name: formData.name,
        phone: formData.phone,
        message: formData.message,
      };
      console.log("Ma'lumotlar yuborildi:", newEntry);
      setFormData({
        name: "",
        phone: "",
        message: "",
      });
    }
  };

  return (
    <div
      id="contact_us"
      className={`${style.containerComponent} ${style.fB} !items-start gap-5 sm:!py-16 md:!py-24 lg:!py-32 py-12`}
    >
      <div className={`w-full sm:w-[47%] md:p-8 p-0`}>
        <h3 className={`${style.h3} mb-7`}>{t("contactUs")}</h3>
        <p className={`${style.p}`}>{t("contactUsText")}</p>
      </div>
      <div
        className={`w-full sm:w-[47%] md:p-8 p-0 ${style.fCol} items-end gap-3`}
      >
        <input
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          value={formData.name}
          className="bg-bgInput sm:border-none border-2 text-[14px] md:text-[1.2rem] p-4 rounded-md w-full outline-none"
          type="text"
          placeholder={t("fullName")}
        />
        <input
          onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
          value={formData.phone}
          className="bg-bgInput sm:border-none border-2 text-[14px] md:text-[1.2rem] p-4 rounded-md w-full outline-none"
          type="text"
          placeholder={t("phone")}
        />
        <textarea
          onChange={(e) =>
            setFormData({ ...formData, message: e.target.value })
          }
          value={formData.message}
          className="bg-bgInput sm:border-none border-2 text-[14px] md:text-[1.2rem] resize-none p-4 h-[200px] rounded-md w-full outline-none"
          maxLength="200"
          placeholder={t("message")}
        />

        <Button
          onClick={handleSubmit}
          title={t("sendMassage")}
          btnClass={`submit-btn`}
        />
      </div>
    </div>
  );
};

export default ContactUs;
