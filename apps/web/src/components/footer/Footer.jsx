import { useState } from "react";
import { useTranslation } from "react-i18next";
import Button from "../../routes/aboutPageNew/components/Button";
import { style } from "../../util/styles";
import InstagramIcon from "../icons/InstagramIcon";
import TelegramIcon from "../icons/TelegramIcon";
import { apiClient } from "../../lib/apiClient";
import "./footer.scss";

// This footer contact form used to duplicate ContactUs.jsx's exact bug: a
// hardcoded Telegram bot token literal and chat id, POSTing straight to
// https://api.telegram.org/bot<TOKEN>/sendMessage from the browser (see
// docs/05-migration-plan.md Phase E). Same fix as ContactUs.jsx: relay
// through the server's public POST /api/contact instead — the token and
// chat id now live only in apps/api's config.
const Footer = () => {
  const { t } = useTranslation();
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    message: "",
  });
  const [isSending, setIsSending] = useState(false);

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
    <div className="footer">
      <div className="footer-list">
        <div
          id="contact_us"
          className={`${style.containerComponent} ${style.fB} !items-start gap-5 sm:!py-0 md:!py-0 lg:!py-0 py-0`}
        >
          <div
            className={`w-full sm:w-[47%] md:p-8 p-0 flex flex-row gap-20 ${style.fCol}`}
          >
            <div className="flex flex-col gap-3 text-[#051d42]">
              <a href="/home">{t("home")}</a>
              <a href="/home#about">{t("about")}</a>
              <a href="/home#features">{t("features")}</a>
              <a href="/home#pricing">{t("pricing")}</a>
              <a href="/home#services">{t("services")}</a>
              <a href="/home#questions">{t("questions")}</a>
            </div>
            <div className="flex flex-col gap-3 text-[#051d42]">
              <a href="/ads">{t("ads")}</a>
              <a href="/ads#top-ads">{t("topAds")}</a>
              <a href="/ads#new-ads">{t("newAds")}</a>
              <a href="/ads#expensive-ads">{t("expensiveAds")}</a>
              <a href="/ads#cheap-ads">{t("cheapAds")}</a>
            </div>
            <div className="flex flex-col gap-3 text-[#051d42]">
              <a href="/agents">{t("agents")}</a>
              <a href="/agents#top-agents">{t("topAgents")}</a>
            </div>
          </div>
          <div
            className={`w-full sm:w-[47%] md:p-8 p-0 ${style.fCol} items-end gap-3`}
          >
            <div className={`w-full sm:w-[100%] md:p-0 p-0`}>
              <h3 className={`${style.h3} mb-7`}>{t("contactUs")}</h3>
              <p className={`${style.p}`}>{t("contactUsText")}</p>
            </div>
            <input
              onChange={(e) =>
                setFormData({ ...formData, name: e.target.value })
              }
              value={formData.name}
              className="bg-bgInput sm:border-none border-2 text-[14px] md:text-[1.2rem] p-4 rounded-md w-full outline-none"
              type="text"
              placeholder={t("fullName")}
            />
            <input
              onChange={(e) =>
                setFormData({ ...formData, phone: e.target.value })
              }
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
      </div>
      <hr className="hr-line" />
      <div className="footer-copyright">
        <span>
          <p>&copy; Empire-soft - 2024</p>
        </span>
        <span className="social-icons-footer">
          <a href="/">
            <InstagramIcon width={25} fill="#051d42" />
          </a>
          <a href="/">
            <TelegramIcon width={25} fill="#051d42" />
          </a>
        </span>
      </div>
    </div>
  );
};

export default Footer;
