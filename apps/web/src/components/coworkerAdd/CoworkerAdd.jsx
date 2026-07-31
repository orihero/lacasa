import { Avatar } from "@files-ui/react";
import { phoneValidationRule } from "@lacasa/domain";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { useTranslation } from "react-i18next";
import { Triangle } from "react-loader-spinner";
import { useNavigate } from "react-router-dom";
import { toast } from "react-toastify";
import { assetUpload } from "../../lib/assetUpload";
import { api } from "../../lib/api";
import { useUserStore } from "../../lib/userStore";
import "./coworkerAdd.scss";
const CoworkerAdd = () => {
  const { t } = useTranslation();
  const [profimeImage, setProfimeImage] = useState("/avatar.jpg");
  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm();
  const { currentUser } = useUserStore();
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const onSubmit = async (data) => {
    setLoading(true);
    const { phone, email, password, fullName } = data;

    try {
      const updater = async () => {
        let avatar;
        if (!!profimeImage && profimeImage !== "/avatar.jpg") {
          avatar = await assetUpload(profimeImage, "avatars");
        }

        // Privileged, server-side coworker creation — replaces the old
        // client-side second-Firebase-app workaround.
        await api.post("/coworkers", {
          fullName,
          email,
          password,
          phoneNumber: phone,
          avatar,
        });

        toast.success("Coworker successfully created!");
        navigate("/profile/" + currentUser.id + "/coworkers");
        reset(); // Reset to initial values
      };

      toast.promise(updater, {
        error: "Something went wrong!",
        pending: "Uploading",
        success: "Coworker successfully created",
      });
      setLoading(false);
    } catch (error) {
      console.error(error);
      toast.error("Error creating coworker: " + error.message);
    }
  };

  const handleCancel = () => {
    reset(); // Reset to initial values
    navigate("/profile/" + currentUser.id + "/coworkers");
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
        <h1>Create coworker</h1>
      </div>
      <div className="profile-content">
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
                  {...register("fullName", {
                    required: "Full Name is required",
                  })}
                  className={errors.fullName ? "error" : ""}
                />
                {errors.fullName && <span>{errors.fullName.message}</span>}
              </div>
              <div className="field">
                <label>{t("phone")}:</label>
                <input
                  type="text"
                  {...register(
                    "phone",
                    phoneValidationRule(
                      "Phone number is required",
                      "Invalid Uzbekistan phone number",
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
                  {...register("email", { required: "Email is required" })}
                  className={errors.email ? "error" : ""}
                />
                {errors.email && <span>{errors.email.message}</span>}
              </div>

              <div className="field">
                <label>{t("password")}:</label>
                <input
                  type="password"
                  {...register("password", {
                    required: "Password is required",
                    minLength: {
                      value: 6,
                      message: "Password must be at least 6 characters",
                    },
                  })}
                  className={errors.password ? "error" : ""}
                />
                {errors.password && <span>{errors.password.message}</span>}
              </div>
            </div>

            <div className="profile-btns">
              <div className="buttons">
                <button
                  className="cancel-btn"
                  type="button"
                  onClick={handleCancel}
                >
                  Cancel
                </button>
                <button type="submit">Save</button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default CoworkerAdd;
