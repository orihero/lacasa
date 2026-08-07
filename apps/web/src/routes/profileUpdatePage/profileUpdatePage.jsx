import { Avatar } from "@files-ui/react";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { assetUpload } from "../../lib/assetUpload";
import { api } from "../../lib/api";
import { useUserStore } from "../../lib/userStore";
import "./profileUpdatePage.scss";
import { useTranslation } from "react-i18next";

function ProfileUpdatePage() {
  const [profimeImage, setProfimeImage] = useState("/avatar.jpg");
  const { t } = useTranslation();
  const { fetchUserInfo } = useUserStore();

  const navigate = useNavigate();

  const onUpdateProfile = async (e) => {
    e.preventDefault();
    const updater = async () => {
      let r = null;
      if (profimeImage !== "/avatar.jpg") {
        r = await assetUpload(profimeImage, "avatars");
      }

      const formData = new FormData(e.target);
      let data = Object.fromEntries(formData);
      if (r) {
        data = { ...data, avatar: r };
      }
      await api.patch("/users/me", data);
      await fetchUserInfo();
    };
    toast.promise(updater, {
      error: "Something went wrong!",
      pending: "Uploading",
      success: "Successfully updated",
    });
    navigate("/profile");
  };

  return (
    <div className="profileUpdatePage">
      <div className="formContainer">
        <form className="form-update" onSubmit={onUpdateProfile}>
          <div>
            <Avatar
              src={profimeImage}
              onError={() => setProfimeImage("/avatar.jpg")}
              onChange={(imgSource) => setProfimeImage(imgSource)}
              accept=".jpg, .png, .gif, .bmp, .webp"
              alt="Avatar"
            />
          </div>
          <div className="inputs">
            <h1>{t("updateProfile")}</h1>
            <div className="item">
              <label htmlFor="fullName">{t("fullName")}</label>
              <input required id="fullName" name="fullName" type="text" />
            </div>
            <div className="item">
              <label htmlFor="phoneNumber">{t("phone")}</label>
              <input required id="phoneNumber" name="phoneNumber" type="tel" />
            </div>
            <div className="item">
              <label htmlFor="email">{t("email")}</label>
              <input required id="email" name="email" type="email" />
            </div>
            <div className="item">
              <label htmlFor="password">{t("password")}</label>
              <input required id="password" name="password" type="password" />
            </div>
            <button>{t("update")}</button>
          </div>
        </form>
      </div>
      <div className="sideContainer">
        <img src="" alt="" className="avatar" />
      </div>
    </div>
  );
}

export default ProfileUpdatePage;
