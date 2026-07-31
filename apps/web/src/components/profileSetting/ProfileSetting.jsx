import { Avatar } from "@files-ui/react";
import { phoneValidationRule } from "@lacasa/domain";
import FormControlLabel from "@mui/material/FormControlLabel";
import FormGroup from "@mui/material/FormGroup";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { useUserStore } from "../../lib/userStore";
import { IOSSwitch } from "../SwitchStyle";
import IgProfileCard from "../igProfileCard/IgProfileCard";
import TgProfileCard from "../tgProfileCard/TgProfileCard";
import "./profileSetting.scss";
import { Triangle } from "react-loader-spinner";
import { api } from "../../lib/api";
import { toast } from "react-toastify";
import { assetUpload } from "../../lib/assetUpload";
import YtProfileCard from "../ytProfileCard/YtProfileCard";
import { Button, Typography } from "@mui/material";
import { YTService } from "../../services/yt";
import {
  getInstagramConnectUrl,
  disconnectInstagram,
} from "../../services/crosspost";
const ProfileSetting = () => {
  const { t } = useTranslation();
  const { currentUser, fetchUserInfo } = useUserStore();
  const [profimeImage, setProfimeImage] = useState();
  const [isEditing, setIsEditing] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm({
    defaultValues: {
      avatar: currentUser?.avatar,
      fullName: currentUser?.fullName,
      phone: currentUser?.phoneNumber,
      email: currentUser?.email,
      password: currentUser?.password,
    },
  });

  useEffect(() => {
    if (currentUser?.id) {
      setProfimeImage(currentUser?.avatar ?? "/avatar.jpg");
    }
  }, [currentUser?.id, currentUser?.avatar]);

  // The Instagram OAuth callback redirects back here with ?ig=connected|error.
  useEffect(() => {
    const ig = new URLSearchParams(window.location.search).get("ig");
    if (!ig) return;
    if (ig === "connected") {
      toast.success("Instagram account connected!");
      fetchUserInfo();
    } else {
      toast.error("Instagram connection failed — please try again.");
    }
    window.history.replaceState({}, "", window.location.pathname);
  }, [fetchUserInfo]);

  const handleIgConnect = async () => {
    try {
      const url = await getInstagramConnectUrl();
      window.open(url, "_blank", "noopener");
    } catch (error) {
      toast.error(
        error?.response?.data?.error?.message ??
          "Instagram connect is not configured yet",
      );
    }
  };

  const handleIgDisconnect = async (igUserId) => {
    try {
      await disconnectInstagram(igUserId);
      toast.success("Instagram account disconnected");
      await fetchUserInfo();
    } catch (error) {
      toast.error("Failed to disconnect the Instagram account");
    }
  };

  const togglePasswordVisibility = () => {
    setShowPassword((prevShowPassword) => !prevShowPassword);
  };

  const onSubmit = async (data) => {
    setLoading(true);

    try {
      let updatedAvatar = currentUser?.avatar;

      if (
        profimeImage !== "/avatar.jpg" &&
        profimeImage !== currentUser?.avatar
      ) {
        updatedAvatar = await assetUpload(profimeImage, "avatars");
      }

      await api.patch("/users/me", {
        fullName: data.fullName,
        phoneNumber: data.phone,
        email: data.email,
        password: data.password,
        avatar: updatedAvatar,
      });

      toast.success("Profile successfully updated!");
      await fetchUserInfo();

      setLoading(false);
      setIsEditing(false);
    } catch (error) {
      console.error("Error updating profile:", error);
      toast.error("Error updating profile: " + error.message);

      setLoading(false);
    }
  };

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    setIsEditing(false);
  };

  const initializeYouTube = async () => {
    const accessToken = await YTService.init();
    console.log("Initializing YouTube API...", accessToken);
    if (accessToken) {
      console.log("YouTube API initialized. Access Token:", accessToken);
      const accountInfo = await YTService.getChannelInfo();
      console.log(accountInfo);
    } else {
      alert("Failed to initialize YouTube API.");
    }
  };

  const signOut = async () => {
    await YTService.signOut();
  };

  if (loading) {
    return (
      <div className="loading">
        <Triangle
          visible={true}
          height="80"
          width="80"
          color="#4fa94d"
          ariaLabel="triangle-loading"
          wrapperStyle={{}}
          wrapperClass=""
        />
      </div>
    );
  }

  return (
    <div className="profile-setting">
      <div className="profile-header">
        <Typography variant="h5">{t("profileSettings")}</Typography>
      </div>
      <div className="profile-container">
        <div className="left">
          <div className="avatar">
            <Avatar
              src={profimeImage}
              onError={() => setProfimeImage("/avatar.jpg")}
              onChange={(imgSource) => setProfimeImage(imgSource)}
              accept=".jpg, .png, .gif, .bmp, .webp"
              alt="Avatar"
            />
          </div>
          <div className="inputs">
            <form onSubmit={handleSubmit(onSubmit)}>
              <div className="field-list">
                <div className="field">
                  <label>{t("fullName")}:</label>
                  <input
                    type="text"
                    disabled={!isEditing}
                    {...register("fullName", {
                      required: t("firstNameRequired"),
                    })}
                    className={errors.fullName ? "error" : ""}
                  />
                  {errors.fullName && <span>{errors.fullName.message}</span>}
                </div>
                <div className="field">
                  <label>{t("phone")}:</label>
                  <input
                    type="text"
                    disabled={!isEditing}
                    {...register(
                      "phone",
                      phoneValidationRule(
                        t("phoneNumberRequired"),
                        t("invalidUzbekistanPhoneNumber"),
                      ),
                    )}
                    className={errors.phone ? "error" : ""}
                  />
                  {errors.phone && <span>{errors.phone.message}</span>}
                </div>
                <div className="field">
                  <label>{t("email")}:</label>
                  <input
                    type="email"
                    disabled={!isEditing}
                    {...register("email", { required: t("emailRequired") })}
                    className={errors.email ? "error" : ""}
                  />
                  {errors.email && <span>{errors.email.message}</span>}
                </div>

                <div className="field" style={{ position: "relative" }}>
                  <label>{t("password")}:</label>
                  <input
                    type={showPassword ? "text" : "password"}
                    disabled={!isEditing}
                    {...register("password", {
                      required: isEditing ? t("passwordRequired") : false,
                      minLength: {
                        value: 6,
                        message: t("passwordMinLength"),
                      },
                    })}
                    className={errors.password ? "error" : ""}
                  />
                  {errors.password && <span>{errors.password.message}</span>}

                  <span
                    onClick={togglePasswordVisibility}
                    style={{
                      position: "absolute",
                      right: "10px",
                      top: "18px",
                      transform: "translateY(-50%)",
                      cursor: "pointer",
                    }}
                  >
                    {showPassword ? "👁️" : "🙈"}
                  </span>
                </div>
              </div>

              <div className="profile-btns">
                {isEditing ? (
                  <div className="buttons">
                    <button
                      className="cancel-btn"
                      type="button"
                      onClick={handleCancel}
                    >
                      {t("cancel")}
                    </button>
                    <button type="submit">{t("save")}</button>
                  </div>
                ) : (
                  <button type="button" onClick={handleEdit}>
                    {t("update")}
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
        {currentUser?.role == "agent" && (
          <div className="right">
            <FormGroup>
              <FormControlLabel
                control={
                  <IOSSwitch checked={!!currentUser?.igAccounts?.length} />
                }
                label={t("createInstagramPost")}
              />
              {currentUser?.igAccounts?.map((e, index) => (
                <div
                  key={e.igUserId ?? index}
                  style={{ display: "flex", alignItems: "center", gap: 8 }}
                >
                  <IgProfileCard data={e} />
                  <Button
                    color="error"
                    size="small"
                    onClick={() => handleIgDisconnect(e.igUserId)}
                  >
                    {t("disconnect", { defaultValue: "Disconnect" })}
                  </Button>
                </div>
              ))}
              <Button onClick={handleIgConnect} variant="text">
                {t("connectInstagram", { defaultValue: "Connect Instagram" })}
              </Button>

              <FormControlLabel
                control={<IOSSwitch checked={!!currentUser?.tgChatIds} />}
                label={t("createTelegramPost")}
              />
              {!!currentUser?.tgChatIds &&
                !!currentUser?.tgAccounts &&
                currentUser?.tgAccounts.map((e, index) => (
                  <TgProfileCard key={index} data={e} />
                ))}
              <FormControlLabel
                control={<IOSSwitch />}
                label={t("createYoutubePost")}
              />
              <YtProfileCard />
              <Button onClick={initializeYouTube} variant="text">
                Add account
              </Button>
              <Button onClick={signOut} variant="text">
                sign out
              </Button>
            </FormGroup>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProfileSetting;
