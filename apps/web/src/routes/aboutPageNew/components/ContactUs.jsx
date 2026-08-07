import { useState } from "react";
import { style } from "../../../util/styles";
import Button from "./Button";
import { useTranslation } from "react-i18next";
import { apiClient } from "../../../lib/apiClient";

// Used to POST directly to https://api.telegram.org/bot<TOKEN>/sendMessage
// with a hardcoded bot token literal committed in this file — the worst of
// the browser-side Telegram leaks (docs/05-migration-plan.md Phase E). The
// form now hits the server's public POST /api/contact (apps/api/src/routes/
// contact.js), which relays to the office Telegram channel using its own
// server-held TG_BOT_TOKEN/TG_CONTACT_CHAT_ID — neither ever reaches the
// browser. Client-side required/phone-format checks are kept as an
// early UX guard; the server re-validates independently (it has to, since
// this route is public and unauthenticated).
const ContactUs = () => {
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    message: "",
  });
  const [isSending, setIsSending] = useState(false);
  const { t } = useTranslation();

  const handleSubmit = async () => {
    if (isSending) return;

    if (!formData.name || !formData.phone) {
      alert(t("requiredFields"));
      return;
    }
    if (!formData.phone.match(/^\+998\d{9}$/)) {
      alert(t("invalidPhone"));
      return;
    }

    setIsSending(true);
    try {
      await apiClient.contact.submit({
        name: formData.name,
        phone: formData.phone,
        message: formData.message,
      });
      alert(t("messageSent"));
      setFormData({
        name: "",
        phone: "",
        message: "",
      });
    } catch (error) {
      console.error("Failed to send contact message:", error);
      // A failed send must be visible, not silently swallowed — surface a
      // specific message for rate limiting (POST /api/contact is 5/min per
      // IP) and a generic one for everything else (validation, the server's
      // TG_BOT_TOKEN being unconfigured, Telegram rejecting the relay).
      if (error?.response?.status === 429) {
        alert(t("messageRateLimited"));
      } else {
        alert(t("messageSendFailed"));
      }
    } finally {
      setIsSending(false);
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
